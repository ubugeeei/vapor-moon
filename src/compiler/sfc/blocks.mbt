///|
fn parse_blocks(source : String) -> Array[SfcBlock] raise CompilerError {
  let blocks : Array[SfcBlock] = []
  let chars = source.to_array()
  let mut cursor = 0
  while cursor < chars.length() {
    if chars[cursor] != '<' {
      cursor += 1
      continue
    }
    if cursor + 1 < chars.length() && chars[cursor + 1] == '!' {
      cursor = skip_comment(chars, cursor)
      continue
    }
    if cursor + 1 < chars.length() && chars[cursor + 1] == '/' {
      cursor += 1
      continue
    }
    match read_start_tag(source, chars, cursor) {
      Some((tag, attrs, tag_end)) => {
        if not(is_top_level_tag(tag)) {
          cursor += 1
          continue
        }
        let close_tag = "</" + tag + ">"
        match find_substring_from(source, close_tag, tag_end) {
          Some(close_start) => {
            let content = String::unsafe_substring(
              source,
              start=tag_end,
              end=close_start,
            )
            let kind = classify_block(tag, attrs)
            let end = close_start + close_tag.length()
            blocks.push({
              kind,
              attrs,
              content: content.trim().to_string(),
              span: { start: cursor, end },
            })
            cursor = end
          }
          None =>
            raise CompilerError::InvalidSfc(
              "unclosed <\{tag}> block at offset \{cursor}",
            )
        }
      }
      None => cursor += 1
    }
  }
  blocks
}

///|
fn is_top_level_tag(tag : String) -> Bool {
  tag == "template" || tag == "script" || tag == "style"
}

///|
fn classify_block(tag : String, attrs : Array[BlockAttr]) -> BlockKind {
  if tag == "template" {
    Template
  } else if tag == "style" {
    Style
  } else if has_attr(attrs, "setup") {
    ScriptSetup
  } else {
    Script
  }
}

///|
fn skip_comment(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start + 1
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

///|
fn find_substring_from(source : String, needle : String, start : Int) -> Int? {
  if needle.length() == 0 {
    return Some(start)
  }
  if start >= source.length() {
    return None
  }
  let source_chars = source.to_array()
  let needle_chars = needle.to_array()
  let last = source_chars.length() - needle_chars.length()
  let mut cursor = start
  while cursor <= last {
    let mut matched = true
    for offset in 0..<needle_chars.length() {
      if source_chars[cursor + offset] != needle_chars[offset] {
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
