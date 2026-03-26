///|
pub fn emit_css(styles : Array[StyleBlock], scope_id : String?) -> String {
  let chunks : Array[String] = []
  for style in styles {
    if style.content.trim().is_empty() {
      continue
    }
    let css = match scope_id {
      Some(id) if style.scoped => scope_css_local(style.content, id)
      _ => style.content
    }
    chunks.push(css.trim().to_string())
  }
  chunks.join("\n\n")
}

///|
pub fn base_name(path : String) -> String {
  let no_ext = match path.rev_find(".") {
    Some(index) => String::unsafe_substring(path, start=0, end=index)
    None => path
  }
  match no_ext.rev_find("/") {
    Some(index) =>
      String::unsafe_substring(no_ext, start=index + 1, end=no_ext.length())
    None => no_ext
  }
}

///|
pub fn pascal_case(name : String) -> String {
  let parts = name.split("_").map(fn(part) { part.to_string() }).collect()
  let sb = StringBuilder::new()
  for part in parts {
    if part.length() == 0 {
      continue
    }
    let first = part[0].to_int()
    let upper = if first >= 'a'.to_int() && first <= 'z'.to_int() {
      (first - 'a'.to_int() + 'A'.to_int()).unsafe_to_char()
    } else {
      first.unsafe_to_char()
    }
    sb.write_char(upper)
    if part.length() > 1 {
      sb.write_string(
        String::unsafe_substring(part, start=1, end=part.length()),
      )
    }
  }
  let result = sb.to_string()
  if result.length() == 0 {
    "Component"
  } else {
    result
  }
}

///|
pub fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}

///|
fn indent_block(text : String, width : Int) -> String {
  let lines = text.split("\n").map(fn(line) { line.to_string() }).collect()
  let prefix = spaces(width)
  lines.map(fn(line) { prefix + line }).join("\n")
}

///|
fn indent_text(text : String, width : Int) -> String {
  spaces(width) + text
}

///|
fn spaces(width : Int) -> String {
  let sb = StringBuilder::new()
  for _ in 0..<width {
    sb.write_char(' ')
  }
  sb.to_string()
}

///|
fn quote(source : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in source {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
fn scope_css_local(css : String, scope_id : String) -> String {
  scope_css_rules(css, scope_id)
}

///|
fn scope_css_rules(css : String, scope_id : String) -> String {
  let scoped_chunks : Array[String] = []
  let mut index = 0
  while index < css.length() {
    index = skip_css_ignored(css, index)
    if index >= css.length() {
      break
    }
    if css[index] == '/' && index + 1 < css.length() && css[index + 1] == '*' {
      let next_index = skip_css_comment(css, index)
      scoped_chunks.push(
        String::unsafe_substring(css, start=index, end=next_index)
        .trim()
        .to_string(),
      )
      index = next_index
      continue
    }
    let header_start = index
    let mut in_string : UInt16? = None
    let mut escaped = false
    while index < css.length() {
      let ch = css[index]
      match in_string {
        Some(quote) => {
          if escaped {
            escaped = false
          } else if ch == '\\' {
            escaped = true
          } else if ch == quote {
            in_string = None
          }
          index += 1
        }
        None =>
          if ch == '"' || ch == '\'' {
            in_string = Some(ch)
            index += 1
          } else if ch == '/' &&
            index + 1 < css.length() &&
            css[index + 1] == '*' {
            index = skip_css_comment(css, index)
          } else if ch == '{' || ch == ';' {
            break
          } else {
            index += 1
          }
      }
    }
    let header = String::unsafe_substring(css, start=header_start, end=index)
      .trim()
      .to_string()
    if index >= css.length() {
      if header.length() > 0 {
        scoped_chunks.push(header)
      }
      break
    }
    let delimiter = css[index]
    if delimiter == ';' {
      if header.length() > 0 {
        scoped_chunks.push(header + ";")
      }
      index += 1
      continue
    }
    let (body, next_index) = read_css_block(css, index)
    index = next_index
    if header.length() == 0 {
      continue
    }
    if header.has_prefix("@") {
      let nested = if scopes_nested_css_rules(header) {
        scope_css_rules(body, scope_id)
      } else {
        body.trim().to_string()
      }
      scoped_chunks.push(wrap_css_block(header, nested))
    } else {
      let selectors = split_css_selector_list(header)
      let scoped_selectors : Array[String] = []
      for selector in selectors {
        let trimmed = selector.trim().to_string()
        if trimmed.length() > 0 {
          scoped_selectors.push(
            "[data-vm-scope=\"" + scope_id + "\"] " + trimmed,
          )
        }
      }
      if not(scoped_selectors.is_empty()) {
        scoped_chunks.push(
          wrap_css_block(scoped_selectors.join(", "), body.trim().to_string()),
        )
      }
    }
  }
  scoped_chunks.join("\n")
}

///|
fn read_css_block(source : String, open_brace_index : Int) -> (String, Int) {
  let mut index = open_brace_index + 1
  let mut depth = 1
  let mut in_string : UInt16? = None
  let mut escaped = false
  while index < source.length() {
    let ch = source[index]
    match in_string {
      Some(quote) => {
        if escaped {
          escaped = false
        } else if ch == '\\' {
          escaped = true
        } else if ch == quote {
          in_string = None
        }
        index += 1
      }
      None =>
        if ch == '"' || ch == '\'' {
          in_string = Some(ch)
          index += 1
        } else if ch == '/' &&
          index + 1 < source.length() &&
          source[index + 1] == '*' {
          index = skip_css_comment(source, index)
        } else if ch == '{' {
          depth += 1
          index += 1
        } else if ch == '}' {
          depth -= 1
          if depth == 0 {
            return (
              String::unsafe_substring(
                source,
                start=open_brace_index + 1,
                end=index,
              ),
              index + 1,
            )
          }
          index += 1
        } else {
          index += 1
        }
    }
  }
  (
    String::unsafe_substring(
      source,
      start=open_brace_index + 1,
      end=source.length(),
    ),
    source.length(),
  )
}

///|
fn split_css_selector_list(source : String) -> Array[String] {
  let selectors : Array[String] = []
  let mut start = 0
  let mut index = 0
  let mut in_string : UInt16? = None
  let mut escaped = false
  let mut paren_depth = 0
  let mut bracket_depth = 0
  while index < source.length() {
    let ch = source[index]
    match in_string {
      Some(quote) => {
        if escaped {
          escaped = false
        } else if ch == '\\' {
          escaped = true
        } else if ch == quote {
          in_string = None
        }
        index += 1
      }
      None =>
        if ch == '"' || ch == '\'' {
          in_string = Some(ch)
          index += 1
        } else if ch == '/' &&
          index + 1 < source.length() &&
          source[index + 1] == '*' {
          index = skip_css_comment(source, index)
        } else if ch == '(' {
          paren_depth += 1
          index += 1
        } else if ch == ')' {
          if paren_depth > 0 {
            paren_depth -= 1
          }
          index += 1
        } else if ch == '[' {
          bracket_depth += 1
          index += 1
        } else if ch == ']' {
          if bracket_depth > 0 {
            bracket_depth -= 1
          }
          index += 1
        } else if ch == ',' && paren_depth == 0 && bracket_depth == 0 {
          selectors.push(String::unsafe_substring(source, start~, end=index))
          start = index + 1
          index += 1
        } else {
          index += 1
        }
    }
  }
  selectors.push(String::unsafe_substring(source, start~, end=source.length()))
  selectors
}

///|
fn skip_css_ignored(source : String, start : Int) -> Int {
  let mut index = start
  while index < source.length() {
    let ch = source[index]
    if ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' {
      index += 1
      continue
    }
    break
  }
  index
}

///|
fn skip_css_comment(source : String, start : Int) -> Int {
  let mut index = start + 2
  while index + 1 < source.length() {
    if source[index] == '*' && source[index + 1] == '/' {
      return index + 2
    }
    index += 1
  }
  source.length()
}

///|
fn scopes_nested_css_rules(header : String) -> Bool {
  not(
    header.has_prefix("@keyframes") ||
    header.has_prefix("@-webkit-keyframes") ||
    header.has_prefix("@font-face") ||
    header.has_prefix("@page") ||
    header.has_prefix("@property"),
  )
}

///|
fn wrap_css_block(header : String, body : String) -> String {
  header + " { " + body.trim().to_string() + " }"
}
