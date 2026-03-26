///|
fn find_interpolation_close(source : String, start : Int) -> Int? {
  let chars = source.to_array()
  let mut cursor = start + 2
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_template_multiline_string_line(chars, cursor) {
      cursor = skip_template_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with(chars, cursor, "//") {
      cursor = skip_template_line_comment(chars, cursor)
      continue
    }
    if starts_with(chars, cursor, "/*") {
      cursor = skip_template_block_comment(chars, cursor)
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_template_quoted(chars, cursor, current)
      continue
    }
    if current == '}' &&
      cursor + 1 < chars.length() &&
      chars[cursor + 1] == '}' &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return Some(cursor)
    }
    let depths = update_interpolation_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    cursor += 1
  }
  None
}

///|
fn starts_template_multiline_string_line(
  chars : Array[Char],
  start : Int,
) -> Bool {
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
fn skip_template_multiline_string_line(chars : Array[Char], start : Int) -> Int {
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
fn skip_template_line_comment(chars : Array[Char], start : Int) -> Int {
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
fn skip_template_block_comment(chars : Array[Char], start : Int) -> Int {
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
fn skip_template_quoted(chars : Array[Char], start : Int, marker : Char) -> Int {
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
fn update_interpolation_depths(
  current : Char,
  paren_depth : Int,
  bracket_depth : Int,
  brace_depth : Int,
) -> (Int, Int, Int) {
  match current {
    '(' => (paren_depth + 1, bracket_depth, brace_depth)
    ')' =>
      (
        if paren_depth > 0 {
          paren_depth - 1
        } else {
          0
        },
        bracket_depth,
        brace_depth,
      )
    '[' => (paren_depth, bracket_depth + 1, brace_depth)
    ']' =>
      (
        paren_depth,
        if bracket_depth > 0 {
          bracket_depth - 1
        } else {
          0
        },
        brace_depth,
      )
    '{' => (paren_depth, bracket_depth, brace_depth + 1)
    '}' =>
      (
        paren_depth,
        bracket_depth,
        if brace_depth > 0 {
          brace_depth - 1
        } else {
          0
        },
      )
    _ => (paren_depth, bracket_depth, brace_depth)
  }
}

///|
fn starts_with(chars : Array[Char], start : Int, expected : String) -> Bool {
  if start + expected.length() > chars.length() {
    return false
  }
  for index in 0..<expected.length() {
    if chars[start + index].to_int() != expected[index].to_int() {
      return false
    }
  }
  true
}

///|
fn decode_html_entities(source : String) -> String {
  let chars = source.to_array()
  let sb = StringBuilder::new(size_hint=source.length())
  let mut cursor = 0
  let mut changed = false
  while cursor < chars.length() {
    if chars[cursor] == '&' {
      match try_decode_html_entity(source, chars, cursor) {
        Some((decoded, next)) => {
          sb.write_char(decoded)
          cursor = next
          changed = true
          continue
        }
        None => ()
      }
    }
    sb.write_char(chars[cursor])
    cursor += 1
  }
  if changed {
    sb.to_string()
  } else {
    source
  }
}

///|
fn try_decode_html_entity(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (Char, Int)? {
  if start + 2 >= chars.length() || chars[start] != '&' {
    return None
  }
  let mut cursor = start + 1
  if chars[cursor] == '#' {
    cursor += 1
    if cursor >= chars.length() {
      return None
    }
    let is_hex = chars[cursor] == 'x' || chars[cursor] == 'X'
    if is_hex {
      cursor += 1
      if cursor >= chars.length() {
        return None
      }
    }
    let digits_start = cursor
    while cursor < chars.length() && is_html_entity_digit(chars[cursor], is_hex) {
      cursor += 1
    }
    if cursor == digits_start ||
      cursor >= chars.length() ||
      chars[cursor] != ';' {
      return None
    }
    match parse_html_entity_codepoint(chars, digits_start, cursor, is_hex) {
      Some(codepoint) => Some((Int::unsafe_to_char(codepoint), cursor + 1))
      None => None
    }
  } else {
    let name_start = cursor
    while cursor < chars.length() && is_html_entity_name_char(chars[cursor]) {
      cursor += 1
    }
    if cursor == name_start || cursor >= chars.length() || chars[cursor] != ';' {
      return None
    }
    let name = String::unsafe_substring(source, start=name_start, end=cursor)
    match named_html_entity(name) {
      Some(decoded) => Some((decoded, cursor + 1))
      None => None
    }
  }
}

///|
fn is_html_entity_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
}

///|
fn is_html_entity_digit(c : Char, is_hex : Bool) -> Bool {
  if is_hex {
    (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
  } else {
    c >= '0' && c <= '9'
  }
}

///|
fn parse_html_entity_codepoint(
  chars : Array[Char],
  start : Int,
  end_ : Int,
  is_hex : Bool,
) -> Int? {
  let base = if is_hex { 16 } else { 10 }
  let mut value = 0
  for index in start..<end_ {
    let digit = match html_entity_digit_value(chars[index], is_hex) {
      Some(digit) => digit
      None => return None
    }
    if value > (0x10FFFF - digit) / base {
      return None
    }
    value = value * base + digit
  }
  if is_valid_html_entity_codepoint(value) {
    Some(value)
  } else {
    None
  }
}

///|
fn html_entity_digit_value(c : Char, is_hex : Bool) -> Int? {
  if c >= '0' && c <= '9' {
    return Some(c.to_int() - '0'.to_int())
  }
  if not(is_hex) {
    return None
  }
  if c >= 'a' && c <= 'f' {
    return Some(c.to_int() - 'a'.to_int() + 10)
  }
  if c >= 'A' && c <= 'F' {
    return Some(c.to_int() - 'A'.to_int() + 10)
  }
  None
}

///|
fn is_valid_html_entity_codepoint(value : Int) -> Bool {
  value > 0 && value <= 0x10FFFF && not(value >= 0xD800 && value <= 0xDFFF)
}

///|
fn named_html_entity(name : String) -> Char? {
  match name {
    "amp" => Some(Int::unsafe_to_char(38))
    "lt" => Some(Int::unsafe_to_char(60))
    "gt" => Some(Int::unsafe_to_char(62))
    "quot" => Some(Int::unsafe_to_char(34))
    "apos" => Some(Int::unsafe_to_char(39))
    "nbsp" => Some(Int::unsafe_to_char(160))
    "copy" => Some(Int::unsafe_to_char(169))
    "reg" => Some(Int::unsafe_to_char(174))
    "trade" => Some(Int::unsafe_to_char(8482))
    "ndash" => Some(Int::unsafe_to_char(8211))
    "mdash" => Some(Int::unsafe_to_char(8212))
    "hellip" => Some(Int::unsafe_to_char(8230))
    "middot" => Some(Int::unsafe_to_char(183))
    "bull" => Some(Int::unsafe_to_char(8226))
    "laquo" => Some(Int::unsafe_to_char(171))
    "raquo" => Some(Int::unsafe_to_char(187))
    "lsquo" => Some(Int::unsafe_to_char(8216))
    "rsquo" => Some(Int::unsafe_to_char(8217))
    "ldquo" => Some(Int::unsafe_to_char(8220))
    "rdquo" => Some(Int::unsafe_to_char(8221))
    _ => None
  }
}

///|
fn skip_html_comment(chars : Array[Char], start : Int) -> Int? {
  let mut cursor = start + 4
  while cursor + 2 < chars.length() {
    if chars[cursor] == '-' &&
      chars[cursor + 1] == '-' &&
      chars[cursor + 2] == '>' {
      return Some(cursor + 3)
    }
    cursor += 1
  }
  None
}
