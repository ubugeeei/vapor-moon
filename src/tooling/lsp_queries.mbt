///|
pub fn diagnostics(
  source : String,
  filename? : String = "Component.mbtv",
) -> Array[ToolingDiagnostic] {
  build_tooling_index(source, filename).diagnostics
}

///|
pub fn hover_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> ToolingHover? {
  let index = build_tooling_index(source, filename)
  let offset = position_to_offset(source, line, character)
  match find_hover_target(index, offset) {
    Some((contents, span)) =>
      Some({ contents, location: location_from_span(source, filename, span) })
    None => None
  }
}

///|
pub fn definition_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> ToolingDefinition? {
  let index = build_tooling_index(source, filename)
  let offset = position_to_offset(source, line, character)
  match find_definition_target(index, offset) {
    Some((name, span)) =>
      Some({ name, location: location_from_span(source, filename, span) })
    None => None
  }
}

///|
pub fn complete_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> Array[ToolingCompletionItem] {
  let index = build_tooling_index(source, filename)
  let offset = position_to_offset(source, line, character)
  match member_completion_items(index, offset) {
    Some(items) => items
    None => general_completion_items(index, offset)
  }
}

///|
fn find_hover_target(
  index : ToolingIndex,
  offset : Int,
) -> (String, @compiler.SourceSpan)? {
  for entry in index.members {
    if contains_offset(entry.span, offset) {
      return Some((member_hover_text(entry), entry.span))
    }
  }
  for binding in index.bindings {
    if contains_offset(binding.span, offset) {
      return Some((binding_hover_text(binding), binding.span))
    }
  }
  for ref_ in index.refs {
    if contains_offset(ref_.member_span, offset) {
      match
        find_binding(index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          match
            find_member(index.members, binding.binding_name, ref_.member_name) {
            Some(entry) =>
              return Some((member_hover_text(entry), ref_.member_span))
            None => ()
          }
        None => ()
      }
    }
    if contains_offset(ref_.binding_span, offset) {
      match
        find_binding(index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          return Some((binding_hover_text(binding), ref_.binding_span))
        None => ()
      }
    }
  }
  None
}

///|
fn find_definition_target(
  index : ToolingIndex,
  offset : Int,
) -> (String, @compiler.SourceSpan)? {
  for entry in index.members {
    if contains_offset(entry.span, offset) {
      return Some((entry.name, entry.span))
    }
  }
  for binding in index.bindings {
    if contains_offset(binding.span, offset) {
      return Some((binding.binding_name, binding.span))
    }
  }
  for ref_ in index.refs {
    if contains_offset(ref_.member_span, offset) {
      match
        find_binding(index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          match
            find_member(index.members, binding.binding_name, ref_.member_name) {
            Some(entry) => return Some((entry.name, entry.span))
            None => ()
          }
        None => ()
      }
    }
    if contains_offset(ref_.binding_span, offset) {
      match
        find_binding(index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) => return Some((binding.binding_name, binding.span))
        None => ()
      }
    }
  }
  None
}

///|
fn member_completion_items(
  index : ToolingIndex,
  offset : Int,
) -> Array[ToolingCompletionItem]? {
  let context = member_completion_context(index.source, offset)
  match context {
    Some((binding_name, prefix)) => {
      let items : Array[ToolingCompletionItem] = []
      for binding in index.bindings {
        if binding.binding_name != binding_name {
          continue
        }
        for field in binding.fields {
          if not(field.name.has_prefix(prefix)) {
            continue
          }
          items.push({
            label: field.name,
            kind: binding.contract_kind,
            detail: render_field_detail(binding.contract_kind, field),
            insert_text: field.name,
          })
        }
      }
      Some(items)
    }
    None => None
  }
}

///|
fn general_completion_items(
  index : ToolingIndex,
  offset : Int,
) -> Array[ToolingCompletionItem] {
  let prefix = current_token_prefix(index.source, offset)
  if prefix.has_prefix("v-") {
    return directive_completion_items(prefix)
  }
  if prefix.has_prefix("client:") {
    return island_completion_items(prefix, "client", [
      "client:load", "client:idle", "client:visible", "client:media", "client:only",
    ])
  }
  if prefix.has_prefix("server:") {
    return island_completion_items(prefix, "server", ["server:defer"])
  }
  macro_completion_items(prefix)
}

///|
fn member_completion_context(
  source : String,
  offset : Int,
) -> (String, String)? {
  let chars = source.to_array()
  let limit = if offset < chars.length() { offset } else { chars.length() }
  let mut start = limit
  while start > 0 && is_identifier_char(chars[start - 1]) {
    start -= 1
  }
  let prefix = String::unsafe_substring(source, start~, end=limit)
  if start == 0 || chars[start - 1] != '.' {
    return None
  }
  let binding_end = start - 1
  let mut binding_start = binding_end
  while binding_start > 0 && is_identifier_char(chars[binding_start - 1]) {
    binding_start -= 1
  }
  let binding_name = String::unsafe_substring(
    source,
    start=binding_start,
    end=binding_end,
  )
  Some((binding_name, prefix))
}

///|
fn member_hover_text(entry : ToolingMemberDef) -> String {
  render_field_detail(entry.contract_kind, {
    name: entry.name,
    signature: entry.signature,
  })
}

///|
fn binding_hover_text(binding : ToolingBindingDef) -> String {
  let fields : Array[String] = []
  for field in binding.fields {
    fields.push(render_field_detail(binding.contract_kind, field))
  }
  "define" +
  uppercase_first(binding.contract_kind) +
  " binding `" +
  binding.binding_name +
  "`\n" +
  fields.join("\n")
}

///|
fn render_field_detail(
  contract_kind : String,
  field : @compiler.MacroField,
) -> String {
  contract_kind + " " + field.name + " : " + field.signature.unwrap_or("String")
}

///|
fn macro_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    ("defineProps", "macro", "declare typed props"),
    ("defineEmits", "macro", "declare typed emits"),
    ("defineSlot", "macro", "declare typed slots"),
    ("useId", "macro", "generate stable ids"),
    ("useTemplateRef", "macro", "create a template ref"),
  ]
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if prefix.length() > 0 && not(entry.0.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry.0,
      kind: entry.1,
      detail: entry.2,
      insert_text: entry.0,
    })
  }
  items
}

///|
fn directive_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = ["v-if", "v-for", "v-show", "v-html", "v-model", "v-once"]
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry,
      kind: "directive",
      detail: "template directive",
      insert_text: entry,
    })
  }
  items
}

///|
fn island_completion_items(
  prefix : String,
  kind : String,
  entries : Array[String],
) -> Array[ToolingCompletionItem] {
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry,
      kind,
      detail: "island directive",
      insert_text: entry,
    })
  }
  items
}
