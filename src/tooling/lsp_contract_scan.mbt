///|
fn find_contract_field_definition_span(
  source : String,
  search_span : @compiler.SourceSpan,
  binding : String,
  field_name : String,
) -> @compiler.SourceSpan? {
  match find_contract_type_body_span(source, search_span, binding) {
    Some(body_span) =>
      find_token_in_span(source, field_name, body_span, body_span.start)
    None => find_field_definition_span(source, search_span, field_name)
  }
}

///|
fn find_contract_type_body_span(
  source : String,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> @compiler.SourceSpan? {
  match find_contract_type_name(source, search_span, binding) {
    Some(type_name) =>
      match find_substring_in_span(source, "struct " + type_name, search_span) {
        Some(start) => find_record_body_span(source, search_span, start)
        None => None
      }
    None => None
  }
}

///|
fn find_contract_type_name(
  source : String,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> String? {
  match find_binding_definition_span(source, search_span, binding) {
    Some(binding_span) => {
      let chars = source.to_array()
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
        Some(String::unsafe_substring(source, start~, end=cursor))
      }
    }
    None => None
  }
}

///|
fn find_record_body_span(
  source : String,
  search_span : @compiler.SourceSpan,
  start_offset : Int,
) -> @compiler.SourceSpan? {
  let chars = source.to_array()
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
