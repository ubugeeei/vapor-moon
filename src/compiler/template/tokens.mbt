///|
fn read_template_token(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (TemplateToken, Int) raise CompilerError {
  if starts_with(chars, start, "<!--") {
    match skip_html_comment(chars, start) {
      Some(end) => return (Comment, end)
      None =>
        raise CompilerError::InvalidTemplate("unterminated HTML comment")
    }
  }
  if starts_with(chars, start, "{{") {
    return read_interpolation_token(source, start)
  }
  if chars[start] == '<' {
    if start + 1 < chars.length() && chars[start + 1] == '/' {
      return read_end_tag_token(source, chars, start)
    }
    let (tag, next) = read_start_tag_token(source, chars, start)
    return (StartTagToken(tag), next)
  }
  read_text_token(source, chars, start)
}

///|
fn read_text_token(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (TemplateToken, Int) {
  let mut cursor = start
  while cursor < chars.length() {
    if chars[cursor] == '<' || starts_with(chars, cursor, "{{") {
      break
    }
    cursor += 1
  }
  (TextToken(String::unsafe_substring(source, start~, end=cursor)), cursor)
}

///|
fn read_interpolation_token(
  source : String,
  start : Int,
) -> (TemplateToken, Int) raise CompilerError {
  match find_substring_local(source, "}}", start + 2) {
    Some(close) => {
      let expr = String::unsafe_substring(source, start=start + 2, end=close)
        .trim()
        .to_string()
      if expr.length() == 0 {
        raise CompilerError::InvalidTemplate("empty interpolation")
      }
      (InterpolationToken(expr), close + 2)
    }
    None =>
      raise CompilerError::InvalidTemplate(
        "unterminated interpolation in template text",
      )
  }
}

///|
fn read_start_tag_token(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (ParsedTemplateTag, Int) raise CompilerError {
  let (tag, attrs, end, self_closing) = read_template_tag(source, chars, start)
  ({ name: tag, attrs, self_closing }, end)
}

///|
fn read_end_tag_token(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (TemplateToken, Int) raise CompilerError {
  let mut cursor = start + 2
  cursor = skip_ws(chars, cursor)
  let name_start = cursor
  while cursor < chars.length() && is_template_name_char(chars[cursor]) {
    cursor += 1
  }
  let name = String::unsafe_substring(source, start=name_start, end=cursor)
  if name.length() == 0 {
    raise CompilerError::InvalidTemplate(
      "expected closing tag name near offset \{start}",
    )
  }
  cursor = skip_ws(chars, cursor)
  if cursor >= chars.length() || chars[cursor] != '>' {
    raise CompilerError::InvalidTemplate("unterminated closing tag </\{name}>")
  }
  (EndTagToken(name), cursor + 1)
}
