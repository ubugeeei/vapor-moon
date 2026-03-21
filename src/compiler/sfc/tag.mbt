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
        "`generic` is only supported on <script setup> in \{filename}",
      )
    }
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
fn read_start_tag(
  source : String,
  chars : Array[Char],
  start : Int,
) -> (String, Array[BlockAttr], Int)? {
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
  while cursor < chars.length() {
    let current = chars[cursor]
    match quote {
      Some(marker) => if current == marker { quote = None }
      None =>
        if current == '"' || current == '\'' {
          quote = Some(current)
        } else if current == '>' {
          let header = String::unsafe_substring(
            source,
            start=header_start,
            end=cursor,
          )
          let attrs = parse_block_attrs(header)
          return Some((tag.to_string(), attrs, cursor + 1))
        }
    }
    cursor += 1
  }
  None
}

///|
fn parse_block_attrs(header : String) -> Array[BlockAttr] {
  let attrs : Array[BlockAttr] = []
  let chars = header.to_array()
  let mut cursor = 0
  while cursor < chars.length() {
    cursor = skip_spaces(chars, cursor)
    if cursor >= chars.length() {
      break
    }
    let name_start = cursor
    while cursor < chars.length() &&
          not(is_block_space(chars[cursor])) &&
          chars[cursor] != '=' &&
          chars[cursor] != '/' {
      cursor += 1
    }
    if cursor == name_start {
      cursor += 1
      continue
    }
    let name = String::unsafe_substring(header, start=name_start, end=cursor)
    cursor = skip_spaces(chars, cursor)
    if cursor < chars.length() && chars[cursor] == '=' {
      cursor += 1
      cursor = skip_spaces(chars, cursor)
      let (value, next) = read_attr_value(header, chars, cursor)
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
) -> (String, Int) {
  if start >= chars.length() {
    return ("", start)
  }
  let marker = chars[start]
  if marker == '"' || marker == '\'' {
    let mut cursor = start + 1
    while cursor < chars.length() {
      if chars[cursor] == marker {
        return (
          String::unsafe_substring(source, start=start + 1, end=cursor),
          cursor + 1,
        )
      }
      cursor += 1
    }
    (
      String::unsafe_substring(source, start=start + 1, end=chars.length()),
      chars.length(),
    )
  } else {
    let mut cursor = start
    while cursor < chars.length() &&
          not(is_block_space(chars[cursor])) &&
          chars[cursor] != '/' {
      cursor += 1
    }
    (String::unsafe_substring(source, start~, end=cursor), cursor)
  }
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
