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
  match resolved_template_ref_completion_items(index, offset) {
    Some(items) => items
    None =>
      match member_completion_items(index, offset) {
        Some(items) => items
        None => general_completion_items(index, offset)
      }
  }
}

///|
fn resolved_template_ref_completion_items(
  index : ToolingIndex,
  offset : Int,
) -> Array[ToolingCompletionItem]? {
  let context = resolved_template_ref_completion_context(index.source, offset)
  match context {
    Some((binding_name, prefix)) => {
      let items : Array[ToolingCompletionItem] = []
      for binding in index.bindings {
        if binding.access_mode != ResolveTemplateRef ||
          binding.binding_name != binding_name {
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
        return Some(items)
      }
      Some([])
    }
    None => None
  }
}

///|
fn resolved_template_ref_completion_context(
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
  let mut cursor = start - 1
  while cursor > 0 && (chars[cursor - 1] == ' ' || chars[cursor - 1] == '\t') {
    cursor -= 1
  }
  if cursor == 0 || chars[cursor - 1] != ')' {
    return None
  }
  let close_paren = cursor - 1
  let open_paren = match matching_open_paren_backward(chars, close_paren) {
    Some(index) => index
    None => return None
  }
  let arg_span = match
    trim_whitespace_span(chars, open_paren + 1, close_paren) {
    Some(span) => span
    None => return None
  }
  let binding_name = String::unsafe_substring(
    source,
    start=arg_span.0,
    end=arg_span.1,
  )
  if not(is_identifier_literal(binding_name)) {
    return None
  }
  cursor = open_paren
  while cursor > 0 && (chars[cursor - 1] == ' ' || chars[cursor - 1] == '\t') {
    cursor -= 1
  }
  let name_end = cursor
  let mut name_start = name_end
  while name_start > 0 {
    let ch = chars[name_start - 1]
    if is_identifier_char(ch) || ch == '.' || ch == '@' {
      name_start -= 1
    } else {
      break
    }
  }
  let callee = String::unsafe_substring(source, start=name_start, end=name_end)
  if not(callee.has_suffix("resolve_template_ref")) {
    return None
  }
  Some((binding_name, prefix))
}

///|
fn matching_open_paren_backward(chars : Array[Char], close_paren : Int) -> Int? {
  let mut depth = 0
  let mut cursor = close_paren + 1
  while cursor > 0 {
    cursor -= 1
    match chars[cursor] {
      ')' => depth += 1
      '(' => {
        depth -= 1
        if depth == 0 {
          return Some(cursor)
        }
      }
      _ => ()
    }
  }
  None
}

///|
fn trim_whitespace_span(
  chars : Array[Char],
  start : Int,
  end_ : Int,
) -> (Int, Int)? {
  let mut trimmed_start = start
  while trimmed_start < end_ &&
        (chars[trimmed_start] == ' ' || chars[trimmed_start] == '\t') {
    trimmed_start += 1
  }
  let mut trimmed_end = end_
  while trimmed_end > trimmed_start &&
        (chars[trimmed_end - 1] == ' ' || chars[trimmed_end - 1] == '\t') {
    trimmed_end -= 1
  }
  if trimmed_start >= trimmed_end {
    None
  } else {
    Some((trimmed_start, trimmed_end))
  }
}

///|
fn is_identifier_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  for ch in source {
    if not(is_identifier_char(ch)) {
      return false
    }
  }
  true
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
        if binding.access_mode != Direct || binding.binding_name != binding_name {
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
  if prefix.has_prefix("@") {
    return event_completion_items(prefix)
  }
  if prefix.has_prefix("v-on:") {
    return long_event_completion_items(prefix)
  }
  if prefix.has_prefix(":") {
    return binding_completion_items(prefix)
  }
  if prefix.has_prefix("v-bind:") {
    return long_binding_completion_items(prefix)
  }
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
    type_identifiers: [],
    type_shape: @compiler_common.SingleValue,
    is_optional: false,
  })
}

///|
fn binding_hover_text(binding : ToolingBindingDef) -> String {
  if binding.access_mode == ResolveTemplateRef {
    let type_name = binding.type_name.unwrap_or("@js_dom.Element")
    let fields : Array[String] = []
    for field in binding.fields {
      fields.push(render_field_detail(binding.contract_kind, field))
    }
    if fields.is_empty() {
      return "template ref `" + binding.binding_name + "` : " + type_name
    }
    return "template ref `" +
      binding.binding_name +
      "` : " +
      type_name +
      "\n" +
      fields.join("\n")
  }
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
