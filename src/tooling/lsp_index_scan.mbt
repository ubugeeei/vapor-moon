///|
fn find_block_span(
  blocks : Array[@compiler.SfcBlock],
  kind : @compiler.BlockKind,
) -> @compiler.SourceSpan {
  for block in blocks {
    if block.kind == kind {
      return block.span
    }
  }
  { start: 0, end: 0 }
}

///|
fn find_block_content_span(
  source : String,
  blocks : Array[@compiler.SfcBlock],
  kind : @compiler.BlockKind,
) -> @compiler.SourceSpan? {
  for block in blocks {
    if block.kind != kind {
      continue
    }
    if block.content.length() == 0 {
      return Some(block.span)
    }
    return find_substring_in_span(source, block.content, block.span).map(fn(
      start,
    ) {
      { start, end: start + block.content.length() }
    })
  }
  None
}

///|
fn find_binding_definition_span(
  source : String,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> @compiler.SourceSpan? {
  match find_substring_in_span(source, "let " + binding, search_span) {
    Some(start) => Some({ start: start + 4, end: start + 4 + binding.length() })
    None => find_token_in_span(source, binding, search_span, search_span.start)
  }
}

///|
fn find_field_definition_span(
  source : String,
  search_span : @compiler.SourceSpan,
  name : String,
) -> @compiler.SourceSpan? {
  match find_substring_in_span(source, "\"" + name + "\"", search_span) {
    Some(start) => Some({ start: start + 1, end: start + 1 + name.length() })
    None =>
      match find_substring_in_span(source, "'" + name + "'", search_span) {
        Some(start) =>
          Some({ start: start + 1, end: start + 1 + name.length() })
        None => find_token_in_span(source, name, search_span, search_span.start)
      }
  }
}

///|
fn find_member_refs(
  source : String,
  search_span : @compiler.SourceSpan,
  contract_kind : String,
  binding_name : String,
) -> Array[ToolingMemberRef] {
  let refs : Array[ToolingMemberRef] = []
  let mut cursor = search_span.start
  while true {
    match find_token_in_span(source, binding_name, search_span, cursor) {
      Some(binding_span) => {
        let member_span = member_span_after_binding(source, binding_span)
        cursor = binding_span.end
        match member_span {
          Some(member_span) =>
            refs.push({
              contract_kind,
              binding_name,
              member_name: span_text(source, member_span),
              binding_span,
              member_span,
            })
          None => ()
        }
      }
      None => break
    }
  }
  refs
}

///|
fn member_span_after_binding(
  source : String,
  binding_span : @compiler.SourceSpan,
) -> @compiler.SourceSpan? {
  let chars = source.to_array()
  let mut cursor = binding_span.end
  while cursor < chars.length() &&
        (chars[cursor] == ' ' || chars[cursor] == '\t') {
    cursor += 1
  }
  if cursor >= chars.length() || chars[cursor] != '.' {
    return None
  }
  cursor += 1
  while cursor < chars.length() &&
        (chars[cursor] == ' ' || chars[cursor] == '\t') {
    cursor += 1
  }
  if cursor >= chars.length() || not(is_identifier_char(chars[cursor])) {
    return None
  }
  let start = cursor
  while cursor < chars.length() && is_identifier_char(chars[cursor]) {
    cursor += 1
  }
  Some({ start, end: cursor })
}

///|
fn overlaps_definition(
  ref_ : ToolingMemberRef,
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
) -> Bool {
  for binding in bindings {
    if spans_overlap(ref_.binding_span, binding.span) {
      return true
    }
  }
  for entry in members {
    if spans_overlap(ref_.member_span, entry.span) {
      return true
    }
  }
  false
}

///|
fn find_binding(
  bindings : Array[ToolingBindingDef],
  contract_kind : String,
  binding_name : String,
) -> ToolingBindingDef? {
  for binding in bindings {
    if binding.contract_kind == contract_kind &&
      binding.binding_name == binding_name {
      return Some(binding)
    }
  }
  None
}

///|
fn find_binding_by_kind(
  bindings : Array[ToolingBindingDef],
  contract_kind : String,
) -> ToolingBindingDef? {
  for binding in bindings {
    if binding.contract_kind == contract_kind {
      return Some(binding)
    }
  }
  None
}

///|
fn find_member(
  members : Array[ToolingMemberDef],
  binding_name : String,
  name : String,
) -> ToolingMemberDef? {
  for entry in members {
    if entry.binding_name == binding_name && entry.name == name {
      return Some(entry)
    }
  }
  None
}

///|
fn canonical_binding_name(contract_kind : String) -> String {
  contract_kind
}

///|
fn uppercase_first(source : String) -> String {
  if source.length() == 0 {
    return source
  }
  let chars = source.to_array()
  let first = chars[0]
  let upper = if first >= 'a' && first <= 'z' {
    (first.to_int() - 'a'.to_int() + 'A'.to_int()).unsafe_to_char()
  } else {
    first
  }
  let sb = StringBuilder::new()
  sb.write_char(upper)
  sb.write_string(
    String::unsafe_substring(source, start=1, end=source.length()),
  )
  sb.to_string()
}

///|
fn find_substring_in_span(
  source : String,
  needle : String,
  span : @compiler.SourceSpan,
) -> Int? {
  let source_chars = source.to_array()
  let needle_chars = needle.to_array()
  if needle_chars.length() == 0 || span.start >= source_chars.length() {
    return None
  }
  let last = min_int(
    span.end - needle_chars.length(),
    source_chars.length() - needle_chars.length(),
  )
  let mut cursor = span.start
  while cursor <= last {
    let mut matched = true
    for offset in 0..<needle_chars.length() {
      if source_chars[cursor + offset] != needle_chars[offset] {
        matched = false
        break
      }
    }
    if matched {
      return Some(cursor)
    }
    cursor += 1
  }
  None
}

///|
fn find_token_in_span(
  source : String,
  token : String,
  span : @compiler.SourceSpan,
  start_offset : Int,
) -> @compiler.SourceSpan? {
  let chars = source.to_array()
  let token_chars = token.to_array()
  let last = min_int(
    span.end - token_chars.length(),
    chars.length() - token_chars.length(),
  )
  let mut cursor = if start_offset > span.start {
    start_offset
  } else {
    span.start
  }
  while cursor <= last {
    let mut matched = true
    for offset in 0..<token_chars.length() {
      if chars[cursor + offset] != token_chars[offset] {
        matched = false
        break
      }
    }
    let before_ok = cursor == 0 || not(is_identifier_char(chars[cursor - 1]))
    let end_ = cursor + token_chars.length()
    let after_ok = end_ >= chars.length() ||
      not(is_identifier_char(chars[end_]))
    if matched && before_ok && after_ok {
      return Some({ start: cursor, end: end_ })
    }
    cursor += 1
  }
  None
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}
