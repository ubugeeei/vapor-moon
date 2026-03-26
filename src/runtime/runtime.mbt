///|
/// Shared runtime helpers used by generated Vapor Moon code.
/// Component contracts themselves are generated as plain typed arguments.

///|
pub(all) enum HydrationMode {
  Manual
  Load
  Idle
  Visible
  Media(String)
  Only
  ServerDefer
} derive(Eq, Show)

///|
pub struct TemplateRef[T] {
  name : String
  phantom : T?
}

///|
pub fn client_module_path(component_name : String) -> String {
  "/_vapor_moon/" + sanitize_component_name(component_name) + ".js"
}

///|
pub fn make_scope_id(component_name : String) -> String {
  "vm-" + hash_string(component_name)
}

///|
pub fn[T] use_template_ref(name : String) -> TemplateRef[T] {
  { name, phantom: None }
}

///|
pub fn use_id(component_name : String, index : Int) -> String {
  sanitize_component_name(component_name) + "-id-" + index.to_string()
}

///|
pub fn[T] TemplateRef::name(self : TemplateRef[T]) -> String {
  self.name
}

///|
pub fn props_to_json(entries : Array[(String, String)]) -> String {
  if entries.is_empty() {
    return "{}"
  }
  let parts : Array[String] = []
  for entry in entries {
    parts.push(escape_json_string(entry.0) + ":" + escape_json_value(entry.1))
  }
  "{" + parts.join(",") + "}"
}

///|
pub fn scope_css(css : String, scope_id : String) -> String {
  scope_css_rules(css, scope_id)
}

///|
pub fn show_style(visible : Bool, base : String) -> String {
  let base_style = normalize_style(base)
  if visible {
    return base_style
  }
  if base_style.length() == 0 {
    "display: none;"
  } else if base_style.has_suffix(";") {
    base_style + " display: none;"
  } else {
    base_style + "; display: none;"
  }
}

///|
pub fn merge_class_names(parts : Array[String]) -> String {
  let merged : Array[String] = []
  for part in parts {
    let trimmed = part.trim().to_string()
    if trimmed.length() > 0 {
      merged.push(trimmed)
    }
  }
  merged.join(" ")
}

///|
pub fn merge_styles(parts : Array[String]) -> String {
  let merged : Array[String] = []
  for part in parts {
    let trimmed = normalize_style(part)
    if trimmed.length() == 0 {
      continue
    }
    if trimmed.has_suffix(";") {
      merged.push(trimmed)
    } else {
      merged.push(trimmed + ";")
    }
  }
  merged.join(" ")
}

///|
fn escape_json_string(source : String) -> String {
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
fn escape_json_value(source : String) -> String {
  if source == "true" || source == "false" || source == "null" {
    return source
  }
  let all_digits = source.length() > 0 &&
    source
    .to_array()
    .all(fn(ch) { (ch >= '0' && ch <= '9') || ch == '.' || ch == '-' })
  if all_digits {
    source
  } else {
    escape_json_string(source)
  }
}

///|
fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}

///|
fn sanitize_component_name(component_name : String) -> String {
  let sb = StringBuilder::new()
  for ch in component_name {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '-' {
      sb.write_char(ch)
    } else {
      sb.write_char('_')
    }
  }
  sb.to_string() + "-" + hash_string(component_name)
}

///|
fn normalize_style(source : String) -> String {
  source.trim().to_string()
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
