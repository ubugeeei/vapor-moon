///|
fn find_template_block_close(
  chars : Array[Char],
  start : Int,
  filename : String,
) -> Int? raise CompilerError {
  let mut cursor = start
  let mut nested_template_depth = 0
  while cursor < chars.length() {
    if starts_with_chars(chars, cursor, "<!--") {
      cursor = skip_html_comment(chars, cursor, filename)
      continue
    }
    if chars[cursor] != '<' {
      cursor += 1
      continue
    }
    match read_nested_tag(chars, cursor) {
      Some((name, next, closing, self_closing)) => {
        if name == "template" {
          if closing {
            if nested_template_depth == 0 {
              return Some(cursor)
            }
            nested_template_depth -= 1
          } else if not(self_closing) {
            nested_template_depth += 1
          }
        }
        cursor = next
      }
      None => cursor += 1
    }
  }
  None
}

///|
fn find_raw_block_close(
  source : String,
  chars : Array[Char],
  tag : String,
  start : Int,
  line_comments : Bool,
) -> Int? {
  let close_tag = "</" + tag + ">"
  let mut cursor = start
  let mut quote : Char? = None
  while cursor < chars.length() {
    match quote {
      Some(marker) =>
        if chars[cursor] == '\\' {
          cursor += 2
        } else if chars[cursor] == marker {
          quote = None
          cursor += 1
        } else {
          cursor += 1
        }
      None =>
        if line_comments && starts_raw_multiline_string_line(chars, cursor) {
          cursor = skip_raw_multiline_string_line(chars, cursor)
        } else if starts_with_chars(chars, cursor, "/*") {
          cursor = skip_block_comment(chars, cursor)
        } else if line_comments && starts_with_chars(chars, cursor, "//") {
          cursor = skip_line_comment(chars, cursor)
        } else if chars[cursor] == '"' ||
          chars[cursor] == '\'' ||
          chars[cursor] == '`' {
          quote = Some(chars[cursor])
          cursor += 1
        } else if starts_with_source(source, cursor, close_tag) {
          return Some(cursor)
        } else {
          cursor += 1
        }
    }
  }
  None
}

///|
fn starts_raw_multiline_string_line(chars : Array[Char], start : Int) -> Bool {
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
fn skip_raw_multiline_string_line(chars : Array[Char], start : Int) -> Int {
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
fn skip_html_comment(
  chars : Array[Char],
  start : Int,
  filename : String,
) -> Int raise CompilerError {
  let mut cursor = start + 4
  while cursor + 2 < chars.length() {
    if chars[cursor] == '-' &&
      chars[cursor + 1] == '-' &&
      chars[cursor + 2] == '>' {
      return cursor + 3
    }
    cursor += 1
  }
  raise CompilerError::InvalidSfc("unterminated HTML comment in \{filename}")
}

///|
fn read_nested_tag(
  chars : Array[Char],
  start : Int,
) -> (String, Int, Bool, Bool)? {
  if chars[start] != '<' {
    return None
  }
  let mut cursor = start + 1
  let closing = if cursor < chars.length() && chars[cursor] == '/' {
    cursor += 1
    true
  } else {
    false
  }
  while cursor < chars.length() && is_block_space(chars[cursor]) {
    cursor += 1
  }
  let name_start = cursor
  while cursor < chars.length() && is_tag_name_char(chars[cursor]) {
    cursor += 1
  }
  if cursor == name_start {
    return None
  }
  let name = chars_to_lower_string(chars, name_start, cursor)
  let mut quote : Char? = None
  let mut self_closing = false
  while cursor < chars.length() {
    match quote {
      Some(marker) =>
        if chars[cursor] == '\\' {
          cursor += 2
        } else if chars[cursor] == marker {
          quote = None
          cursor += 1
        } else {
          cursor += 1
        }
      None =>
        if chars[cursor] == '"' || chars[cursor] == '\'' {
          quote = Some(chars[cursor])
          cursor += 1
        } else if chars[cursor] == '>' {
          return Some((name, cursor + 1, closing, self_closing))
        } else if chars[cursor] == '/' &&
          is_nested_self_closing_marker(chars, cursor) {
          self_closing = true
          cursor += 1
        } else {
          cursor += 1
        }
    }
  }
  None
}

///|
fn is_nested_self_closing_marker(chars : Array[Char], start : Int) -> Bool {
  let mut cursor = start + 1
  while cursor < chars.length() && is_block_space(chars[cursor]) {
    cursor += 1
  }
  cursor < chars.length() && chars[cursor] == '>'
}

///|
fn chars_to_lower_string(
  chars : Array[Char],
  start : Int,
  end_ : Int,
) -> String {
  let sb = StringBuilder::new()
  let mut cursor = start
  while cursor < end_ {
    sb.write_char(to_lower_char(chars[cursor]))
    cursor += 1
  }
  sb.to_string()
}

///|
fn starts_with_source(source : String, start : Int, expected : String) -> Bool {
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
fn starts_with_chars(
  chars : Array[Char],
  start : Int,
  expected : String,
) -> Bool {
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
