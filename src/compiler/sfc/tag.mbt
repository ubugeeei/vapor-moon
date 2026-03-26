///|
fn detect_extension(filename : String) -> String {
  match filename.rev_find(".") {
    Some(index) =>
      String::unsafe_substring(filename, start=index, end=filename.length())
    None => ".mbtv"
  }
}

///|
fn has_attr(attrs : Array[BlockAttr], name : String) -> Bool {
  for attr in attrs {
    if attr.name == name {
      return true
    }
  }
  false
}

///|
fn reject_unsupported_attrs(
  block : SfcBlock,
  filename : String,
) -> Unit raise CompilerError {
  validate_block_attrs(block, filename)
  for attr in block.attrs {
    if attr.name == "lang" {
      raise CompilerError::InvalidSfc(
        "`lang` is not supported in \{filename}; Vapor Moon blocks are always MoonBit / plain CSS",
      )
    }
    if attr.name == "src" {
      raise CompilerError::InvalidSfc(
        "`src` is not supported in \{filename}; keep the SFC self-contained",
      )
    }
    if attr.name == "generic" && block.kind != ScriptSetup {
      raise CompilerError::InvalidSfc(
        "`generic` is only supported on <script> in \{filename}",
      )
    }
  }
}

///|
fn validate_block_attrs(
  block : SfcBlock,
  filename : String,
) -> Unit raise CompilerError {
  let seen : Array[String] = []
  for attr in block.attrs {
    if has_seen_block_attr(seen, attr.name) {
      raise CompilerError::InvalidSfc(
        "duplicate `\{attr.name}` attribute on \{block_tag_display(block)} in \{filename}",
      )
    }
    seen.push(attr.name)
    if not(is_supported_block_attr(block.kind, attr.name)) {
      match attr.name {
        "setup" =>
          if block.kind == ScriptExtern {
            raise CompilerError::InvalidSfc(
              "`setup` cannot be combined with `extern` on <script extern> in \{filename}",
            )
          } else {
            raise CompilerError::InvalidSfc(
              "`setup` is only supported on <script> in \{filename}",
            )
          }
        "extern" =>
          raise CompilerError::InvalidSfc(
            "`extern` is only supported on <script> in \{filename}",
          )
        "scoped" =>
          raise CompilerError::InvalidSfc(
            "`scoped` is only supported on <style> in \{filename}",
          )
        _ =>
          raise CompilerError::InvalidSfc(
            "unsupported attribute `\{attr.name}` on \{block_tag_display(block)} in \{filename}",
          )
      }
    }
    match attr.name {
      "generic" =>
        if block.kind == ScriptSetup {
          match attr.value {
            Some(value) if value.trim().length() > 0 => ()
            _ =>
              raise CompilerError::InvalidSfc(
                "`generic` requires a value on \{block_tag_display(block)} in \{filename}",
              )
          }
        }
      "setup" =>
        match attr.value {
          Some(_) =>
            raise CompilerError::InvalidSfc(
              "`setup` does not take a value on \{block_tag_display(block)} in \{filename}",
            )
          None => ()
        }
      "extern" =>
        match attr.value {
          Some(_) =>
            raise CompilerError::InvalidSfc(
              "`extern` does not take a value on <script extern> in \{filename}",
            )
          None => ()
        }
      "scoped" =>
        match attr.value {
          Some(value) if not(is_scoped_style_disabled_value(value)) =>
            raise CompilerError::InvalidSfc(
              "`scoped` only accepts `false` on <style> in \{filename}",
            )
          _ => ()
        }
      _ => ()
    }
  }
}

///|
fn has_seen_block_attr(seen : Array[String], target : String) -> Bool {
  for name in seen {
    if name == target {
      return true
    }
  }
  false
}

///|
fn block_tag_name(kind : BlockKind) -> String {
  match kind {
    Template => "template"
    ScriptSetup | ScriptExtern => "script"
    Style => "style"
  }
}

///|
fn block_tag_suffix(block : SfcBlock) -> String {
  match block.kind {
    ScriptSetup => if has_attr(block.attrs, "setup") { " setup" } else { "" }
    ScriptExtern => " extern"
    _ => ""
  }
}

///|
fn block_tag_display(block : SfcBlock) -> String {
  "<" + block_tag_name(block.kind) + block_tag_suffix(block) + ">"
}

///|
fn is_supported_block_attr(kind : BlockKind, name : String) -> Bool {
  match kind {
    Template => name == "lang" || name == "src" || name == "generic"
    ScriptSetup =>
      name == "setup" || name == "generic" || name == "lang" || name == "src"
    ScriptExtern => name == "extern" || name == "lang" || name == "src"
    Style => name == "scoped" || name == "lang" || name == "src"
  }
}

///|
fn find_attr_value(attrs : Array[BlockAttr], name : String) -> String? {
  for attr in attrs {
    if attr.name == name {
      return attr.value
    }
  }
  None
}

///|
fn style_block_is_scoped(attrs : Array[BlockAttr]) -> Bool {
  match find_attr_value(attrs, "scoped") {
    Some(value) => not(is_scoped_style_disabled_value(value))
    None => true
  }
}

///|
fn is_scoped_style_disabled_value(value : String) -> Bool {
  let normalized = StringBuilder::new()
  for ch in value.trim() {
    normalized.write_char(to_lower_char(ch))
  }
  normalized.to_string() == "false"
}

///|
fn read_start_tag(
  source : String,
  chars : Array[Char],
  start : Int,
  filename : String,
) -> (String, Array[BlockAttr], Int, Bool)? raise CompilerError {
  if chars[start] != '<' {
    return None
  }
  let mut cursor = start + 1
  let tag = StringBuilder::new()
  while cursor < chars.length() && is_tag_name_char(chars[cursor]) {
    tag.write_char(to_lower_char(chars[cursor]))
    cursor += 1
  }
  if tag.to_string().length() == 0 {
    return None
  }
  let header_start = cursor
  let mut quote : Char? = None
  let mut self_closing = false
  while cursor < chars.length() {
    let current = chars[cursor]
    match quote {
      Some(marker) =>
        if current == '\\' {
          cursor += 1
        } else if current == marker {
          quote = None
        }
      None =>
        if current == '"' || current == '\'' {
          quote = Some(current)
        } else if current == '/' {
          let next = skip_spaces(chars, cursor + 1)
          if next < chars.length() && chars[next] == '>' {
            self_closing = true
          }
        } else if current == '>' {
          let header = String::unsafe_substring(
            source,
            start=header_start,
            end=cursor,
          )
          let attrs = parse_block_attrs(header, tag.to_string(), filename)
          return Some((tag.to_string(), attrs, cursor + 1, self_closing))
        }
    }
    cursor += 1
  }
  match quote {
    Some(_) =>
      raise CompilerError::InvalidSfc(
        "unterminated attribute value in <\{tag.to_string()}> start tag of \{filename}",
      )
    None =>
      raise CompilerError::InvalidSfc(
        "unterminated <\{tag.to_string()}> start tag in \{filename}",
      )
  }
}

///|
fn read_end_tag_name(chars : Array[Char], start : Int) -> (String, Int)? {
  if start + 2 >= chars.length() ||
    chars[start] != '<' ||
    chars[start + 1] != '/' {
    return None
  }
  let mut cursor = start + 2
  cursor = skip_spaces(chars, cursor)
  let name_start = cursor
  while cursor < chars.length() && is_tag_name_char(chars[cursor]) {
    cursor += 1
  }
  if cursor == name_start {
    return None
  }
  let name = chars_to_lower_string(chars, name_start, cursor)
  cursor = skip_spaces(chars, cursor)
  if cursor < chars.length() && chars[cursor] == '>' {
    Some((name, cursor + 1))
  } else {
    None
  }
}

///|
fn parse_block_attrs(
  header : String,
  tag : String,
  filename : String,
) -> Array[BlockAttr] raise CompilerError {
  let attrs : Array[BlockAttr] = []
  let chars = header.to_array()
  let mut cursor = 0
  while cursor < chars.length() {
    cursor = skip_spaces(chars, cursor)
    if cursor >= chars.length() {
      break
    }
    if chars[cursor] == '/' {
      let next = skip_spaces(chars, cursor + 1)
      if next >= chars.length() {
        break
      }
      raise CompilerError::InvalidSfc(
        "unexpected `/` in <\{tag}> start tag of \{filename}",
      )
    }
    let name_start = cursor
    if cursor >= chars.length() ||
      not(is_block_attr_name_start_char(chars[cursor])) {
      raise CompilerError::InvalidSfc(
        "expected attribute name in <\{tag}> start tag of \{filename}",
      )
    }
    cursor += 1
    while cursor < chars.length() &&
          is_block_attr_name_continue_char(chars[cursor]) {
      cursor += 1
    }
    let name = String::unsafe_substring(header, start=name_start, end=cursor)
    cursor = skip_spaces(chars, cursor)
    if cursor < chars.length() && chars[cursor] == '=' {
      cursor += 1
      cursor = skip_spaces(chars, cursor)
      let (value, next) = read_attr_value(header, chars, cursor, tag, filename)
      attrs.push({ name, value: Some(value) })
      cursor = next
    } else {
      attrs.push({ name, value: None })
    }
  }
  attrs
}

///|
fn read_attr_value(
  source : String,
  chars : Array[Char],
  start : Int,
  tag : String,
  filename : String,
) -> (String, Int) raise CompilerError {
  if start >= chars.length() {
    raise CompilerError::InvalidSfc(
      "expected attribute value in <\{tag}> start tag of \{filename}",
    )
  }
  let marker = chars[start]
  if marker == '"' || marker == '\'' {
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
    raise CompilerError::InvalidSfc(
      "unterminated attribute value in <\{tag}> start tag of \{filename}",
    )
  } else {
    let mut cursor = start
    while cursor < chars.length() &&
          not(is_block_space(chars[cursor])) &&
          not(is_attr_value_self_closing_boundary(chars, cursor)) {
      cursor += 1
    }
    if cursor == start {
      raise CompilerError::InvalidSfc(
        "expected attribute value in <\{tag}> start tag of \{filename}",
      )
    }
    (String::unsafe_substring(source, start~, end=cursor), cursor)
  }
}

///|
fn is_attr_value_self_closing_boundary(
  chars : Array[Char],
  start : Int,
) -> Bool {
  if chars[start] != '/' {
    return false
  }
  let next = skip_spaces(chars, start + 1)
  next >= chars.length()
}

///|
fn is_block_attr_name_start_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_block_attr_name_continue_char(c : Char) -> Bool {
  is_block_attr_name_start_char(c) ||
  (c >= '0' && c <= '9') ||
  c == '-' ||
  c == '_'
}

///|
fn skip_spaces(chars : Array[Char], start : Int) -> Int {
  let mut cursor = start
  while cursor < chars.length() && is_block_space(chars[cursor]) {
    cursor += 1
  }
  cursor
}

///|
fn is_block_space(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\t' || c == '\r'
}

///|
fn is_tag_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
fn to_lower_char(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() - 'A'.to_int() + 'a'.to_int()).unsafe_to_char()
  } else {
    c
  }
}
