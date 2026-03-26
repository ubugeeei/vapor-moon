///|
fn render_client_component_props(
  element : TemplateElement,
  static_mode : Bool,
) -> String {
  let _ = static_mode
  let parts : Array[String] = []
  for attr in element.attrs {
    match attr.kind {
      Event => ()
      Static =>
        parts.push(
          "(\"" + attr.name + "\", fn() { " + quote(attr.value) + " })",
        )
      Boolean => parts.push("(\"" + attr.name + "\", fn() { \"true\" })")
      Dynamic =>
        parts.push(
          "(\"" + attr.name + "\", fn() { " + attr.value + ".to_string() })",
        )
    }
  }
  match element.model {
    Some(model) => {
      let prop_name = model.argument.unwrap_or("modelValue")
      parts.push(
        "(\"" + prop_name + "\", fn() { " + model.expression + ".to_string() })",
      )
    }
    None => ()
  }
  if parts.is_empty() {
    "[]"
  } else {
    "[" + parts.join(", ") + "]"
  }
}

///|
fn render_server_component_props(
  element : TemplateElement,
  static_mode : Bool,
) -> String {
  let parts : Array[String] = []
  for attr in element.attrs {
    match attr.kind {
      Event => ()
      Static => parts.push("(\"" + attr.name + "\", " + quote(attr.value) + ")")
      Boolean => parts.push("(\"" + attr.name + "\", \"true\")")
      Dynamic =>
        parts.push("(\"" + attr.name + "\", " + attr.value + ".to_string())")
    }
  }
  let _ = static_mode
  match element.model {
    Some(model) =>
      parts.push(
        "(\"" +
        model.argument.unwrap_or("modelValue") +
        "\", " +
        model.expression +
        ".to_string())",
      )
    None => ()
  }
  "@r.props_to_json(" +
  (if parts.is_empty() { "[]" } else { "[" + parts.join(", ") + "]" }) +
  ")"
}

///|
fn render_mode_expr(mode : IslandMode) -> String {
  match mode {
    None => "@r.HydrationMode::Manual"
    Load => "@r.HydrationMode::Load"
    Idle => "@r.HydrationMode::Idle"
    Visible => "@r.HydrationMode::Visible"
    Media(query) => "@r.HydrationMode::Media(" + quote(query) + ")"
    Only => "@r.HydrationMode::Only"
    ServerDefer => "@r.HydrationMode::ServerDefer"
  }
}
