///|
fn collect_client_attr_entries(
  element : TemplateElement,
  scope_id : String?,
  static_mode : Bool,
) -> Array[String] {
  let parts : Array[String] = []
  for attr in element.attrs {
    if attr.name != "style" && not(is_class_attr_name(attr.name)) {
      parts.push(render_client_attr(attr, static_mode))
    }
  }
  push_if_some(parts, render_client_class_attr(element, static_mode))
  push_if_some(parts, render_client_style_attr(element, static_mode))
  push_if_some(parts, render_client_key_attr(element))
  push_if_some(parts, render_client_ref_attr(element))
  push_if_some(parts, render_client_html_attr(element, static_mode))
  for attr in render_client_model_attrs(element, static_mode) {
    parts.push(attr)
  }
  match scope_id {
    Some(id) =>
      parts.push("(\"data-vm-scope\", @v.attr(" + quote(id) + "))")
    None => ()
  }
  parts
}

///|
fn render_server_attrs(
  element : TemplateElement,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let parts : Array[String] = []
  for attr in element.attrs {
    if attr.name != "style" && not(is_class_attr_name(attr.name)) {
      match attr.kind {
        Event => ()
        _ => parts.push(render_server_attr(attr, static_mode))
      }
    }
  }
  push_if_some(parts, render_server_class_attr(element, static_mode))
  push_if_some(parts, render_server_style_attr(element, static_mode))
  push_if_some(parts, render_server_key_attr(element))
  push_if_some(parts, render_server_ref_attr(element))
  for attr in render_server_model_attrs(element, static_mode) {
    parts.push(attr)
  }
  match scope_id {
    Some(id) =>
      parts.push(
        "(\"data-vm-scope\", @luna_core.attr_static(" + quote(id) + "))",
      )
    None => ()
  }
  if parts.is_empty() {
    "[]"
  } else {
    "[" + parts.join(", ") + "]"
  }
}

///|
fn render_client_attr(attr : TemplateAttr, static_mode : Bool) -> String {
  match attr.kind {
    Static =>
      if attr.name == "style" {
        "(\"" + attr.name + "\", @v.style(" + quote(attr.value) + "))"
      } else {
        "(\"" + attr.name + "\", @v.attr(" + quote(attr.value) + "))"
      }
    Dynamic =>
      if static_mode {
        if attr.name == "style" {
          "(\"" +
          attr.name +
          "\", @v.style(" +
          attr.value +
          ".to_string()))"
        } else {
          "(\"" +
          attr.name +
          "\", @v.attr(" +
          attr.value +
          ".to_string()))"
        }
      } else if attr.name == "style" {
        "(\"" +
        attr.name +
        "\", @v.dynStyle(fn() { " +
        attr.value +
        ".to_string() }))"
      } else {
        "(\"" +
        attr.name +
        "\", @v.dynAttr(fn() { " +
        attr.value +
        ".to_string() }))"
      }
    Event => render_client_event_attr(attr)
    Boolean => "(\"" + attr.name + "\", @v.attr(\"\"))"
  }
}

///|
fn render_server_attr(attr : TemplateAttr, static_mode : Bool) -> String {
  match attr.kind {
    Static =>
      "(\"" +
      attr.name +
      "\", @luna_core.attr_static(" +
      quote(attr.value) +
      "))"
    Dynamic =>
      if static_mode {
        "(\"" +
        attr.name +
        "\", @luna_core.attr_static(" +
        attr.value +
        ".to_string()))"
      } else {
        "(\"" +
        attr.name +
        "\", @luna_core.attr_dynamic(fn() { " +
        attr.value +
        ".to_string() }))"
      }
    Event => "(\"" + attr.name + "\", @luna_core.attr_static(\"\"))"
    Boolean => "(\"" + attr.name + "\", @luna_core.attr_static(\"\"))"
  }
}

///|
fn push_if_some(parts : Array[String], value : String?) -> Unit {
  match value {
    Some(item) => parts.push(item)
    None => ()
  }
}

///|
fn render_client_event_attr(attr : TemplateAttr) -> String {
  let handler = "fn(_event) { " + attr.value + " }"
  if attr.modifiers.is_empty() {
    "(\"" + attr.name + "\", @v.on(" + handler + "))"
  } else {
    "(\"" +
    attr.name +
    "\", @v.onWith(" +
    handler +
    ", " +
    render_string_array(attr.modifiers) +
    "))"
  }
}

///|
fn render_string_array(values : Array[String]) -> String {
  if values.is_empty() {
    return "[]"
  }
  let quoted : Array[String] = []
  for value in values {
    quoted.push(quote(value))
  }
  "[" + quoted.join(", ") + "]"
}
