///|
fn render_client_class_attr(
  element : TemplateElement,
  static_mode : Bool,
) -> String? {
  render_class_attr(element.attrs, static_mode, true)
}

///|
fn render_server_class_attr(
  element : TemplateElement,
  static_mode : Bool,
) -> String? {
  render_class_attr(element.attrs, static_mode, false)
}

///|
fn render_class_attr(
  attrs : Array[TemplateAttr],
  static_mode : Bool,
  client : Bool,
) -> String? {
  let class_attrs = find_class_attrs(attrs)
  if class_attrs.is_empty() {
    return None
  }
  let (expr, dynamic) = render_merged_attr_expr(class_attrs, static_mode, false)
  Some(render_class_value(expr, dynamic, client))
}

///|
fn render_client_style_attr(
  element : TemplateElement,
  static_mode : Bool,
) -> String? {
  render_style_attr(element, static_mode, true)
}

///|
fn render_server_style_attr(
  element : TemplateElement,
  static_mode : Bool,
) -> String? {
  render_style_attr(element, static_mode, false)
}

///|
fn render_style_attr(
  element : TemplateElement,
  static_mode : Bool,
  client : Bool,
) -> String? {
  let style_attrs = find_style_attrs(element.attrs)
  if not(style_attrs.is_empty()) {
    let (base_expr, base_dynamic) = render_merged_attr_expr(
      style_attrs, static_mode, true,
    )
    let dynamic = base_dynamic ||
      (element.show_expr is Some(_) && not(static_mode))
    let final_expr = match element.show_expr {
      Some(expr) => "@r.show_style(" + expr + ", " + base_expr + ")"
      None => base_expr
    }
    Some(render_style_value(final_expr, dynamic, client))
  } else {
    match element.show_expr {
      Some(expr) =>
        Some(
          render_style_value(
            "@r.show_style(" + expr + ", \"\")",
            not(static_mode),
            client,
          ),
        )
      None => None
    }
  }
}

///|
fn render_merged_attr_expr(
  attrs : Array[TemplateAttr],
  static_mode : Bool,
  style_mode : Bool,
) -> (String, Bool) {
  if attrs.length() == 1 {
    return render_attr_expr(attrs[0], static_mode, style_mode)
  }
  let parts : Array[String] = []
  let mut dynamic = false
  for attr in attrs {
    let (expr, part_dynamic) = render_attr_expr(attr, static_mode, style_mode)
    parts.push(expr)
    if part_dynamic {
      dynamic = true
    }
  }
  (
    if style_mode {
      "@r.merge_styles([" + parts.join(", ") + "])"
    } else {
      "@r.merge_class_names([" + parts.join(", ") + "])"
    },
    dynamic,
  )
}

///|
fn render_attr_expr(
  attr : TemplateAttr,
  static_mode : Bool,
  style_mode : Bool,
) -> (String, Bool) {
  match attr.kind {
    Static => (quote(attr.value), false)
    Dynamic => (attr.value + ".to_string()", not(static_mode))
    Boolean => (if style_mode { "\"\"" } else { "\"\"" }, false)
    Event => ("\"\"", false)
  }
}

///|
fn render_class_value(expr : String, dynamic : Bool, client : Bool) -> String {
  if client {
    if dynamic {
      "(\"class\", @d.dynAttr(fn() { " + expr + " }))"
    } else {
      "(\"class\", @d.attr(" + expr + "))"
    }
  } else if dynamic {
    "(\"class\", @luna_core.attr_dynamic(fn() { " + expr + " }))"
  } else {
    "(\"class\", @luna_core.attr_static(" + expr + "))"
  }
}

///|
fn render_style_value(expr : String, dynamic : Bool, client : Bool) -> String {
  if client {
    if dynamic {
      "(\"style\", @d.dynStyle(fn() { " + expr + " }))"
    } else {
      "(\"style\", @d.style(" + expr + "))"
    }
  } else if dynamic {
    "(\"style\", @luna_core.attr_dynamic(fn() { " + expr + " }))"
  } else {
    "(\"style\", @luna_core.attr_static(" + expr + "))"
  }
}

///|
fn find_style_attrs(attrs : Array[TemplateAttr]) -> Array[TemplateAttr] {
  let style_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    if attr.name == "style" {
      style_attrs.push(attr)
    }
  }
  style_attrs
}

///|
fn find_class_attrs(attrs : Array[TemplateAttr]) -> Array[TemplateAttr] {
  let class_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    if is_class_attr_name(attr.name) {
      class_attrs.push(attr)
    }
  }
  class_attrs
}

///|
fn is_class_attr_name(name : String) -> Bool {
  name == "class" || name == "className"
}
