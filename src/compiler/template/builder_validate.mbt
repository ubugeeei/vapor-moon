///|
fn validate_finalized_element(
  element : TemplateElement,
  children : Array[TemplateNode],
) -> Unit raise CompilerError {
  if is_void_html_tag(element.tag) {
    if not(children.is_empty()) {
      raise CompilerError::InvalidTemplate(
        "void element <\{element.tag}> cannot have children",
      )
    }
  }
  match element.html_expr {
    Some(_) if is_void_html_tag(element.tag) =>
      raise CompilerError::InvalidDirective(
        "v-html is not supported on void elements: <\{element.tag}>",
      )
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
  if attr.has_value && not(attr.value.trim().is_empty()) {
    return attr.value
  }
  raise CompilerError::InvalidDirective(
    "`\{attr.name}` requires a value on <\{tag}>",
  )
}

///|
fn reject_unexpected_attr_value(
  attr : ParsedTemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  if attr.has_value {
    raise CompilerError::InvalidDirective(
      "`\{attr.name}` does not take a value on <\{tag}>",
    )
  }
}

///|
fn validate_element_tag_form(
  tag : String,
  self_closing : Bool,
) -> Unit raise CompilerError {
  if is_void_html_tag(tag) && not(self_closing) {
    raise CompilerError::InvalidTemplate(
      "void element <\{tag}> must be self closing",
    )
  }
}

///|
fn validate_normalized_attr(
  raw_attr : ParsedTemplateAttr,
  attr : TemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  match attr.kind {
    Event => {
      if attr.name.trim().is_empty() {
        raise CompilerError::InvalidDirective(
          "event directive requires an event name on <\{tag}>",
        )
      }
      if has_dynamic_directive_argument(attr.name) {
        raise CompilerError::InvalidDirective(
          "dynamic event arguments are not supported on <\{tag}>: `\{raw_attr.name}`",
        )
      }
      if has_directive_modifier(attr.name) {
        raise CompilerError::InvalidDirective(
          "event modifiers are not supported on <\{tag}>: `\{raw_attr.name}`",
        )
      }
      if not(raw_attr.has_value) || raw_attr.value.trim().is_empty() {
        raise CompilerError::InvalidDirective(
          "`\{raw_attr.name}` requires an expression",
        )
      }
    }
    Dynamic => {
      if attr.name.trim().is_empty() {
        raise CompilerError::InvalidDirective(
          "binding directive requires an attribute name on <\{tag}>",
        )
      }
      if has_dynamic_directive_argument(attr.name) {
        raise CompilerError::InvalidDirective(
          "dynamic binding arguments are not supported on <\{tag}>: `\{raw_attr.name}`",
        )
      }
      if has_directive_modifier(attr.name) {
        raise CompilerError::InvalidDirective(
          "binding modifiers are not supported on <\{tag}>: `\{raw_attr.name}`",
        )
      }
    }
    _ => ()
  }
}

///|
fn validate_normalized_attr_conflict(
  attrs : Array[TemplateAttr],
  attr : TemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  match attr.kind {
    Event =>
      if has_attr_with_kind(attrs, attr.name, Event) {
        raise CompilerError::InvalidDirective(
          "duplicate event listener `\{attr.name}` on <\{tag}>",
        )
      }
    _ =>
      if not(is_mergeable_attr_name(attr.name)) &&
        has_non_event_attr(attrs, attr.name) {
        raise CompilerError::InvalidDirective(
          "duplicate attribute `\{attr.name}` on <\{tag}>",
        )
      }
  }
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
fn validate_native_model_binding(
  tag : String,
  attrs : Array[TemplateAttr],
  model : TemplateModel,
) -> Unit raise CompilerError {
  match model.argument {
    Some(argument) =>
      raise CompilerError::InvalidDirective(
        "native v-model arguments are not supported on <\{tag}>: `\{argument}`",
      )
    None => ()
  }
  for modifier in model.modifiers {
    if modifier != "trim" && modifier != "lazy" {
      raise CompilerError::InvalidDirective(
        "unsupported v-model modifier `.\{modifier}` on <\{tag}>",
      )
    }
  }
  if tag == "input" {
    if has_dynamic_attr(attrs, "type") {
      raise CompilerError::InvalidDirective(
        "dynamic input `type` is not supported with v-model on <input>",
      )
    }
    match find_static_attr_value(attrs, "type") {
      Some("radio") =>
        raise CompilerError::InvalidDirective(
          "v-model on <input type=\"radio\"> is not supported yet",
        )
      Some("file") =>
        raise CompilerError::InvalidDirective(
          "v-model on <input type=\"file\"> is not supported yet",
        )
      Some("checkbox") =>
        if has_model_modifier_name(model, "trim") {
          raise CompilerError::InvalidDirective(
            "unsupported v-model modifier `.trim` on <input type=\"checkbox\">",
          )
        }
      _ => ()
    }
  }
  if tag == "select" {
    if has_attr(attrs, "multiple") {
      raise CompilerError::InvalidDirective(
        "v-model on <select multiple> is not supported yet",
      )
    }
    if has_model_modifier_name(model, "trim") {
      raise CompilerError::InvalidDirective(
        "unsupported v-model modifier `.trim` on <select>",
      )
    }
  }
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
fn reject_unknown_directive(
  attr : ParsedTemplateAttr,
  tag : String,
) -> Unit raise CompilerError {
  if is_supported_directive_name(attr.name) {
    return
  }
  if attr.name.has_prefix("v-") {
    raise CompilerError::InvalidDirective(
      "unsupported directive on <\{tag}>: `\{attr.name}`",
    )
  }
  if attr.name.has_prefix("client:") || attr.name.has_prefix("server:") {
    raise CompilerError::InvalidDirective(
      "unsupported island directive on <\{tag}>: `\{attr.name}`",
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
  show_expr : String?,
  html_expr : String?,
) -> Unit raise CompilerError {
  match island_directive {
    Some(_) if not(is_component) =>
      raise CompilerError::InvalidDirective(
        "island directives can only be used on component tags: <\{tag}>",
      )
    _ => ()
  }
  if not(is_component) {
    match html_expr {
      Some(_) if is_void_html_tag(tag) =>
        raise CompilerError::InvalidDirective(
          "v-html is not supported on void elements: <\{tag}>",
        )
      _ => ()
    }
    match model {
      Some(binding) => validate_native_model_binding(tag, attrs, binding)
      None => ()
    }
    return
  }
  match show_expr {
    Some(_) =>
      raise CompilerError::InvalidDirective(
        "v-show is not supported on component tags: <\{tag}>",
      )
    None => ()
  }
  for attr in attrs {
    if attr.kind == Event {
      raise CompilerError::InvalidDirective(
        "component event listeners are not supported yet on <\{tag}>",
      )
    }
  }
  match html_expr {
    Some(_) =>
      raise CompilerError::InvalidDirective(
        "v-html is not supported on component tags: <\{tag}>",
      )
    None => ()
  }
  match model {
    Some(_) =>
      raise CompilerError::InvalidDirective(
        "component v-model is not supported yet on <\{tag}>",
      )
    None => ()
  }
}

///|
fn has_model_modifier_name(model : TemplateModel, expected : String) -> Bool {
  for modifier in model.modifiers {
    if modifier == expected {
      return true
    }
  }
  false
}

///|
fn has_attr(attrs : Array[TemplateAttr], name : String) -> Bool {
  for attr in attrs {
    if attr.name == name {
      return true
    }
  }
  false
}

///|
fn has_dynamic_attr(attrs : Array[TemplateAttr], name : String) -> Bool {
  for attr in attrs {
    if attr.name == name && attr.kind == Dynamic {
      return true
    }
  }
  false
}

///|
fn has_attr_with_kind(
  attrs : Array[TemplateAttr],
  name : String,
  kind : TemplateAttrKind,
) -> Bool {
  for attr in attrs {
    if attr.name == name && attr.kind == kind {
      return true
    }
  }
  false
}

///|
fn has_non_event_attr(attrs : Array[TemplateAttr], name : String) -> Bool {
  for attr in attrs {
    if attr.name == name && attr.kind != Event {
      return true
    }
  }
  false
}

///|
fn find_static_attr_value(
  attrs : Array[TemplateAttr],
  name : String,
) -> String? {
  for attr in attrs {
    if attr.name != name {
      continue
    }
    match attr.kind {
      Static => return Some(attr.value)
      Boolean => return Some("")
      _ => ()
    }
  }
  None
}

///|
fn has_dynamic_directive_argument(name : String) -> Bool {
  name.contains("[") || name.contains("]")
}

///|
fn has_directive_modifier(name : String) -> Bool {
  name.contains(".")
}

///|
fn is_supported_directive_name(name : String) -> Bool {
  name == "v-if" ||
  name == "v-else" ||
  name == "v-else-if" ||
  name == "v-match" ||
  name == "v-case" ||
  name == "v-case.default" ||
  name == "v-for" ||
  name == "v-show" ||
  name == "v-html" ||
  name == "v-once" ||
  name == "key" ||
  name == "ref" ||
  name == ":key" ||
  name == "v-bind:key" ||
  name == ":ref" ||
  name == "v-bind:ref" ||
  name == "client:load" ||
  name == "client:idle" ||
  name == "client:visible" ||
  name == "client:none" ||
  name == "client:only" ||
  name == "client:media" ||
  name == "server:defer" ||
  name.has_prefix(":") ||
  name.has_prefix("@") ||
  name.has_prefix("v-bind:") ||
  name.has_prefix("v-on:") ||
  name.has_prefix("v-model")
}

///|
fn is_mergeable_attr_name(name : String) -> Bool {
  name == "class" || name == "className" || name == "style"
}

///|
fn is_void_html_tag(tag : String) -> Bool {
  tag == "area" ||
  tag == "base" ||
  tag == "br" ||
  tag == "col" ||
  tag == "embed" ||
  tag == "hr" ||
  tag == "img" ||
  tag == "input" ||
  tag == "link" ||
  tag == "meta" ||
  tag == "param" ||
  tag == "source" ||
  tag == "track" ||
  tag == "wbr"
}
