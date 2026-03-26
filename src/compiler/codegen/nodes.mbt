///|
fn render_client_nodes(
  nodes : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  node_counter : Array[Int],
) -> String {
  if nodes.length() == 1 {
    indent_block(
      render_client_node(nodes[0], indent, scope_id, node_counter, false),
      indent,
    )
  } else {
    let children = render_client_children(
      nodes, indent, scope_id, node_counter, false,
    )
    indent_block("@dom.frag(" + children + ")", indent)
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
  node_counter : Array[Int],
  static_mode : Bool,
) -> String {
  match node {
    Text(content) => "@dom.text(" + quote(content) + ")"
    Interpolation(expr) =>
      if static_mode {
        "@dom.text(" + expr + ".to_string())"
      } else {
        render_client_dynamic_text(expr, indent, node_counter)
      }
    Element(element) => {
      let next_static = static_mode || element.once
      let rendered = if element.is_component {
        render_client_component(
          element, indent, scope_id, node_counter, next_static,
        )
      } else {
        render_client_element(
          element, indent, scope_id, node_counter, next_static,
        )
      }
      wrap_client_directives(element, rendered)
    }
    Conditional(branches) =>
      render_client_conditional(
        branches, indent, scope_id, node_counter, static_mode,
      )
    Match(node) =>
      render_client_match(node, indent, scope_id, node_counter, static_mode)
  }
}

///|
fn render_client_match(
  node : MatchNode,
  indent : Int,
  scope_id : String?,
  node_counter : Array[Int],
  static_mode : Bool,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("match " + node.expr + " {\n")
  for branch in node.branches {
    let rendered = render_client_node(
      Element(branch.element),
      indent + 4,
      scope_id,
      node_counter,
      static_mode,
    )
    sb.write_string(spaces(indent + 2) + branch.pattern + " =>\n")
    sb.write_string(indent_block(rendered, indent + 4))
    sb.write_string("\n")
  }
  sb.write_string(spaces(indent) + "}")
  sb.to_string()
}

///|
fn render_client_conditional(
  branches : Array[ConditionalBranch],
  indent : Int,
  scope_id : String?,
  node_counter : Array[Int],
  static_mode : Bool,
) -> String {
  let sb = StringBuilder::new()
  for i, branch in branches {
    let rendered = render_client_node(
      Element(branch.element),
      indent + 2,
      scope_id,
      node_counter,
      static_mode,
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
  node_counter : Array[Int],
  static_mode : Bool,
) -> Array[String] {
  let statements : Array[String] = []
  for node in nodes {
    statements.push(
      "@dom.append(" +
      target_expr +
      ", " +
      render_client_node(node, indent + 2, scope_id, node_counter, static_mode) +
      ")",
    )
  }
  statements
}

///|
fn render_client_dynamic_text(
  expr : String,
  indent : Int,
  node_counter : Array[Int],
) -> String {
  let node_name = next_client_node_name(node_counter)
  let statements : Array[String] = [
    "let " + node_name + " = @dom.text(\"\")",
    "@dom.setText(" + node_name + ", fn() { " + expr + ".to_string() })",
    node_name,
  ]
  render_client_iife(statements, indent)
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
    Match(node) => render_server_match(node, indent, scope_id, static_mode)
  }
}

///|
fn render_server_match(
  node : MatchNode,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("match " + node.expr + " {\n")
  for branch in node.branches {
    let rendered = render_server_node(
      Element(branch.element),
      indent + 4,
      scope_id,
      static_mode,
    )
    sb.write_string(spaces(indent + 2) + branch.pattern + " =>\n")
    sb.write_string(indent_text(rendered, indent + 4))
    sb.write_string("\n")
  }
  sb.write_string(spaces(indent) + "}")
  sb.to_string()
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
      Element(branch.element),
      indent + 2,
      scope_id,
      static_mode,
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
      current = "@dom.show(fn() { " + expr + " }, fn() { " + current + " })"
    None => ()
  }
  match element.for_binding {
    Some(binding) => {
      let index_name = binding.index.unwrap_or("_index")
      current = "@dom.each(fn() { " +
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
