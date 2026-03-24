///|
fn read_template_tag(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (String, Array[ParsedTemplateAttr], Int, Bool) raise CompilerError {
  let mut cursor = start + 1
  let name_start = cursor
  while cursor < chars.length() && is_template_name_char(chars[cursor]) {
    cursor += 1
  }
  let tag = String::unsafe_substring(source, start=name_start, end=cursor)
  if tag.length() == 0 {
    raise CompilerError::InvalidTemplate(
      "expected tag name near offset \{start}",
    )
  }
  let attrs : Array[ParsedTemplateAttr] = []
  while cursor < chars.length() {
    cursor = skip_ws(chars, cursor)
    if cursor >= chars.length() {
      break
    }
    if chars[cursor] == '/' {
      let slash = cursor
      cursor += 1
      cursor = skip_ws(chars, cursor)
      if cursor < chars.length() && chars[cursor] == '>' {
        return (tag, attrs, cursor + 1, true)
      }
      raise CompilerError::InvalidTemplate(
        "unexpected `/` in start tag <\{tag}> near offset \{slash}",
      )
    }
    if chars[cursor] == '>' {
      return (tag, attrs, cursor + 1, false)
    }
    let (attr, next) = parse_template_attr(source, chars, cursor, tag)
    attrs.push(attr)
    cursor = next
  }
  raise CompilerError::InvalidTemplate("unterminated start tag <\{tag}>")
}

///|
fn parse_template_attr(
  source : String,
  chars : Array[Char],
  start : Int,
  tag : String,
) -> (ParsedTemplateAttr, Int) raise CompilerError {
  let mut cursor = start
  let name_start = cursor
  while cursor < chars.length() &&
        not(is_space(chars[cursor])) &&
        chars[cursor] != '=' &&
        chars[cursor] != '>' &&
        chars[cursor] != '/' {
    cursor += 1
  }
  if cursor == name_start {
    raise CompilerError::InvalidTemplate(
      "expected attribute name in start tag <\{tag}>",
    )
  }
  let name = String::unsafe_substring(source, start=name_start, end=cursor)
  cursor = skip_ws(chars, cursor)
  if cursor < chars.length() && chars[cursor] == '=' {
    cursor += 1
    cursor = skip_ws(chars, cursor)
    let (value, next) = read_template_attr_value(source, chars, cursor)
    ({ name, value, has_value: true }, next)
  } else {
    ({ name, value: "true", has_value: false }, cursor)
  }
}

///|
fn read_template_attr_value(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (String, Int) raise CompilerError {
  if start >= chars.length() {
    raise CompilerError::InvalidTemplate("expected attribute value")
  }
  if chars[start] == '"' || chars[start] == '\'' {
    let marker = chars[start]
    let mut cursor = start + 1
    while cursor < chars.length() {
      if chars[cursor] == '\\' {
        cursor += 2
        continue
      }
      if chars[cursor] == marker {
        return (
          String::unsafe_substring(source, start=start + 1, end=cursor),
          cursor + 1,
        )
      }
      cursor += 1
    }
    raise CompilerError::InvalidTemplate("unterminated attribute value")
  }
  let mut cursor = start
  while cursor < chars.length() &&
        not(is_space(chars[cursor])) &&
        chars[cursor] != '>' &&
        not(is_self_closing_value_boundary(chars, cursor)) {
    cursor += 1
  }
  if cursor == start {
    raise CompilerError::InvalidTemplate("expected attribute value")
  }
  (String::unsafe_substring(source, start~, end=cursor), cursor)
}

///|
fn is_self_closing_value_boundary(chars : Array[Char], start : Int) -> Bool {
  chars[start] == '/' && start + 1 < chars.length() && chars[start + 1] == '>'
}

///|
fn skip_ws(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start
  while cursor < chars.length() && is_space(chars[cursor]) {
    cursor += 1
  }
  cursor
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\t' || c == '\r'
}

///|
fn is_template_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '-' ||
  c == '_' ||
  c == ':' ||
  c == '.' ||
  c == '[' ||
  c == ']' ||
  c == ','
}

///|
fn is_component_name(tag : String) -> Bool {
  if tag.length() == 0 {
    return false
  }
  let first = tag.to_array()[0]
  first >= 'A' && first <= 'Z'
}
