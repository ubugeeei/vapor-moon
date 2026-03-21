///|
fn render_client_key_attr(element : TemplateElement) -> String? {
  match element.key_expr {
    Some(expr) =>
      Some(
        "(\"data-vm-key\", @vm_dom.attr_dynamic(fn() { " +
        expr +
        ".to_string() }))",
      )
    None => None
  }
}

///|
fn render_server_key_attr(element : TemplateElement) -> String? {
  match element.key_expr {
    Some(expr) =>
      Some(
        "(\"data-vm-key\", @luna_core.attr_dynamic(fn() { " +
        expr +
        ".to_string() }))",
      )
    None => None
  }
}

///|
fn render_client_ref_attr(element : TemplateElement) -> String? {
  match element.ref_name {
    Some(expr) =>
      Some(
        "(\"__ref\", @vm_dom.attr_handler(fn(target) { @vm_dom.bind_template_ref(" +
        expr +
        ", target) }))",
      )
    None => None
  }
}

///|
fn render_server_ref_attr(element : TemplateElement) -> String? {
  match element.ref_name {
    Some(expr) =>
      Some(
        "(\"data-vm-ref\", @luna_core.attr_dynamic(fn() { " +
        expr +
        ".to_string() }))",
      )
    None => None
  }
}

///|
fn render_client_component_meta_attrs(element : TemplateElement) -> String {
  let parts : Array[String] = []
  push_if_some(parts, render_client_key_attr(element))
  push_if_some(parts, render_client_ref_attr(element))
  if parts.is_empty() {
    "[]"
  } else {
    "[" + parts.join(", ") + "]"
  }
}

///|
fn render_server_component_meta_attrs(element : TemplateElement) -> String {
  let parts : Array[String] = []
  push_if_some(parts, render_server_key_attr(element))
  push_if_some(parts, render_server_ref_attr(element))
  if parts.is_empty() {
    "[]"
  } else {
    "[" + parts.join(", ") + "]"
  }
}

///|
fn render_client_html_attr(
  element : TemplateElement,
  static_mode : Bool,
) -> String? {
  match element.html_expr {
    Some(expr) =>
      if static_mode {
        Some("(\"__innerHTML\", @vm_dom.attr_static(" + expr + ".to_string()))")
      } else {
        Some(
          "(\"__innerHTML\", @vm_dom.attr_dynamic(fn() { " +
          expr +
          ".to_string() }))",
        )
      }
    None => None
  }
}

///|
fn render_client_model_attrs(
  element : TemplateElement,
  static_mode : Bool,
) -> Array[String] {
  let parts : Array[String] = []
  match element.model {
    Some(model) if not(element.is_component) => {
      let checked = infer_model_checked(element)
      let event_name = if element.tag == "select" { "change" } else { "input" }
      let value_expr = if checked {
        "if " + model.expression + " { \"true\" } else { \"false\" }"
      } else {
        model.expression + ".to_string()"
      }
      let attr_name = if checked { "checked" } else { "value" }
      if static_mode {
        parts.push(
          "(\"" + attr_name + "\", @vm_dom.attr_static(" + value_expr + "))",
        )
      } else {
        parts.push(
          "(\"" +
          attr_name +
          "\", @vm_dom.attr_dynamic(fn() { " +
          value_expr +
          " }))",
        )
      }
      parts.push(
        "(\"" +
        event_name +
        "\", @vm_dom.attr_handler(fn(_event) { " +
        render_model_write_expr(
          model.expression,
          render_model_read_expr(model, checked),
        ) +
        " }))",
      )
    }
    _ => ()
  }
  parts
}

///|
fn render_server_model_attrs(
  element : TemplateElement,
  static_mode : Bool,
) -> Array[String] {
  let parts : Array[String] = []
  match element.model {
    Some(model) if not(element.is_component) => {
      let checked = infer_model_checked(element)
      let attr_name = if checked { "checked" } else { "value" }
      let value_expr = if checked {
        "if " + model.expression + " { \"true\" } else { \"false\" }"
      } else {
        model.expression + ".to_string()"
      }
      if static_mode {
        parts.push(
          "(\"" + attr_name + "\", @luna_core.attr_static(" + value_expr + "))",
        )
      } else {
        parts.push(
          "(\"" +
          attr_name +
          "\", @luna_core.attr_dynamic(fn() { " +
          value_expr +
          " }))",
        )
      }
    }
    _ => ()
  }
  parts
}

///|
fn infer_model_checked(element : TemplateElement) -> Bool {
  if element.tag != "input" {
    return false
  }
  for attr in element.attrs {
    if attr.name == "type" && attr.kind == Static && attr.value == "checkbox" {
      return true
    }
  }
  false
}

///|
fn render_model_read_expr(model : TemplateModel, checked : Bool) -> String {
  let mut value_expr = if checked {
    "_event._get(\"target\")._get(\"checked\").cast()"
  } else {
    "_event._get(\"target\")._get(\"value\").cast()"
  }
  if not(checked) && has_model_modifier(model, "trim") {
    value_expr = "(" + value_expr + ").trim().to_string()"
  }
  value_expr
}

///|
fn render_model_write_expr(target : String, value_expr : String) -> String {
  if target.has_suffix(".get()") && target.length() > 6 {
    String::unsafe_substring(target, start=0, end=target.length() - 6) +
    ".set(" +
    value_expr +
    ")"
  } else {
    target + " = " + value_expr
  }
}

///|
fn has_model_modifier(model : TemplateModel, expected : String) -> Bool {
  for modifier in model.modifiers {
    if modifier == expected {
      return true
    }
  }
  false
}
