///|
fn ScriptSetupSource::skip_inline_gap(
  self : ScriptSetupSource,
  start : Int,
) -> Int {
  let mut cursor = start
  while cursor < self.chars.length() {
    let current = self.chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    if self.starts_with(cursor, "//") {
      cursor = self.skip_line_comment(cursor)
      continue
    }
    if self.starts_with(cursor, "/*") {
      cursor = self.skip_block_comment(cursor)
      continue
    }
    return cursor
  }
  cursor
}

///|
fn ScriptSetupSource::starts_with(
  self : ScriptSetupSource,
  start : Int,
  expected : String,
) -> Bool {
  if start + expected.length() > self.source.length() {
    return false
  }
  for index in 0..<expected.length() {
    if self.source[start + index] != expected[index] {
      return false
    }
  }
  true
}

///|
fn ScriptSetupSource::skip_line_comment(
  self : ScriptSetupSource,
  start : Int,
) -> Int {
  let mut cursor = start + 2
  while cursor < self.chars.length() {
    if self.chars[cursor] == '\n' {
      return cursor + 1
    }
    cursor += 1
  }
  self.chars.length()
}

///|
fn ScriptSetupSource::skip_block_comment(
  self : ScriptSetupSource,
  start : Int,
) -> Int {
  let mut cursor = start + 2
  while cursor + 1 < self.chars.length() {
    if self.chars[cursor] == '*' && self.chars[cursor + 1] == '/' {
      return cursor + 2
    }
    cursor += 1
  }
  self.chars.length()
}

///|
fn ScriptSetupSource::skip_quoted(
  self : ScriptSetupSource,
  start : Int,
  marker : Char,
) -> Int {
  let mut cursor = start + 1
  while cursor < self.chars.length() {
    if self.chars[cursor] == '\\' {
      cursor += 2
      continue
    }
    if self.chars[cursor] == marker {
      return cursor + 1
    }
    cursor += 1
  }
  self.chars.length()
}

///|
fn ScriptSetupSource::starts_multiline_string_line(
  self : ScriptSetupSource,
  start : Int,
) -> Bool {
  if not(
      start + 1 < self.chars.length() &&
      self.chars[start] == '#' &&
      self.chars[start + 1] == '|',
    ) {
    return false
  }
  let mut cursor = start
  while cursor > 0 {
    let previous = self.chars[cursor - 1]
    if previous == '\n' || previous == '\r' {
      return true
    }
    if previous == ' ' || previous == '\t' {
      cursor -= 1
      continue
    }
    return false
  }
  true
}

///|
fn ScriptSetupSource::skip_multiline_string_line(
  self : ScriptSetupSource,
  start : Int,
) -> Int {
  let mut cursor = start + 2
  while cursor < self.chars.length() {
    if self.chars[cursor] == '\n' {
      return cursor + 1
    }
    cursor += 1
  }
  self.chars.length()
}

///|
fn is_identifier_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let first = source[0].to_int()
  if not(
      (first >= 'a'.to_int() && first <= 'z'.to_int()) ||
      (first >= 'A'.to_int() && first <= 'Z'.to_int()) ||
      first == '_'.to_int() ||
      first == '$'.to_int(),
    ) {
    return false
  }
  for i in 1..<source.length() {
    if not(is_identifier_charcode(source[i].to_int())) {
      return false
    }
  }
  true
}

///|
fn is_identifier_charcode(c : Int) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= '0'.to_int() && c <= '9'.to_int()) ||
  c == '_'.to_int() ||
  c == '$'.to_int()
}
