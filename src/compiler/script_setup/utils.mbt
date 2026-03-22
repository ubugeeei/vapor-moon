///|
fn skip_inline_gap(
  source : String,
  chars : Array[Char],
  start : Int,
) -> Int {
  let mut cursor = start
  while cursor < chars.length() {
    let current = chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    if starts_with_local(source, cursor, "//") {
      cursor = skip_line_comment(chars, cursor)
      continue
    }
    if starts_with_local(source, cursor, "/*") {
      cursor = skip_block_comment(chars, cursor)
      continue
    }
    return cursor
  }
  cursor
}

///|
fn starts_with_local(source : String, start : Int, expected : String) -> Bool {
  let expected_chars = expected.to_array()
  if start + expected_chars.length() > source.length() {
    return false
  }
  let chars = source.to_array()
  for index in 0..<expected_chars.length() {
    if chars[start + index] != expected_chars[index] {
      return false
    }
  }
  true
}

///|
fn skip_line_comment(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start + 2
  while cursor < chars.length() {
    if chars[cursor] == '\n' {
      return cursor + 1
    }
    cursor += 1
  }
  chars.length()
}

///|
fn skip_block_comment(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start + 2
  while cursor + 1 < chars.length() {
    if chars[cursor] == '*' && chars[cursor + 1] == '/' {
      return cursor + 2
    }
    cursor += 1
  }
  chars.length()
}

///|
fn skip_quoted(chars : Array[Char], start : Int, marker : Char) -> Int {
  let mut cursor = start + 1
  while cursor < chars.length() {
    if chars[cursor] == '\\' {
      cursor += 2
      continue
    }
    if chars[cursor] == marker {
      return cursor + 1
    }
    cursor += 1
  }
  chars.length()
}

///|
fn starts_multiline_string_line(chars : Array[Char], start : Int) -> Bool {
  start + 1 < chars.length() && chars[start] == '#' && chars[start + 1] == '|'
}

///|
fn skip_multiline_string_line(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start + 2
  while cursor < chars.length() {
    if chars[cursor] == '\n' {
      return cursor + 1
    }
    cursor += 1
  }
  chars.length()
}

///|
fn is_identifier_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let chars = source.to_array()
  let first = chars[0]
  if not(
      (first >= 'a' && first <= 'z') ||
      (first >= 'A' && first <= 'Z') ||
      first == '_' ||
      first == '$',
    ) {
    return false
  }
  let mut cursor = 1
  while cursor < chars.length() {
    if not(is_identifier_char(chars[cursor])) {
      return false
    }
    cursor += 1
  }
  true
}

///|
fn is_identifier_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '$'
}
