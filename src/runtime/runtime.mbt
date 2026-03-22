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
pub struct TemplateRef {
  name : String
} derive(Eq, Show)

///|
pub fn client_module_path(component_name : String) -> String {
  "/_vapor_moon/" + sanitize_component_name(component_name) + ".js"
}

///|
pub fn make_scope_id(component_name : String) -> String {
  "vm-" + hash_string(component_name)
}

///|
pub fn use_template_ref(name : String) -> TemplateRef {
  { name, }
}

///|
pub fn use_id(component_name : String, index : Int) -> String {
  sanitize_component_name(component_name) + "-id-" + index.to_string()
}

///|
pub fn TemplateRef::name(self : TemplateRef) -> String {
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
  let chunks = css.split("}").map(fn(part) { part.to_string() }).collect()
  let scoped : Array[String] = []
  for chunk in chunks {
    let trimmed = chunk.trim().to_string()
    if trimmed.length() == 0 {
      continue
    }
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
          scoped.push(selector + " { " + body + " }")
        } else {
          let selectors = selector
            .split(",")
            .map(fn(part) {
              "[data-vm-scope=\"" + scope_id + "\"] " + part.trim().to_string()
            })
            .collect()
          scoped.push(selectors.join(", ") + " { " + body + " }")
        }
      }
      None => scoped.push(trimmed)
    }
  }
  scoped.join("\n")
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
