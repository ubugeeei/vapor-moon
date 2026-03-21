///|
fn collect_client_attr_entries(
  element : TemplateElement,
  scope_id : String?,
  static_mode : Bool,
) -> Array[String] {
  let parts : Array[String] = []
  for attr in element.attrs {
    if attr.name != "style" {
      parts.push(render_client_attr(attr, static_mode))
    }
  }
  push_if_some(parts, render_client_style_attr(element, static_mode))
  push_if_some(parts, render_client_key_attr(element))
  push_if_some(parts, render_client_ref_attr(element))
  push_if_some(parts, render_client_html_attr(element, static_mode))
  for attr in render_client_model_attrs(element, static_mode) {
    parts.push(attr)
  }
  match scope_id {
    Some(id) =>
      parts.push("(\"data-vm-scope\", @vm_dom.attr_static(" + quote(id) + "))")
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
    if attr.name != "style" {
      match attr.kind {
        Event => ()
        _ => parts.push(render_server_attr(attr, static_mode))
      }
    }
  }
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
        "(\"" + attr.name + "\", @vm_dom.attr_style(" + quote(attr.value) + "))"
      } else {
        "(\"" +
        attr.name +
        "\", @vm_dom.attr_static(" +
        quote(attr.value) +
        "))"
      }
    Dynamic =>
      if static_mode {
        if attr.name == "style" {
          "(\"" +
          attr.name +
          "\", @vm_dom.attr_style(" +
          attr.value +
          ".to_string()))"
        } else {
          "(\"" +
          attr.name +
          "\", @vm_dom.attr_static(" +
          attr.value +
          ".to_string()))"
        }
      } else if attr.name == "style" {
        "(\"" +
        attr.name +
        "\", @vm_dom.attr_dynamic_style(fn() { " +
        attr.value +
        ".to_string() }))"
      } else {
        "(\"" +
        attr.name +
        "\", @vm_dom.attr_dynamic(fn() { " +
        attr.value +
        ".to_string() }))"
      }
    Event =>
      "(\"" +
      attr.name +
      "\", @vm_dom.attr_handler(fn(_event) { " +
      attr.value +
      " }))"
    Boolean => "(\"" + attr.name + "\", @vm_dom.attr_static(\"\"))"
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
