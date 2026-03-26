///|
fn render_client_key_attr(element : TemplateElement) -> String? {
  match element.key_expr {
    Some(expr) =>
      Some("(\"data-vm-key\", @dom.dynAttr(fn() { " + expr + ".to_string() }))")
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
  match element.ref_binding_name {
    Some(binding_name) =>
      Some(
        "(\"__ref\", @dom.on(fn(target) { @dom.bindRef(" +
        binding_name +
        ", target) }))",
      )
    None =>
      match element.ref_name {
        Some(expr) =>
          Some(
            "(\"__ref\", @dom.on(fn(target) { @dom.bindRefName(" +
            expr +
            ", target) }))",
          )
        None => None
      }
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
        Some("(\"__innerHTML\", @dom.attr(" + expr + ".to_string()))")
      } else {
        Some("(\"__innerHTML\", @dom.dynAttr(fn() { " + expr + ".to_string() }))")
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
      let event_name = render_model_event_name(element, model, checked)
      let value_expr = if checked {
        "if " + model.expression + " { \"true\" } else { \"false\" }"
      } else {
        model.expression + ".to_string()"
      }
      let attr_name = if checked { "checked" } else { "value" }
      if static_mode {
        parts.push("(\"" + attr_name + "\", @dom.attr(" + value_expr + "))")
      } else {
        parts.push(
          "(\"" + attr_name + "\", @dom.dynAttr(fn() { " + value_expr + " }))",
        )
      }
      parts.push(
        "(\"" +
        event_name +
        "\", @dom.on(fn(_event) { " +
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
fn render_model_event_name(
  element : TemplateElement,
  model : TemplateModel,
  checked : Bool,
) -> String {
  if element.tag == "select" || checked || has_model_modifier(model, "lazy") {
    "change"
  } else {
    "input"
  }
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
  match signal_getter_receiver(target) {
    Some(receiver) => receiver + ".set(" + value_expr + ")"
    None => target + " = " + value_expr
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

///|
fn signal_getter_receiver(target : String) -> String? {
  let wrapped = "let __vm_probe = " + target
  let (impls, reports) = @mbt_parser.parse_string(
    wrapped,
    name="__vm_model_target__.mbt",
  )
  if not(reports.is_empty()) {
    return None
  }
  for impl_ in impls {
    match impl_ {
      TopLetDef(expr~, ..) =>
        return signal_getter_receiver_from_expr(expr, wrapped)
      _ => ()
    }
  }
  None
}

///|
fn signal_getter_receiver_from_expr(
  expr : @mbt_syntax.Expr,
  source : String,
) -> String? {
  let expr = unwrap_group_expr_model(expr)
  match expr {
    Apply(func~, args~, ..) =>
      getter_receiver_from_apply_model(func, args, source)
    DotApply(self~, method_name~, args~, ..) =>
      if method_name.name == "get" && argument_list_is_empty_model(args) {
        Some(slice_location_model(source, self.loc()).trim().to_string())
      } else {
        None
      }
    _ => None
  }
}

///|
fn getter_receiver_from_apply_model(
  func : @mbt_syntax.Expr,
  args : @list.List[@mbt_syntax.Argument],
  source : String,
) -> String? {
  if not(argument_list_is_empty_model(args)) {
    return None
  }
  let func = unwrap_group_expr_model(func)
  match func {
    Field(record~, accessor~, ..) =>
      if accessor_label_name_model(accessor) == Some("get") {
        Some(slice_location_model(source, record.loc()).trim().to_string())
      } else {
        None
      }
    _ => None
  }
}

///|
fn unwrap_group_expr_model(expr : @mbt_syntax.Expr) -> @mbt_syntax.Expr {
  match expr {
    Group(expr~, ..) => unwrap_group_expr_model(expr)
    _ => expr
  }
}

///|
fn accessor_label_name_model(accessor : @mbt_syntax.Accessor) -> String? {
  match accessor {
    Label(label) => Some(label.name)
    Index(..) | Newtype(..) => None
  }
}

///|
fn argument_list_is_empty_model(
  args : @list.List[@mbt_syntax.Argument],
) -> Bool {
  match args {
    @list.Empty => true
    @list.More(_, ..) => false
  }
}

///|
fn slice_location_model(source : String, loc : @mbt_basic.Location) -> String {
  String::unsafe_substring(source, start=loc.start.cnum, end=loc.end.cnum)
}
