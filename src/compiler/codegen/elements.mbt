///|
fn render_client_element(
  element : TemplateElement,
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let statements : Array[String] = [
    "let __vm_el = @dom.el(" + quote(element.tag) + ")",
  ]
  for attr in collect_client_attr_entries(element, scope_id, static_mode) {
    statements.push("@dom.setAttr(__vm_el, " + attr + ")")
  }
  if element.html_expr is None && not(element.children.is_empty()) {
    for
      statement in render_client_append_statements(
        "__vm_el.as_node()",
        element.children,
        indent + 4,
        scope_id,
        static_mode,
      ) {
      statements.push(statement)
    }
  }
  statements.push("@dom.into(__vm_el)")
  render_client_iife(statements, indent)
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
  let meta_attrs = render_client_component_meta_attrs(element)
  let children = if has_named_slots(element.children) {
    render_client_slots_record(element.children, indent + 2, scope_id, static_mode)
  } else {
    render_client_children(element.children, indent + 2, scope_id, static_mode)
  }
  match element.island_mode {
    Load | Idle | Visible | Media(_) | Only | ServerDefer =>
      if meta_attrs == "[]" {
        "@dom.island(" +
        quote(element.tag) +
        ", " +
        render_mode_expr(element.island_mode) +
        ", " +
        props +
        ", " +
        children +
        ")"
      } else {
        "@dom.islandMeta(" +
        quote(element.tag) +
        ", " +
        render_mode_expr(element.island_mode) +
        ", " +
        props +
        ", " +
        children +
        ", " +
        meta_attrs +
        ")"
      }
    None =>
      if meta_attrs == "[]" {
        "@dom.component(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ")"
      } else {
        "@dom.componentMeta(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ", " +
        meta_attrs +
        ")"
      }
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
  let meta_attrs = render_server_component_meta_attrs(element)
  let children = if has_named_slots(element.children) {
    render_server_slots_record(element.children, indent + 2, scope_id, static_mode)
  } else {
    render_server_children(element.children, indent + 2, scope_id, static_mode)
  }
  match element.island_mode {
    Load | Idle | Visible | Media(_) | Only | ServerDefer =>
      if meta_attrs == "[]" {
        "@vm_server.island_ssr(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ", " +
        render_mode_expr(element.island_mode) +
        ")"
      } else {
        "@vm_server.island_ssr_meta(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ", " +
        render_mode_expr(element.island_mode) +
        ", " +
        meta_attrs +
        ")"
      }
    None =>
      if meta_attrs == "[]" {
        "@vm_server.component_ssr(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ")"
      } else {
        "@vm_server.component_ssr_meta(" +
        quote(element.tag) +
        ", " +
        props +
        ", " +
        children +
        ", " +
        meta_attrs +
        ")"
      }
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
      indent_block(
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
fn render_client_iife(statements : Array[String], indent : Int) -> String {
  let lines : Array[String] = []
  for statement in statements {
    lines.push(indent_block(statement, indent + 2))
  }
  "(fn() {\n" + lines.join("\n") + "\n" + spaces(indent) + "})()"
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
          if not(local_string_array_contains(result, element.tag)) {
            result.push(element.tag)
          }
        None => ()
      }
      for child in element.children {
        collect_node_islands(child, result)
      }
    }
    Conditional(branches) =>
      for branch in branches {
        collect_node_islands(Element(branch.element), result)
      }
    Match(node) =>
      for branch in node.branches {
        collect_node_islands(Element(branch.element), result)
      }
    _ => ()
  }
}

///|
fn has_named_slots(children : Array[TemplateNode]) -> Bool {
  for child in children {
    match child {
      Element(element) if element.slot_name is Some(_) => return true
      _ => ()
    }
  }
  false
}

///|
priv struct SlotGroup {
  name : String
  nodes : Array[TemplateNode]
}

///|
fn group_children_by_slot(children : Array[TemplateNode]) -> Array[SlotGroup] {
  let groups : Array[SlotGroup] = []
  let default_nodes : Array[TemplateNode] = []
  for child in children {
    match child {
      Element(element) =>
        match element.slot_name {
          Some(name) => {
            let mut found = false
            for group in groups {
              if group.name == name {
                for inner in element.children {
                  group.nodes.push(inner)
                }
                found = true
                break
              }
            }
            if not(found) {
              let nodes : Array[TemplateNode] = []
              for inner in element.children {
                nodes.push(inner)
              }
              groups.push({ name, nodes })
            }
          }
          None => default_nodes.push(child)
        }
      _ => default_nodes.push(child)
    }
  }
  if not(default_nodes.is_empty()) {
    let mut has_default = false
    for group in groups {
      if group.name == "default" {
        for node in default_nodes {
          group.nodes.push(node)
        }
        has_default = true
        break
      }
    }
    if not(has_default) {
      groups.push({ name: "default", nodes: default_nodes })
    }
  }
  groups
}

///|
fn render_client_slots_record(
  children : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let groups = group_children_by_slot(children)
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  for i, group in groups {
    sb.write_string(spaces(indent + 2))
    sb.write_string(group.name)
    sb.write_string(": Some(fn() { ")
    sb.write_string(
      render_client_children(group.nodes, indent + 4, scope_id, static_mode),
    )
    sb.write_string(" })")
    if i < groups.length() - 1 {
      sb.write_string(",")
    }
    sb.write_string("\n")
  }
  sb.write_string(spaces(indent) + "}")
  sb.to_string()
}

///|
fn render_server_slots_record(
  children : Array[TemplateNode],
  indent : Int,
  scope_id : String?,
  static_mode : Bool,
) -> String {
  let groups = group_children_by_slot(children)
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  for i, group in groups {
    sb.write_string(spaces(indent + 2))
    sb.write_string(group.name)
    sb.write_string(": Some(fn() { ")
    sb.write_string(
      render_server_children(group.nodes, indent + 4, scope_id, static_mode),
    )
    sb.write_string(" })")
    if i < groups.length() - 1 {
      sb.write_string(",")
    }
    sb.write_string("\n")
  }
  sb.write_string(spaces(indent) + "}")
  sb.to_string()
}

///|
fn local_string_array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
