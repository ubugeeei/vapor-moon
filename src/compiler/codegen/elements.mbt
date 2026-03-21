///|
fn render_client_element(
  element : TemplateElement,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let attrs = render_client_attrs(element, scope_id, static_mode)
  let children = if element.html_expr is Some(_) {
    "[]"
  } else {
    render_client_children(element.children, indent + 2, scope_id, static_mode)
  }
  "@luna_dom.create_element(" +
  quote(element.tag) +
  ", " +
  attrs +
  ", " +
  children +
  ")"
}

///|
fn render_server_element(
  element : TemplateElement,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let attrs = render_server_attrs(element, scope_id, static_mode)
  let children = match element.html_expr {
    Some(expr) => "[@luna_core.raw_html(" + expr + ".to_string())]"
    None =>
      render_server_children(
        element.children,
        indent + 2,
        scope_id,
        static_mode,
      )
  }
  "@luna_core.h(" + quote(element.tag) + ", " + attrs + ", " + children + ")"
}

///|
fn render_client_component(
  element : TemplateElement,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let props = render_client_component_props(element, static_mode)
  let children = render_client_children(
    element.children,
    indent + 2,
    scope_id,
    static_mode,
  )
  match element.island_mode {
    Load | Idle | Visible | Media(_) | Only | ServerDefer =>
      "@vm_dom.island_dom(" +
      quote(element.tag) +
      ", " +
      render_mode_expr(element.island_mode) +
      ", " +
      props +
      ", " +
      children +
      ")"
    None =>
      "@vm_dom.component_dom(" +
      quote(element.tag) +
      ", " +
      props +
      ", " +
      children +
      ")"
  }
}

///|
fn render_server_component(
  element : TemplateElement,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let props = render_server_component_props(element, static_mode)
  let children = render_server_children(
    element.children,
    indent + 2,
    scope_id,
    static_mode,
  )
  match element.island_mode {
    Load | Idle | Visible | Media(_) | Only | ServerDefer =>
      "@vm_server.island_ssr(" +
      quote(element.tag) +
      ", " +
      props +
      ", " +
      children +
      ", " +
      render_mode_expr(element.island_mode) +
      ")"
    None =>
      "@vm_server.component_ssr(" +
      quote(element.tag) +
      ", " +
      props +
      ", " +
      children +
      ")"
  }
}

///|
fn render_client_children(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  if nodes.is_empty() {
    return "[]"
  }
  let lines : Array[String] = []
  for node in nodes {
    lines.push(
      indent_text(
        render_client_node(node, indent + 2, scope_id, static_mode),
        indent + 2,
      ),
    )
  }
  "[\n" + lines.join(",\n") + "\n" + spaces(indent) + "]"
}

///|
fn render_server_children(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  if nodes.is_empty() {
    return "[]"
  }
  let lines : Array[String] = []
  for node in nodes {
    lines.push(
      indent_text(
        render_server_node(node, indent + 2, scope_id, static_mode),
        indent + 2,
      ),
    )
  }
  "[\n" + lines.join(",\n") + "\n" + spaces(indent) + "]"
}

///|
pub fn collect_island_components(nodes : Array[TemplateNode]) -> Array[String] {
  let result : Array[String] = []
  for node in nodes {
    collect_node_islands(node, result)
  }
  result
}

///|
fn collect_node_islands(node : TemplateNode, result : Array[String]) -> Unit {
  match node {
    Element(element) => {
      match element.island_mode {
        Load | Idle | Visible | Media(_) | Only | ServerDefer =>
          result.push(element.tag)
        None => ()
      }
      for child in element.children {
        collect_node_islands(child, result)
      }
    }
    _ => ()
  }
}
