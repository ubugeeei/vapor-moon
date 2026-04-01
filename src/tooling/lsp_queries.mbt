///|
/// Editor-facing hover/definition/completion queries built on top of `ToolingIndex`.

///|
/// Shared query context for hover, definition, and completion requests.
priv struct ToolingQuery {
  index : ToolingIndex
}

///|
priv enum ToolingReferenceTarget {
  Binding(String, String, @compiler.SourceSpan)
  Member(String, String, String, @compiler.SourceSpan)
}

///|
/// Compute diagnostics for a document without spinning up the JSON-RPC server.
pub fn diagnostics(
  source : String,
  filename? : String = "Component.mbtv",
) -> Array[ToolingDiagnostic] {
  build_tooling_index(source, filename).diagnostics
}

///|
/// Resolve hover contents at a UTF-16 line/character position.
pub fn hover_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> ToolingHover? {
  ToolingQuery::new(source, filename).hover(line, character)
}

///|
/// Resolve the definition target for the token at the given UTF-16 position.
pub fn definition_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> ToolingDefinition? {
  ToolingQuery::new(source, filename).definition(line, character)
}

///|
/// Compute completion items using template-ref, member, and general directive contexts.
pub fn complete_at(
  source : String,
  line : Int,
  character : Int,
  filename? : String = "Component.mbtv",
) -> Array[ToolingCompletionItem] {
  ToolingQuery::new(source, filename).complete(line, character)
}

///|
/// Resolve all references for the token at the given UTF-16 position.
pub fn references_at(
  source : String,
  line : Int,
  character : Int,
  include_declaration? : Bool = true,
  filename? : String = "Component.mbtv",
) -> Array[ToolingLocation] {
  ToolingQuery::new(source, filename).references(
    line, character, include_declaration,
  )
}

///|
/// Build a reusable query context for one source document.
fn ToolingQuery::new(source : String, filename : String) -> ToolingQuery {
  { index: build_tooling_index(source, filename) }
}

///|
/// Resolve hover contents at a UTF-16 line/character position.
fn ToolingQuery::hover(
  self : ToolingQuery,
  line : Int,
  character : Int,
) -> ToolingHover? {
  let document = self.index.document
  let offset = document.position_to_offset(line, character)
  match self.find_hover_target(offset) {
    Some((contents, span)) =>
      Some({ contents, location: document.location_from_span(span) })
    None => None
  }
}

///|
/// Resolve the definition target for the token at the given UTF-16 position.
fn ToolingQuery::definition(
  self : ToolingQuery,
  line : Int,
  character : Int,
) -> ToolingDefinition? {
  let document = self.index.document
  let offset = document.position_to_offset(line, character)
  match self.find_definition_target(offset) {
    Some((name, span)) =>
      Some({ name, location: document.location_from_span(span) })
    None => None
  }
}

///|
/// Compute completion items using template-ref, member, and general directive contexts.
fn ToolingQuery::complete(
  self : ToolingQuery,
  line : Int,
  character : Int,
) -> Array[ToolingCompletionItem] {
  let offset = self.index.document.position_to_offset(line, character)
  match self.resolved_template_ref_completion_items(offset) {
    Some(items) => items
    None =>
      match self.member_completion_items(offset) {
        Some(items) => items
        None => self.general_completion_items(offset)
      }
  }
}

///|
/// Resolve all references for the token at the given UTF-16 position.
fn ToolingQuery::references(
  self : ToolingQuery,
  line : Int,
  character : Int,
  include_declaration : Bool,
) -> Array[ToolingLocation] {
  let offset = self.index.document.position_to_offset(line, character)
  match self.find_reference_target(offset) {
    Some(target) => self.reference_locations(target, include_declaration)
    None => []
  }
}

///|
/// Complete members on `resolve_template_ref(ref).member` expressions.
fn ToolingQuery::resolved_template_ref_completion_items(
  self : ToolingQuery,
  offset : Int,
) -> Array[ToolingCompletionItem]? {
  let context = self.resolved_template_ref_completion_context(offset)
  match context {
    Some((binding_name, prefix)) => {
      let items : Array[ToolingCompletionItem] = []
      for binding in self.index.bindings {
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
/// Detect the completion context for `resolve_template_ref(binding).prefix`.
fn ToolingQuery::resolved_template_ref_completion_context(
  self : ToolingQuery,
  offset : Int,
) -> (String, String)? {
  let document = self.index.document
  let chars = document.chars
  let limit = if offset < chars.length() { offset } else { chars.length() }
  let mut start = limit
  while start > 0 && is_identifier_char(chars[start - 1]) {
    start -= 1
  }
  let prefix = String::unsafe_substring(document.source, start~, end=limit)
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
  let open_paren = match document.matching_open_paren_backward(close_paren) {
    Some(index) => index
    None => return None
  }
  let arg_span = match
    document.trim_span_whitespace(open_paren + 1, close_paren) {
    Some(span) => span
    None => return None
  }
  let binding_name = document.span_text(arg_span)
  if not(ToolingDocument::identifier_literal(binding_name)) {
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
  let callee = String::unsafe_substring(
    document.source,
    start=name_start,
    end=name_end,
  )
  if not(callee.has_suffix("resolve_template_ref")) {
    return None
  }
  Some((binding_name, prefix))
}

///|
/// Find the best hover payload for a source offset.
fn ToolingQuery::find_hover_target(
  self : ToolingQuery,
  offset : Int,
) -> (String, @compiler.SourceSpan)? {
  for entry in self.index.members {
    if contains_offset(entry.span, offset) {
      return Some((member_hover_text(entry), entry.span))
    }
  }
  for binding in self.index.bindings {
    if contains_offset(binding.span, offset) {
      return Some((binding_hover_text(binding), binding.span))
    }
  }
  for ref_ in self.index.refs {
    if contains_offset(ref_.member_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          match
            find_member(
              self.index.members,
              binding.binding_name,
              ref_.member_name,
            ) {
            Some(entry) =>
              return Some((member_hover_text(entry), ref_.member_span))
            None => ()
          }
        None => ()
      }
    }
    if contains_offset(ref_.binding_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          return Some((binding_hover_text(binding), ref_.binding_span))
        None => ()
      }
    }
  }
  None
}

///|
/// Resolve the declaration span referenced by a source offset.
fn ToolingQuery::find_definition_target(
  self : ToolingQuery,
  offset : Int,
) -> (String, @compiler.SourceSpan)? {
  for entry in self.index.members {
    if contains_offset(entry.span, offset) {
      return Some((entry.name, entry.span))
    }
  }
  for binding in self.index.bindings {
    if contains_offset(binding.span, offset) {
      return Some((binding.binding_name, binding.span))
    }
  }
  for ref_ in self.index.refs {
    if contains_offset(ref_.member_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          match
            find_member(
              self.index.members,
              binding.binding_name,
              ref_.member_name,
            ) {
            Some(entry) => return Some((entry.name, entry.span))
            None => ()
          }
        None => ()
      }
    }
    if contains_offset(ref_.binding_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) => return Some((binding.binding_name, binding.span))
        None => ()
      }
    }
  }
  None
}

///|
/// Complete members on direct contract bindings such as `props.foo`.
fn ToolingQuery::member_completion_items(
  self : ToolingQuery,
  offset : Int,
) -> Array[ToolingCompletionItem]? {
  let context = self.member_completion_context(offset)
  match context {
    Some((binding_name, prefix)) => {
      let items : Array[ToolingCompletionItem] = []
      for binding in self.index.bindings {
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
/// Fallback completion path for directives, events, bindings, and macros.
fn ToolingQuery::general_completion_items(
  self : ToolingQuery,
  offset : Int,
) -> Array[ToolingCompletionItem] {
  let prefix = self.index.document.current_token_prefix(offset)
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
  if prefix.has_prefix("v-slot") || prefix.has_prefix("#") {
    return slot_completion_items(prefix)
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
/// Detect `binding.member` completion contexts at the given offset.
fn ToolingQuery::member_completion_context(
  self : ToolingQuery,
  offset : Int,
) -> (String, String)? {
  let document = self.index.document
  let chars = document.chars
  let limit = if offset < chars.length() { offset } else { chars.length() }
  let mut start = limit
  while start > 0 && is_identifier_char(chars[start - 1]) {
    start -= 1
  }
  let prefix = String::unsafe_substring(document.source, start~, end=limit)
  if start == 0 || chars[start - 1] != '.' {
    return None
  }
  let binding_end = start - 1
  let mut binding_start = binding_end
  while binding_start > 0 && is_identifier_char(chars[binding_start - 1]) {
    binding_start -= 1
  }
  let binding_name = String::unsafe_substring(
    document.source,
    start=binding_start,
    end=binding_end,
  )
  Some((binding_name, prefix))
}

///|
/// Resolve the binding/member target used by go-to-references.
fn ToolingQuery::find_reference_target(
  self : ToolingQuery,
  offset : Int,
) -> ToolingReferenceTarget? {
  for entry in self.index.members {
    if contains_offset(entry.span, offset) {
      return Some(
        Member(entry.contract_kind, entry.binding_name, entry.name, entry.span),
      )
    }
  }
  for binding in self.index.bindings {
    if contains_offset(binding.span, offset) {
      return Some(
        Binding(binding.contract_kind, binding.binding_name, binding.span),
      )
    }
  }
  for ref_ in self.index.refs {
    if contains_offset(ref_.member_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          match
            find_member(
              self.index.members,
              binding.binding_name,
              ref_.member_name,
            ) {
            Some(entry) =>
              return Some(
                Member(
                  binding.contract_kind,
                  binding.binding_name,
                  entry.name,
                  entry.span,
                ),
              )
            None => ()
          }
        None => ()
      }
    }
    if contains_offset(ref_.binding_span, offset) {
      match
        find_binding(self.index.bindings, ref_.contract_kind, ref_.binding_name) {
        Some(binding) =>
          return Some(
            Binding(binding.contract_kind, binding.binding_name, binding.span),
          )
        None => ()
      }
    }
  }
  None
}

///|
/// Collect reference locations for one resolved binding or member target.
fn ToolingQuery::reference_locations(
  self : ToolingQuery,
  target : ToolingReferenceTarget,
  include_declaration : Bool,
) -> Array[ToolingLocation] {
  let locations : Array[ToolingLocation] = []
  match target {
    Binding(contract_kind, binding_name, span) => {
      if include_declaration {
        push_unique_location(
          locations,
          self.index.document.location_from_span(span),
        )
      }
      for ref_ in self.index.refs {
        if ref_.contract_kind != contract_kind {
          continue
        }
        match
          find_binding(
            self.index.bindings,
            ref_.contract_kind,
            ref_.binding_name,
          ) {
          Some(binding) if binding.binding_name == binding_name =>
            push_unique_location(
              locations,
              self.index.document.location_from_span(ref_.binding_span),
            )
          _ => ()
        }
      }
    }
    Member(contract_kind, binding_name, member_name, span) => {
      if include_declaration {
        push_unique_location(
          locations,
          self.index.document.location_from_span(span),
        )
      }
      for ref_ in self.index.refs {
        if ref_.contract_kind != contract_kind ||
          ref_.member_name != member_name {
          continue
        }
        match
          find_binding(
            self.index.bindings,
            ref_.contract_kind,
            ref_.binding_name,
          ) {
          Some(binding) if binding.binding_name == binding_name =>
            push_unique_location(
              locations,
              self.index.document.location_from_span(ref_.member_span),
            )
          _ => ()
        }
      }
    }
  }
  locations
}

///|
/// Deduplicate reference locations by filename and source span.
fn push_unique_location(
  locations : Array[ToolingLocation],
  next_ : ToolingLocation,
) -> Unit {
  for location in locations {
    if location.filename == next_.filename && location.span == next_.span {
      return
    }
  }
  locations.push(next_)
}

///|
/// Render hover text for one contract field entry.
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
/// Render hover text for an entire binding, including template-ref metadata.
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
/// Convert a macro field into the user-facing detail string shown in LSP results.
fn render_field_detail(
  contract_kind : String,
  field : @compiler.MacroField,
) -> String {
  contract_kind + " " + field.name + " : " + field.signature.unwrap_or("String")
}
