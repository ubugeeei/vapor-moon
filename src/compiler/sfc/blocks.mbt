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
      cursor = skip_html_comment(chars, cursor)
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
        match find_block_close_start(source, chars, tag, tag_end) {
          Some(close_start) => {
            let content = String::unsafe_substring(
              source,
              start=tag_end,
              end=close_start,
            )
            let kind = classify_block(tag, attrs)
            let close_tag = "</" + tag + ">"
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
fn find_block_close_start(
  source : String,
  chars : Array[Char],
  tag : String,
  start : Int,
) -> Int? {
  if tag == "template" {
    find_template_block_close(chars, start)
  } else {
    find_raw_block_close(source, chars, tag, start, tag == "script")
  }
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
