///|
fn append_text_like_nodes(
  segment : String,
  roots : Array[TemplateNode],
  stack : Array[TemplateFrame],
) -> Unit raise CompilerError {
  let mut cursor = 0
  while cursor < segment.length() {
    match find_substring_local(segment, "{{", cursor) {
      Some(open) => {
        let before = String::unsafe_substring(segment, start=cursor, end=open)
        if before.trim().length() > 0 {
          append_node(Text(before), roots, stack)
        }
        match find_interpolation_close(segment, open) {
          Some(close) => {
            let expr = String::unsafe_substring(
                segment,
                start=open + 2,
                end=close,
              )
              .trim()
              .to_string()
            if expr.length() == 0 {
              raise CompilerError::InvalidTemplate("empty interpolation")
            }
            append_node(Interpolation(expr), roots, stack)
            cursor = close + 2
          }
          None =>
            raise CompilerError::InvalidTemplate(
              "unterminated interpolation in template text",
            )
        }
      }
      None => {
        let rest = String::unsafe_substring(
          segment,
          start=cursor,
          end=segment.length(),
        )
        if rest.trim().length() > 0 {
          append_node(Text(rest), roots, stack)
        }
        cursor = segment.length()
      }
    }
  }
}

///|
fn find_interpolation_close(source : String, start : Int) -> Int? {
  let chars = source.to_array()
  let mut cursor = start + 2
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
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
      current,
      paren_depth,
      bracket_depth,
      brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    cursor += 1
  }
  None
}

///|
fn find_substring_local(source : String, needle : String, start : Int) -> Int? {
  let chars = source.to_array()
  let needle_chars = needle.to_array()
  if needle_chars.length() == 0 {
    return Some(start)
  }
  let last = chars.length() - needle_chars.length()
  let mut cursor = start
  while cursor <= last {
    let mut matched = true
    for offset in 0..<needle_chars.length() {
      if chars[cursor + offset] != needle_chars[offset] {
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
  let expected_chars = expected.to_array()
  if start + expected_chars.length() > chars.length() {
    return false
  }
  for index in 0..<expected_chars.length() {
    if chars[start + index] != expected_chars[index] {
      return false
    }
  }
  true
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
