///|
priv enum TemplateTokenizerState {
  Text
  TagOpen
  StartTag
  EndTag
  Interpolation
  Comment
}

///|
fn visit_template_tokens(
  source : String,
  visitor : TemplateTokenVisitor,
) -> Unit raise CompilerError {
  let chars = source.to_array()
  let mut cursor = 0
  let mut text_start = 0
  let mut text_has_content = false
  let mut state = TemplateTokenizerState::Text
  while cursor < chars.length() {
    match state {
      Text =>
        if is_interpolation_open(chars, cursor) {
          visitor_on_text(visitor, source, text_start, cursor, text_has_content)
          text_has_content = false
          state = TemplateTokenizerState::Interpolation
        } else if is_template_markup_open(chars, cursor) {
          visitor_on_text(visitor, source, text_start, cursor, text_has_content)
          text_has_content = false
          state = TemplateTokenizerState::TagOpen
        } else {
          if not(is_space(chars[cursor])) {
            text_has_content = true
          }
          cursor += 1
        }
      TagOpen =>
        if is_comment_open(chars, cursor) {
          state = TemplateTokenizerState::Comment
        } else if is_end_tag_open(chars, cursor) {
          state = TemplateTokenizerState::EndTag
        } else {
          state = TemplateTokenizerState::StartTag
        }
      StartTag => {
        let (tag, attrs, next, self_closing) = read_template_tag(
          source, chars, cursor,
        )
        visitor_on_start_tag(visitor, tag, attrs, self_closing)
        cursor = next
        text_start = cursor
        text_has_content = false
        state = TemplateTokenizerState::Text
      }
      EndTag => {
        let (name, next) = read_template_end_tag(source, chars, cursor)
        visitor_on_end_tag(visitor, name)
        cursor = next
        text_start = cursor
        text_has_content = false
        state = TemplateTokenizerState::Text
      }
      Interpolation => {
        cursor = visit_template_interpolation(source, cursor, visitor)
        text_start = cursor
        text_has_content = false
        state = TemplateTokenizerState::Text
      }
      Comment =>
        match skip_html_comment(chars, cursor) {
          Some(next) => {
            cursor = next
            text_start = cursor
            text_has_content = false
            state = TemplateTokenizerState::Text
          }
          None =>
            raise CompilerError::InvalidTemplate("unterminated HTML comment")
        }
    }
  }
  visitor_on_text(visitor, source, text_start, chars.length(), text_has_content)
}

///|
fn visit_template_interpolation(
  source : String,
  start : Int,
  visitor : TemplateTokenVisitor,
) -> Int raise CompilerError {
  match find_interpolation_close(source, start) {
    Some(close) => {
      let expr = String::unsafe_substring(source, start=start + 2, end=close)
        .trim()
        .to_string()
      if expr.length() == 0 {
        raise CompilerError::InvalidTemplate("empty interpolation")
      }
      visitor_on_interpolation(visitor, expr)
      close + 2
    }
    None =>
      raise CompilerError::InvalidTemplate(
        "unterminated interpolation in template text",
      )
  }
}

///|
fn read_template_end_tag(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (String, Int) raise CompilerError {
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
  (name, cursor + 1)
}

///|
fn is_comment_open(chars : Array[Char], start : Int) -> Bool {
  start + 3 < chars.length() &&
  chars[start] == '<' &&
  chars[start + 1] == '!' &&
  chars[start + 2] == '-' &&
  chars[start + 3] == '-'
}

///|
fn is_end_tag_open(chars : Array[Char], start : Int) -> Bool {
  if not(start + 1 < chars.length() && chars[start] == '<' && chars[start + 1] == '/') {
    return false
  }
  let mut cursor = start + 2
  cursor = skip_ws(chars, cursor)
  cursor < chars.length() && is_template_name_start_char(chars[cursor])
}

///|
fn is_interpolation_open(chars : Array[Char], start : Int) -> Bool {
  start + 1 < chars.length() && chars[start] == '{' && chars[start + 1] == '{'
}

///|
fn is_template_markup_open(chars : Array[Char], start : Int) -> Bool {
  is_comment_open(chars, start) ||
  is_end_tag_open(chars, start) ||
  is_start_tag_open(chars, start)
}

///|
fn is_start_tag_open(chars : Array[Char], start : Int) -> Bool {
  start + 1 < chars.length() &&
  chars[start] == '<' &&
  is_template_name_start_char(chars[start + 1])
}

///|
fn is_template_name_start_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}
