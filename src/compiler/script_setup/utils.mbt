///|
fn skip_inline_gap(source : String, chars : Array[Char], start : Int) -> Int {
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
  if start + expected.length() > source.length() {
    return false
  }
  for index in 0..<expected.length() {
    if source[start + index] != expected[index] {
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
  if not(
      start + 1 < chars.length() &&
      chars[start] == '#' &&
      chars[start + 1] == '|',
    ) {
    return false
  }
  let mut cursor = start
  while cursor > 0 {
    let previous = chars[cursor - 1]
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
  let first = source[0].to_int()
  if not(
      (first >= 0x61 && first <= 0x7A) ||
      (first >= 0x41 && first <= 0x5A) ||
      first == 0x5F ||
      first == 0x24,
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
  (c >= 0x61 && c <= 0x7A) ||
  (c >= 0x41 && c <= 0x5A) ||
  (c >= 0x30 && c <= 0x39) ||
  c == 0x5F ||
  c == 0x24
}
