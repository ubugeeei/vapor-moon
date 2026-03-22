///|
fn parse_blocks(
  source : String,
  filename : String,
) -> Array[SfcBlock] raise CompilerError {
  let blocks : Array[SfcBlock] = []
  let chars = source.to_array()
  let mut cursor = 0
  while cursor < chars.length() {
    if chars[cursor] != '<' {
      if is_block_space(chars[cursor]) {
        cursor += 1
        continue
      }
      raise CompilerError::InvalidSfc(
        "unexpected top-level content at offset \{cursor} in \{filename}",
      )
    }
    if cursor + 1 < chars.length() && chars[cursor + 1] == '!' {
      cursor = skip_html_comment(chars, cursor)
      continue
    }
    if cursor + 1 < chars.length() && chars[cursor + 1] == '/' {
      match read_end_tag_name(chars, cursor) {
        Some((tag, _)) if is_top_level_tag(tag) =>
          raise CompilerError::InvalidSfc(
            "unexpected closing </\{tag}> block at offset \{cursor} in \{filename}",
          )
        Some(_) | None =>
          raise CompilerError::InvalidSfc(
            "unexpected top-level content at offset \{cursor} in \{filename}",
          )
      }
    }
    match read_start_tag(source, chars, cursor) {
      Some((tag, attrs, tag_end, self_closing)) => {
        if not(is_top_level_tag(tag)) {
          raise CompilerError::InvalidSfc(
            "unexpected top-level tag <\{tag}> in \{filename}",
          )
        }
        if self_closing {
          raise CompilerError::InvalidSfc(
            "self-closing <\{tag}> blocks are not supported in \{filename}",
          )
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
      None =>
        raise CompilerError::InvalidSfc(
          "unexpected top-level content at offset \{cursor} in \{filename}",
        )
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
