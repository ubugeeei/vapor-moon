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
  match find_style_attr(element.attrs) {
    Some(attr) => {
      let (base_expr, dynamic) = render_style_expr(attr, static_mode)
      let final_expr = match element.show_expr {
        Some(expr) => "@vm.show_style(" + expr + ", " + base_expr + ")"
        None => base_expr
      }
      Some(render_style_value(final_expr, dynamic, client))
    }
    None =>
      match element.show_expr {
        Some(expr) =>
          Some(
            render_style_value(
              "@vm.show_style(" + expr + ", \"\")",
              not(static_mode),
              client,
            ),
          )
        None => None
      }
  }
}

///|
fn render_style_expr(attr : TemplateAttr, static_mode : Bool) -> (String, Bool) {
  match attr.kind {
    Static => (quote(attr.value), false)
    Dynamic => (attr.value + ".to_string()", not(static_mode))
    Boolean => ("\"true\"", false)
    Event => ("\"\"", false)
  }
}

///|
fn render_style_value(expr : String, dynamic : Bool, client : Bool) -> String {
  if client {
    if dynamic {
      "(\"style\", @luna_dom.attr_dynamic_style(fn() { " + expr + " }))"
    } else {
      "(\"style\", @luna_dom.attr_style(" + expr + "))"
    }
  } else if dynamic {
    "(\"style\", @luna_core.attr_dynamic(fn() { " + expr + " }))"
  } else {
    "(\"style\", @luna_core.attr_static(" + expr + "))"
  }
}

///|
fn find_style_attr(attrs : Array[TemplateAttr]) -> TemplateAttr? {
  for attr in attrs {
    if attr.name == "style" {
      return Some(attr)
    }
  }
  None
}
