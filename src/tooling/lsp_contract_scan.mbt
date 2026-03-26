///|
fn ToolingDocument::find_contract_field_definition_span(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  binding : String,
  field_name : String,
) -> @compiler.SourceSpan? {
  match self.find_contract_type_body_span(search_span, binding) {
    Some(body_span) =>
      self.find_token_in_span(field_name, body_span, body_span.start)
    None => self.find_field_definition_span(search_span, field_name)
  }
}

///|
fn ToolingDocument::find_contract_type_body_span(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> @compiler.SourceSpan? {
  match self.find_contract_type_name(search_span, binding) {
    Some(type_name) =>
      match self.find_substring_in_span("struct " + type_name, search_span) {
        Some(start) => self.find_record_body_span(search_span, start)
        None => None
      }
    None => None
  }
}

///|
fn ToolingDocument::find_contract_type_name(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> String? {
  match self.find_binding_definition_span(search_span, binding) {
    Some(binding_span) => {
      let chars = self.chars
      let mut cursor = binding_span.end
      while cursor < search_span.end &&
            chars[cursor] != ':' &&
            chars[cursor] != '\n' &&
            chars[cursor] != '=' {
        cursor += 1
      }
      if cursor >= search_span.end || chars[cursor] != ':' {
        return None
      }
      cursor += 1
      while cursor < search_span.end &&
            (chars[cursor] == ' ' || chars[cursor] == '\t') {
        cursor += 1
      }
      let start = cursor
      while cursor < search_span.end && is_identifier_char(chars[cursor]) {
        cursor += 1
      }
      if cursor == start {
        None
      } else {
        Some(String::unsafe_substring(self.source, start~, end=cursor))
      }
    }
    None => None
  }
}

///|
fn ToolingDocument::find_record_body_span(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  start_offset : Int,
) -> @compiler.SourceSpan? {
  let chars = self.chars
  let mut cursor = start_offset
  while cursor < search_span.end && chars[cursor] != '{' {
    cursor += 1
  }
  if cursor >= search_span.end {
    return None
  }
  let body_start = cursor + 1
  cursor += 1
  let mut depth = 1
  while cursor < search_span.end {
    if chars[cursor] == '{' {
      depth += 1
    } else if chars[cursor] == '}' {
      depth -= 1
      if depth == 0 {
        return Some({ start: body_start, end: cursor })
      }
    }
    cursor += 1
  }
  None
}
