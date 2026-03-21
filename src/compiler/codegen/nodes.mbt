///|
fn render_client_nodes(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
) -> String {
  if nodes.length() == 1 {
    indent_text(render_client_node(nodes[0], indent, scope_id, false), indent)
  } else {
    let children = render_client_children(nodes, indent, scope_id, false)
    indent_text("@luna_dom.fragment(" + children + ")", indent)
  }
}

///|
fn render_server_nodes(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
) -> String {
  if nodes.length() == 1 {
    indent_text(render_server_node(nodes[0], indent, scope_id, false), indent)
  } else {
    let children = render_server_children(nodes, indent, scope_id, false)
    indent_text("@luna_core.fragment(" + children + ")", indent)
  }
}

///|
fn render_client_node(
  node : TemplateNode,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  match node {
    Text(content) => "@luna_dom.text(" + quote(content) + ")"
    Interpolation(expr) =>
      if static_mode {
        "@luna_dom.text(" + expr + ".to_string())"
      } else {
        "@luna_dom.text_dyn(fn() { " + expr + ".to_string() })"
      }
    Element(element) => {
      let next_static = static_mode || element.once
      let rendered = if element.is_component {
        render_client_component(element, indent, scope_id, next_static)
      } else {
        render_client_element(element, indent, scope_id, next_static)
      }
      wrap_client_directives(element, rendered)
    }
  }
}

///|
fn render_server_node(
  node : TemplateNode,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  match node {
    Text(content) => "@luna_core.text(" + quote(content) + ")"
    Interpolation(expr) =>
      if static_mode {
        "@luna_core.text(" + expr + ".to_string())"
      } else {
        "@luna_core.text_dyn(fn() { " + expr + ".to_string() })"
      }
    Element(element) => {
      let next_static = static_mode || element.once
      let rendered = if element.is_component {
        render_server_component(element, indent, scope_id, next_static)
      } else {
        render_server_element(element, indent, scope_id, next_static)
      }
      wrap_server_directives(element, rendered)
    }
  }
}

///|
fn wrap_client_directives(
  element : TemplateElement,
  rendered : String,
) -> String {
  let mut current = rendered
  match element.if_expr {
    Some(expr) =>
      current = "@luna_dom.show(fn() { " +
        expr +
        " }, fn() { " +
        current +
        " })"
    None => ()
  }
  match element.for_binding {
    Some(binding) => {
      let index_name = binding.index.unwrap_or("_index")
      current = "@luna_dom.for_each(fn() { " +
        binding.source +
        " }, fn(" +
        binding.value +
        ", " +
        index_name +
        ") { " +
        current +
        " })"
    }
    None => ()
  }
  current
}

///|
fn wrap_server_directives(
  element : TemplateElement,
  rendered : String,
) -> String {
  let mut current = rendered
  match element.if_expr {
    Some(expr) =>
      current = "@luna_core.show(fn() { " +
        expr +
        " }, fn() { " +
        current +
        " })"
    None => ()
  }
  match element.for_binding {
    Some(binding) => {
      let index_name = binding.index.unwrap_or("_index")
      current = "@luna_core.for_each(fn() { " +
        binding.source +
        ".map(fn(" +
        binding.value +
        ", " +
        index_name +
        ") { " +
        current +
        " }) })"
    }
    None => ()
  }
  current
}
