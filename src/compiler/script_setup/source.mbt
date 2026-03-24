///|
fn split_top_level_statements(source : String) -> Array[String] {
  let parts : Array[String] = []
  let chars = source.to_array()
  let mut cursor = 0
  let mut start = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_multiline_string_line(chars, cursor) {
      cursor = skip_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_local(source, cursor, "//") {
      let next = skip_line_comment(chars, cursor)
      if range_has_only_statement_trivia(chars, start, cursor) {
        start = next
      }
      cursor = next
      continue
    }
    if starts_with_local(source, cursor, "/*") {
      let next = skip_block_comment(chars, cursor)
      if range_has_only_statement_trivia(chars, start, cursor) {
        start = next
      }
      cursor = next
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_quoted(chars, cursor, current)
      continue
    }
    let depths = update_scan_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    if (current == '\n' || current == ';') &&
      not(
        continues_top_level_statement(
          source,
          chars,
          start,
          cursor,
          cursor + 1,
          current,
        ),
      ) &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      parts.push(String::unsafe_substring(source, start~, end=cursor))
      start = cursor + 1
    }
    cursor += 1
  }
  parts.push(String::unsafe_substring(source, start~, end=source.length()))
  parts
}

///|
fn range_has_only_statement_trivia(
  chars : Array[Char],
  start : Int,
  end_ : Int,
) -> Bool {
  let mut cursor = start
  while cursor < end_ {
    let current = chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    return false
  }
  true
}

///|
fn continues_top_level_statement(
  source : String,
  chars : Array[Char],
  start : Int,
  end_ : Int,
  next_start : Int,
  separator : Char,
) -> Bool {
  if separator == ';' {
    return false
  }
  let prefix = String::unsafe_substring(source, start~, end=end_)
    .trim_end(chars=" \t\r")
    .to_string()
  if prefix.length() == 0 {
    return false
  }
  prefix.has_suffix("=") ||
  prefix.has_suffix("(") ||
  prefix.has_suffix("[") ||
  prefix.has_suffix("{") ||
  prefix.has_suffix(",") ||
  prefix.has_suffix(":") ||
  prefix.has_suffix("+") ||
  prefix.has_suffix("-") ||
  prefix.has_suffix("*") ||
  prefix.has_suffix("/") ||
  prefix.has_suffix("%") ||
  prefix.has_suffix("|>") ||
  prefix.has_suffix("&&") ||
  prefix.has_suffix("||") ||
  prefix.has_suffix("=>") ||
  prefix.has_suffix("->") ||
  next_significant_token_continues_statement(source, chars, next_start)
}

///|
fn next_significant_token_continues_statement(
  source : String,
  chars : Array[Char],
  start : Int,
) -> Bool {
  let cursor = skip_to_next_significant_token(source, chars, start)
  if cursor >= chars.length() {
    return false
  }
  starts_with_local(source, cursor, "|>") ||
  starts_with_local(source, cursor, "..") ||
  chars[cursor] == '.' ||
  starts_with_continuation_word(source, chars, cursor, "else") ||
  starts_with_continuation_word(source, chars, cursor, "catch")
}

///|
fn skip_to_next_significant_token(
  source : String,
  chars : Array[Char],
  start : Int,
) -> Int {
  let mut cursor = start
  while cursor < chars.length() {
    if starts_multiline_string_line(chars, cursor) {
      return cursor
    }
    if starts_with_local(source, cursor, "//") {
      cursor = skip_line_comment(chars, cursor)
      continue
    }
    if starts_with_local(source, cursor, "/*") {
      cursor = skip_block_comment(chars, cursor)
      continue
    }
    let current = chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    return cursor
  }
  cursor
}

///|
fn starts_with_continuation_word(
  source : String,
  chars : Array[Char],
  start : Int,
  expected : String,
) -> Bool {
  if not(starts_with_local(source, start, expected)) {
    return false
  }
  let end_ = start + expected.length()
  if end_ >= chars.length() {
    return true
  }
  let current = chars[end_]
  current == ' ' ||
  current == '\n' ||
  current == '\t' ||
  current == '\r' ||
  current == '{'
}

///|
fn find_top_level_char(
  source : String,
  chars : Array[Char],
  target : Char,
) -> Int? {
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_multiline_string_line(chars, cursor) {
      cursor = skip_multiline_string_line(chars, cursor)
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
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_quoted(chars, cursor, current)
      continue
    }
    if current == target &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return Some(cursor)
    }
    let depths = update_scan_depths(
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
fn find_matching_delimiter(
  source : String,
  chars : Array[Char],
  open_index : Int,
  open_char : Char,
  close_char : Char,
  filename : String,
  label : String,
) -> Int raise CompilerError {
  let mut cursor = open_index + 1
  let mut depth = 1
  while cursor < chars.length() {
    if starts_multiline_string_line(chars, cursor) {
      cursor = skip_multiline_string_line(chars, cursor)
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
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_quoted(chars, cursor, current)
      continue
    }
    if current == open_char {
      depth += 1
    } else if current == close_char {
      depth -= 1
      if depth == 0 {
        return cursor
      }
    }
    cursor += 1
  }
  raise CompilerError::InvalidScriptSetup(
    "unterminated \{label} in \{filename}",
  )
}

///|
fn update_scan_depths(
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
fn split_top_level(source : String, separator : Char) -> Array[String] {
  let parts : Array[String] = []
  let current_parts : Array[String] = []
  let chars = source.to_array()
  let mut cursor = 0
  let mut start = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_multiline_string_line(chars, cursor) {
      cursor = skip_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_local(source, cursor, "//") {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_line_comment(chars, cursor)
      start = cursor
      continue
    }
    if starts_with_local(source, cursor, "/*") {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_block_comment(chars, cursor)
      start = cursor
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_quoted(chars, cursor, current)
      continue
    }
    let depths = update_scan_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    if current == separator &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      parts.push(current_parts.join(""))
      current_parts.clear()
      start = cursor + 1
    }
    cursor += 1
  }
  current_parts.push(
    String::unsafe_substring(source, start~, end=source.length()),
  )
  parts.push(current_parts.join(""))
  parts
}
