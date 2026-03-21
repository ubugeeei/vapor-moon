///|
fn validate_finalized_element(
  element : TemplateElement,
  children : Array[TemplateNode],
) -> Unit raise CompilerError {
  match element.html_expr {
    Some(_) if not(children.is_empty()) =>
      raise CompilerError::InvalidDirective(
        "v-html cannot be combined with child nodes on <\{element.tag}>",
      )
    _ => ()
  }
}

///|
fn ensure_empty_expr_directive(
  existing : String?,
  attr : ParsedTemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  match existing {
    Some(_) =>
      raise CompilerError::InvalidDirective(
        "duplicate `\{attr.name}` on <\{tag}>",
      )
    None => ()
  }
}

///|
fn expect_attr_value(
  attr : ParsedTemplateAttr,
  tag : String,
) -> String raise CompilerError {
  if attr.has_value && attr.value.trim().length() > 0 {
    return attr.value
  }
  raise CompilerError::InvalidDirective(
    "`\{attr.name}` requires a value on <\{tag}>",
  )
}

///|
fn register_island_mode(
  previous : String?,
  attr : ParsedTemplateAttr,
  tag : String,
  next : IslandMode,
) -> IslandMode raise CompilerError {
  match previous {
    Some(name) =>
      raise CompilerError::InvalidDirective(
        "multiple island directives are not allowed on <\{tag}>: `\{name}` and `\{attr.name}`",
      )
    None => next
  }
}

///|
fn validate_model_target(
  tag : String,
  is_component : Bool,
) -> Unit raise CompilerError {
  if tag == "input" || tag == "textarea" || tag == "select" {
    return
  }
  if is_component {
    return
  }
  raise CompilerError::InvalidDirective(
    "v-model is only supported on form controls or component tags: <\{tag}>",
  )
}

///|
fn occupied_directive_value(target : String?) -> String? {
  match target {
    Some(_) => Some("used")
    None => None
  }
}

///|
fn reject_unsupported_slot_outlet(
  attr : ParsedTemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  if attr.name == "v-slot" ||
    attr.name.has_prefix("v-slot:") ||
    attr.name.has_prefix("#") {
    raise CompilerError::InvalidDirective(
      "slot outlet syntax is not supported yet on <\{tag}>",
    )
  }
}

///|
fn validate_component_bindings(
  tag : String,
  is_component : Bool,
  attrs : Array[TemplateAttr],
  model : TemplateModel?,
  island_directive : String?,
) -> Unit raise CompilerError {
  match island_directive {
    Some(_) if not(is_component) =>
      raise CompilerError::InvalidDirective(
        "island directives can only be used on component tags: <\{tag}>",
      )
    _ => ()
  }
  if not(is_component) {
    return
  }
  for attr in attrs {
    if attr.kind == Event {
      raise CompilerError::InvalidDirective(
        "component event listeners are not supported yet on <\{tag}>",
      )
    }
  }
  match model {
    Some(_) =>
      raise CompilerError::InvalidDirective(
        "component v-model is not supported yet on <\{tag}>",
      )
    None => ()
  }
}
