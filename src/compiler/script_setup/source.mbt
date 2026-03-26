///|
priv struct ScriptSetupSource {
  source : String
  filename : String
  chars : Array[Char]
}

///|
fn ScriptSetupSource::new(
  source : String,
  filename : String,
) -> ScriptSetupSource {
  { source, filename, chars: source.to_array() }
}

///|
fn ScriptSetupSource::split_top_level_statements(
  self : ScriptSetupSource,
) -> Array[String] {
  let parts : Array[String] = []
  let mut cursor = 0
  let mut start = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < self.chars.length() {
    if self.starts_multiline_string_line(cursor) {
      cursor = self.skip_multiline_string_line(cursor)
      continue
    }
    if self.starts_with(cursor, "//") {
      let next = self.skip_line_comment(cursor)
      if self.range_has_only_statement_trivia(start, cursor) {
        start = next
      }
      cursor = next
      continue
    }
    if self.starts_with(cursor, "/*") {
      let next = self.skip_block_comment(cursor)
      if self.range_has_only_statement_trivia(start, cursor) {
        start = next
      }
      cursor = next
      continue
    }
    let current = self.chars[cursor]
    if current == '"' || current == '\'' {
      cursor = self.skip_quoted(cursor, current)
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
        self.continues_top_level_statement(start, cursor, cursor + 1, current),
      ) &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      parts.push(String::unsafe_substring(self.source, start~, end=cursor))
      start = cursor + 1
    }
    cursor += 1
  }
  parts.push(
    String::unsafe_substring(self.source, start~, end=self.source.length()),
  )
  parts
}

///|
fn ScriptSetupSource::range_has_only_statement_trivia(
  self : ScriptSetupSource,
  start : Int,
  end_ : Int,
) -> Bool {
  let mut cursor = start
  while cursor < end_ {
    let current = self.chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    return false
  }
  true
}

///|
fn ScriptSetupSource::continues_top_level_statement(
  self : ScriptSetupSource,
  start : Int,
  end_ : Int,
  next_start : Int,
  separator : Char,
) -> Bool {
  if separator == ';' {
    return false
  }
  let prefix = String::unsafe_substring(self.source, start~, end=end_)
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
  self.next_significant_token_continues_statement(next_start)
}

///|
fn ScriptSetupSource::next_significant_token_continues_statement(
  self : ScriptSetupSource,
  start : Int,
) -> Bool {
  let cursor = self.skip_to_next_significant_token(start)
  if cursor >= self.chars.length() {
    return false
  }
  self.starts_with(cursor, "|>") ||
  self.starts_with(cursor, "..") ||
  self.chars[cursor] == '.' ||
  self.starts_with_continuation_word(cursor, "else") ||
  self.starts_with_continuation_word(cursor, "catch")
}

///|
fn ScriptSetupSource::skip_to_next_significant_token(
  self : ScriptSetupSource,
  start : Int,
) -> Int {
  let mut cursor = start
  while cursor < self.chars.length() {
    if self.starts_multiline_string_line(cursor) {
      return cursor
    }
    if self.starts_with(cursor, "//") {
      cursor = self.skip_line_comment(cursor)
      continue
    }
    if self.starts_with(cursor, "/*") {
      cursor = self.skip_block_comment(cursor)
      continue
    }
    let current = self.chars[cursor]
    if current == ' ' || current == '\n' || current == '\t' || current == '\r' {
      cursor += 1
      continue
    }
    return cursor
  }
  cursor
}

///|
fn ScriptSetupSource::starts_with_continuation_word(
  self : ScriptSetupSource,
  start : Int,
  expected : String,
) -> Bool {
  if not(self.starts_with(start, expected)) {
    return false
  }
  let end_ = start + expected.length()
  if end_ >= self.chars.length() {
    return true
  }
  let current = self.chars[end_]
  current == ' ' ||
  current == '\n' ||
  current == '\t' ||
  current == '\r' ||
  current == '{'
}

///|
fn ScriptSetupSource::find_top_level_char(
  self : ScriptSetupSource,
  target : Char,
) -> Int? {
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < self.chars.length() {
    if self.starts_multiline_string_line(cursor) {
      cursor = self.skip_multiline_string_line(cursor)
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
    let current = self.chars[cursor]
    if current == '"' || current == '\'' {
      cursor = self.skip_quoted(cursor, current)
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
fn ScriptSetupSource::find_matching_delimiter(
  self : ScriptSetupSource,
  open_index : Int,
  open_char : Char,
  close_char : Char,
  label : String,
) -> Int raise CompilerError {
  let mut cursor = open_index + 1
  let mut depth = 1
  while cursor < self.chars.length() {
    if self.starts_multiline_string_line(cursor) {
      cursor = self.skip_multiline_string_line(cursor)
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
    let current = self.chars[cursor]
    if current == '"' || current == '\'' {
      cursor = self.skip_quoted(cursor, current)
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
    "unterminated \{label} in \{self.filename}",
  )
}

///|
fn ScriptSetupSource::split_top_level(
  self : ScriptSetupSource,
  separator : Char,
) -> Array[String] {
  let parts : Array[String] = []
  let current_parts : Array[String] = []
  let mut cursor = 0
  let mut start = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < self.chars.length() {
    if self.starts_multiline_string_line(cursor) {
      cursor = self.skip_multiline_string_line(cursor)
      continue
    }
    if self.starts_with(cursor, "//") {
      current_parts.push(
        String::unsafe_substring(self.source, start~, end=cursor),
      )
      cursor = self.skip_line_comment(cursor)
      start = cursor
      continue
    }
    if self.starts_with(cursor, "/*") {
      current_parts.push(
        String::unsafe_substring(self.source, start~, end=cursor),
      )
      cursor = self.skip_block_comment(cursor)
      start = cursor
      continue
    }
    let current = self.chars[cursor]
    if current == '"' || current == '\'' {
      cursor = self.skip_quoted(cursor, current)
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
      current_parts.push(
        String::unsafe_substring(self.source, start~, end=cursor),
      )
      parts.push(current_parts.join(""))
      current_parts.clear()
      start = cursor + 1
    }
    cursor += 1
  }
  current_parts.push(
    String::unsafe_substring(self.source, start~, end=self.source.length()),
  )
  parts.push(current_parts.join(""))
  parts
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
