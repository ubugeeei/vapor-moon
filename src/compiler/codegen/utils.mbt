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
      sb.write_string(String::unsafe_substring(part, start=1, end=part.length()))
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
  let chunks = css.split("}").map(fn(part) { part.to_string() }).collect()
  let scoped_chunks : Array[String] = []
  for chunk in chunks {
    if chunk.trim().is_empty() {
      continue
    }
    let trimmed = chunk.trim().to_string()
    match trimmed.find("{") {
      Some(index) => {
        let selector = String::unsafe_substring(trimmed, start=0, end=index)
          .trim()
          .to_string()
        let body = String::unsafe_substring(
            trimmed,
            start=index + 1,
            end=trimmed.length(),
          )
          .trim()
          .to_string()
        if selector.has_prefix("@") {
          scoped_chunks.push(selector + " { " + body + " }")
        } else {
          let selectors = selector
            .split(",")
            .map(fn(part) {
              "[data-vm-scope=\"" + scope_id + "\"] " + part.trim().to_string()
            })
            .collect()
          scoped_chunks.push(selectors.join(", ") + " { " + body + " }")
        }
      }
      None => scoped_chunks.push(trimmed)
    }
  }
  scoped_chunks.join("\n")
}
