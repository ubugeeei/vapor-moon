///|
fn render_client_nodes(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
) -> String {
  if nodes.length() == 1 {
    indent_block(render_client_node(nodes[0], indent, scope_id, false), indent)
  } else {
    let children = render_client_children(nodes, indent, scope_id, false)
    indent_block("@vm_dom.fragment(" + children + ")", indent)
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
    Text(content) => "@vm_dom.text(" + quote(content) + ")"
    Interpolation(expr) =>
      if static_mode {
        "@vm_dom.text(" + expr + ".to_string())"
      } else {
        "@vm_dom.text_expr(fn() { " + expr + ".to_string() })"
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
    Conditional(branches) =>
      render_client_conditional(branches, indent, scope_id, static_mode)
  }
}

///|
fn render_client_conditional(
  branches : Array[ConditionalBranch],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let sb = StringBuilder::new()
  for i, branch in branches {
    let rendered = render_client_node(
      Element(branch.element), indent + 2, scope_id, static_mode,
    )
    match branch.condition {
      Some(condition) =>
        if i == 0 {
          sb.write_string("if " + condition + " {\n")
        } else {
          sb.write_string(" else if " + condition + " {\n")
        }
      None => sb.write_string(" else {\n")
    }
    sb.write_string(indent_block(rendered, indent + 2))
    sb.write_string("\n" + spaces(indent) + "}")
  }
  sb.to_string()
}

///|
fn render_client_append_statements(
  target_expr : String,
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> Array[String] {
  let statements : Array[String] = []
  for node in nodes {
    statements.push(
      "@vm_dom.append_child(" +
      target_expr +
      ", " +
      render_client_node(node, indent + 2, scope_id, static_mode) +
      ")",
    )
  }
  statements
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
    Conditional(branches) =>
      render_server_conditional(branches, indent, scope_id, static_mode)
  }
}

///|
fn render_server_conditional(
  branches : Array[ConditionalBranch],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let sb = StringBuilder::new()
  for i, branch in branches {
    let rendered = render_server_node(
      Element(branch.element), indent + 2, scope_id, static_mode,
    )
    match branch.condition {
      Some(condition) =>
        if i == 0 {
          sb.write_string("if " + condition + " {\n")
        } else {
          sb.write_string(" else if " + condition + " {\n")
        }
      None => sb.write_string(" else {\n")
    }
    sb.write_string(indent_text(rendered, indent + 2))
    sb.write_string("\n" + spaces(indent) + "}")
  }
  sb.to_string()
}

///|
fn wrap_client_directives(
  element : TemplateElement,
  rendered : String,
) -> String {
  let mut current = rendered
  match element.if_expr {
    Some(expr) =>
      current = "@vm_dom.show(fn() { " + expr + " }, fn() { " + current + " })"
    None => ()
  }
  match element.for_binding {
    Some(binding) => {
      let index_name = binding.index.unwrap_or("_index")
      current = "@vm_dom.for_each(fn() { " +
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
