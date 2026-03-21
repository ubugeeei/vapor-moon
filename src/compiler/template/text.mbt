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
        match find_substring_local(segment, "}}", open + 2) {
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
fn skip_html_comment(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start + 4
  while cursor + 2 < chars.length() {
    if chars[cursor] == '-' &&
      chars[cursor + 1] == '-' &&
      chars[cursor + 2] == '>' {
      return cursor + 3
    }
    cursor += 1
  }
  chars.length()
}
