///|
/// Parse the `<template>` body into a lightweight HTML-like AST.

///|
pub fn parse_template(
  source : String,
) -> Array[TemplateNode] raise CompilerError {
  let visitor = new_template_token_visitor()
  visit_template_tokens(source, visitor)
  finish_template_token_visitor(visitor)
}

///|
fn parse_for_binding(source : String) -> ForBinding raise CompilerError {
  match find_top_level_for_separator(source) {
    Some((left_end, right_start)) => {
      let left = strip_for_comments(
          String::unsafe_substring(source, start=0, end=left_end),
        )
        .trim()
        .to_string()
      let right = String::unsafe_substring(
          source,
          start=right_start,
          end=source.length(),
        )
        .trim()
        .to_string()
      if right.length() == 0 {
        raise CompilerError::InvalidDirective("invalid v-for source: \{source}")
      }
      if left.has_prefix("(") && left.has_suffix(")") {
        let body = String::unsafe_substring(
          left,
          start=1,
          end=left.length() - 1,
        )
        let items = split_top_level_for_binding_items(body)
        if items.length() > 2 {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        if items.length() == 0 || items[0].length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        if items.length() == 2 && items[1].length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        ensure_valid_for_binding_name(items[0], source)
        if items.length() == 2 {
          ensure_valid_for_binding_name(items[1], source)
        }
        {
          value: items[0],
          index: if items.length() > 1 && items[1].length() > 0 {
            Some(items[1])
          } else {
            None
          },
          source: right,
        }
      } else {
        if left.length() == 0 || has_top_level_for_binding_separator(left, ',') {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        ensure_valid_for_binding_name(left, source)
        { value: left, index: None, source: right }
      }
    }
    None =>
      raise CompilerError::InvalidDirective(
        "expected `item in items`, got: \{source}",
      )
  }
}

///|
fn strip_for_comments(source : String) -> String {
  let parts : Array[String] = []
  let chars = source.to_array()
  let mut cursor = 0
  let mut start = 0
  while cursor < chars.length() {
    if starts_for_multiline_string_line(chars, cursor) {
      cursor = skip_for_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "//") {
      parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_for_line_comment(chars, cursor)
      start = cursor
      continue
    }
    if starts_with_for_local(source, cursor, "/*") {
      parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_for_block_comment(chars, cursor)
      start = cursor
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_for_quoted(chars, cursor, current)
      continue
    }
    cursor += 1
  }
  parts.push(String::unsafe_substring(source, start~, end=source.length()))
  parts.join("")
}

///|
fn find_top_level_for_separator(source : String) -> (Int, Int)? {
  let chars = source.to_array()
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0 {
      match try_parse_for_separator(source, chars, cursor) {
        Some(right_start) => return Some((cursor, right_start))
        None => ()
      }
    }
    if starts_for_multiline_string_line(chars, cursor) {
      cursor = skip_for_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "//") {
      cursor = skip_for_line_comment(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "/*") {
      cursor = skip_for_block_comment(chars, cursor)
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_for_quoted(chars, cursor, current)
      continue
    }
    let depths = update_for_binding_depths(
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
fn try_parse_for_separator(
  source : String,
  chars : Array[Char],
  start : Int,
) -> Int? {
  let keyword_start = skip_for_separator_gap(source, chars, start)
  if keyword_start == start ||
    not(starts_with_for_local(source, keyword_start, "in")) {
    return None
  }
  let right_start = skip_for_separator_gap(source, chars, keyword_start + 2)
  if right_start == keyword_start + 2 {
    return None
  }
  Some(right_start)
}

///|
fn skip_for_separator_gap(
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
    if starts_with_for_local(source, cursor, "//") {
      cursor = skip_for_line_comment(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "/*") {
      cursor = skip_for_block_comment(chars, cursor)
      continue
    }
    return cursor
  }
  cursor
}

///|
fn split_top_level_for_binding_items(source : String) -> Array[String] {
  let parts : Array[String] = []
  let current_parts : Array[String] = []
  let chars = source.to_array()
  let mut cursor = 0
  let mut start = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_for_multiline_string_line(chars, cursor) {
      cursor = skip_for_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "//") {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_for_line_comment(chars, cursor)
      start = cursor
      continue
    }
    if starts_with_for_local(source, cursor, "/*") {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      cursor = skip_for_block_comment(chars, cursor)
      start = cursor
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_for_quoted(chars, cursor, current)
      continue
    }
    let depths = update_for_binding_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    if current == ',' &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      current_parts.push(String::unsafe_substring(source, start~, end=cursor))
      parts.push(current_parts.join("").trim().to_string())
      current_parts.clear()
      start = cursor + 1
    }
    cursor += 1
  }
  current_parts.push(
    String::unsafe_substring(source, start~, end=source.length()),
  )
  parts.push(current_parts.join("").trim().to_string())
  parts
}

///|
fn has_top_level_for_binding_separator(
  source : String,
  separator : Char,
) -> Bool {
  let chars = source.to_array()
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    if starts_for_multiline_string_line(chars, cursor) {
      cursor = skip_for_multiline_string_line(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "//") {
      cursor = skip_for_line_comment(chars, cursor)
      continue
    }
    if starts_with_for_local(source, cursor, "/*") {
      cursor = skip_for_block_comment(chars, cursor)
      continue
    }
    let current = chars[cursor]
    if current == '"' || current == '\'' {
      cursor = skip_for_quoted(chars, cursor, current)
      continue
    }
    if current == separator &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return true
    }
    let depths = update_for_binding_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    cursor += 1
  }
  false
}

///|
fn starts_with_for_local(
  source : String,
  start : Int,
  expected : String,
) -> Bool {
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
fn skip_for_line_comment(chars : Array[Char], start : Int) -> Int {
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
fn skip_for_block_comment(chars : Array[Char], start : Int) -> Int {
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
fn skip_for_quoted(chars : Array[Char], start : Int, marker : Char) -> Int {
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
fn starts_for_multiline_string_line(chars : Array[Char], start : Int) -> Bool {
  start + 1 < chars.length() && chars[start] == '#' && chars[start + 1] == '|'
}

///|
fn skip_for_multiline_string_line(chars : Array[Char], start : Int) -> Int {
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
fn update_for_binding_depths(
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
fn ensure_valid_for_binding_name(
  name : String,
  source : String,
) -> Unit raise CompilerError {
  if not(is_identifier_literal(name)) {
    raise CompilerError::InvalidDirective("invalid v-for binding: \{source}")
  }
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

///|
priv struct TemplateTokenVisitor {
  roots : Array[TemplateNode]
  stack : Array[TemplateFrame]
}

///|
fn new_template_token_visitor() -> TemplateTokenVisitor {
  { roots: [], stack: [] }
}

///|
fn finish_template_token_visitor(
  visitor : TemplateTokenVisitor,
) -> Array[TemplateNode] raise CompilerError {
  if visitor.stack.length() > 0 {
    let frame = visitor.stack[visitor.stack.length() - 1]
    raise CompilerError::InvalidTemplate(
      "missing closing tag </\{frame.element.tag}>",
    )
  }
  visitor.roots
}

///|
struct ParsedTemplateTag {
  name : String
  attrs : Array[ParsedTemplateAttr]
  self_closing : Bool
} derive(Eq, Show)

///|
priv struct TemplateFrame {
  element : TemplateElement
  children : Array[TemplateNode]
}

///|
pub struct ParsedTemplateAttr {
  name : String
  value : String
  has_value : Bool
} derive(Eq, Show)
