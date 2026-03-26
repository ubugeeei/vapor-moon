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
fn ToolingDocument::find_block_content_span(
  self : ToolingDocument,
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
    return self.find_substring_in_span(block.content, block.span).map(fn(start) {
      { start, end: start + block.content.length() }
    })
  }
  None
}

///|
fn ToolingDocument::find_binding_definition_span(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  binding : String,
) -> @compiler.SourceSpan? {
  match self.find_substring_in_span("let " + binding, search_span) {
    Some(start) => Some({ start: start + 4, end: start + 4 + binding.length() })
    None => self.find_token_in_span(binding, search_span, search_span.start)
  }
}

///|
fn ToolingDocument::find_field_definition_span(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  name : String,
) -> @compiler.SourceSpan? {
  match self.find_substring_in_span("\"" + name + "\"", search_span) {
    Some(start) => Some({ start: start + 1, end: start + 1 + name.length() })
    None =>
      match self.find_substring_in_span("'" + name + "'", search_span) {
        Some(start) =>
          Some({ start: start + 1, end: start + 1 + name.length() })
        None => self.find_token_in_span(name, search_span, search_span.start)
      }
  }
}

///|
fn ToolingDocument::find_member_refs(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  contract_kind : String,
  binding_name : String,
) -> Array[ToolingMemberRef] {
  let refs : Array[ToolingMemberRef] = []
  let mut cursor = search_span.start
  while true {
    match self.find_token_in_span(binding_name, search_span, cursor) {
      Some(binding_span) => {
        let member_span = self.member_span_after_binding(binding_span)
        cursor = binding_span.end
        match member_span {
          Some(member_span) =>
            refs.push({
              contract_kind,
              binding_name,
              member_name: self.span_text(member_span),
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
fn ToolingDocument::find_resolved_template_ref_member_refs(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  binding_name : String,
) -> Array[ToolingMemberRef] {
  let refs : Array[ToolingMemberRef] = []
  let mut cursor = search_span.start
  while true {
    match
      self.find_substring_in_span_from(
        "resolve_template_ref",
        search_span,
        cursor,
      ) {
      Some(start) => {
        cursor = start + "resolve_template_ref".length()
        match self.parse_resolved_template_ref_member_ref(search_span, start) {
          Some((resolved_binding_name, binding_span, member_span)) =>
            if resolved_binding_name == binding_name {
              refs.push({
                contract_kind: "template ref",
                binding_name,
                member_name: self.span_text(member_span),
                binding_span,
                member_span,
              })
            }
          None => ()
        }
      }
      None => break
    }
  }
  refs
}

///|
fn ToolingDocument::parse_resolved_template_ref_member_ref(
  self : ToolingDocument,
  search_span : @compiler.SourceSpan,
  start : Int,
) -> (String, @compiler.SourceSpan, @compiler.SourceSpan)? {
  let chars = self.chars
  let mut cursor = start + "resolve_template_ref".length()
  while cursor < search_span.end &&
        (chars[cursor] == ' ' || chars[cursor] == '\t') {
    cursor += 1
  }
  if cursor >= search_span.end || chars[cursor] != '(' {
    return None
  }
  let open_paren = cursor
  let close_paren = match
    self.find_matching_paren_forward(open_paren, search_span.end) {
    Some(index) => index
    None => return None
  }
  let binding_span = match self.trim_span_whitespace(open_paren + 1, close_paren) {
    Some(span) => span
    None => return None
  }
  let binding_name = self.span_text(binding_span)
  if not(ToolingDocument::identifier_literal(binding_name)) {
    return None
  }
  cursor = close_paren + 1
  while cursor < search_span.end &&
        (chars[cursor] == ' ' || chars[cursor] == '\t') {
    cursor += 1
  }
  if cursor >= search_span.end || chars[cursor] != '.' {
    return None
  }
  cursor += 1
  while cursor < search_span.end &&
        (chars[cursor] == ' ' || chars[cursor] == '\t') {
    cursor += 1
  }
  if cursor >= search_span.end || not(is_identifier_char(chars[cursor])) {
    return None
  }
  let member_start = cursor
  while cursor < search_span.end && is_identifier_char(chars[cursor]) {
    cursor += 1
  }
  Some((binding_name, binding_span, { start: member_start, end: cursor }))
}

///|
fn ToolingDocument::matching_open_paren_backward(
  self : ToolingDocument,
  close_paren : Int,
) -> Int? {
  let chars = self.chars
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
fn ToolingDocument::find_matching_paren_forward(
  self : ToolingDocument,
  open_paren : Int,
  limit : Int,
) -> Int? {
  let chars = self.chars
  let mut depth = 0
  let mut cursor = open_paren
  while cursor < limit {
    match chars[cursor] {
      '(' => depth += 1
      ')' => {
        depth -= 1
        if depth == 0 {
          return Some(cursor)
        }
      }
      _ => ()
    }
    cursor += 1
  }
  None
}

///|
fn ToolingDocument::trim_span_whitespace(
  self : ToolingDocument,
  start : Int,
  end_ : Int,
) -> @compiler.SourceSpan? {
  let chars = self.chars
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
    Some({ start: trimmed_start, end: trimmed_end })
  }
}

///|
fn ToolingDocument::identifier_literal(
  source : String,
) -> Bool {
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
fn ToolingDocument::member_span_after_binding(
  self : ToolingDocument,
  binding_span : @compiler.SourceSpan,
) -> @compiler.SourceSpan? {
  let chars = self.chars
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
fn ToolingDocument::find_substring_in_span(
  self : ToolingDocument,
  needle : String,
  span : @compiler.SourceSpan,
) -> Int? {
  let source_chars = self.chars
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
fn ToolingDocument::find_substring_in_span_from(
  self : ToolingDocument,
  needle : String,
  span : @compiler.SourceSpan,
  start_offset : Int,
) -> Int? {
  let source_chars = self.chars
  let needle_chars = needle.to_array()
  if needle_chars.length() == 0 || span.start >= source_chars.length() {
    return None
  }
  let last = min_int(
    span.end - needle_chars.length(),
    source_chars.length() - needle_chars.length(),
  )
  let mut cursor = if start_offset > span.start {
    start_offset
  } else {
    span.start
  }
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
fn ToolingDocument::find_token_in_span(
  self : ToolingDocument,
  token : String,
  span : @compiler.SourceSpan,
  start_offset : Int,
) -> @compiler.SourceSpan? {
  let chars = self.chars
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
    let after_ok = end_ >= chars.length() || not(is_identifier_char(chars[end_]))
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
