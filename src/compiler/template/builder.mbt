///|
fn on_start_tag(
  tag : ParsedTemplateTag,
  roots : Array[TemplateNode],
  stack : Array[TemplateFrame],
) -> Unit raise CompilerError {
  let element = build_template_element(tag.name, tag.attrs, tag.self_closing)
  if tag.self_closing {
    append_node(Element(element), roots, stack)
  } else {
    stack.push({ element, children: [] })
  }
}

///|
fn on_end_tag(
  name : String,
  roots : Array[TemplateNode],
  stack : Array[TemplateFrame],
) -> Unit raise CompilerError {
  if stack.is_empty() {
    raise CompilerError::InvalidTemplate("unexpected closing tag </\{name}>")
  }
  let last_index = stack.length() - 1
  let frame = stack[last_index]
  stack.unsafe_pop_back()
  if frame.element.tag != name {
    raise CompilerError::InvalidTemplate(
      "expected </\{frame.element.tag}>, got </\{name}>",
    )
  }
  append_node(
    Element({ ..frame.element, children: frame.children }),
    roots,
    stack,
  )
}

///|
fn build_template_element(
  tag : String,
  attrs : Array[ParsedTemplateAttr],
  self_closing : Bool,
) -> TemplateElement raise CompilerError {
  let is_component = is_component_name(tag)
  let mut if_expr : String? = None
  let mut for_binding : ForBinding? = None
  let mut island_mode = IslandMode::None
  let mut show_expr : String? = None
  let mut html_expr : String? = None
  let mut model : TemplateModel? = None
  let mut key_expr : String? = None
  let mut ref_name : String? = None
  let mut once = false
  let final_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    match attr.name {
      "v-if" => if_expr = Some(attr.value)
      "v-for" => for_binding = Some(parse_for_binding(attr.value))
      "client:load" => island_mode = IslandMode::Load
      "client:idle" => island_mode = IslandMode::Idle
      "client:visible" => island_mode = IslandMode::Visible
      "client:none" => island_mode = IslandMode::None
      "client:only" => island_mode = IslandMode::Only
      "server:defer" => island_mode = IslandMode::ServerDefer
      "client:media" => island_mode = IslandMode::Media(attr.value)
      "v-show" => show_expr = Some(attr.value)
      "v-html" => html_expr = Some(attr.value)
      "v-once" => once = true
      "key" =>
        key_expr = Some(
          if attr.has_value {
            quote_template_literal(attr.value)
          } else {
            "\"true\""
          },
        )
      ":key" | "v-bind:key" => key_expr = Some(attr.value)
      "ref" =>
        if attr.has_value {
          ref_name = Some(quote_template_literal(attr.value))
        }
      ":ref" | "v-bind:ref" => ref_name = Some(attr.value)
      _ =>
        match parse_model_attr(attr) {
          Some(binding) => model = Some(binding)
          None => final_attrs.push(classify_template_attr(attr))
        }
    }
  }
  if island_mode != IslandMode::None && not(is_component) {
    raise CompilerError::InvalidDirective(
      "island directives can only be used on component tags: <\{tag}>",
    )
  }
  {
    tag,
    attrs: final_attrs,
    children: [],
    is_component,
    is_self_closing: self_closing,
    if_expr,
    for_binding,
    island_mode,
    show_expr,
    html_expr,
    model,
    key_expr,
    ref_name,
    once,
  }
}

///|
fn append_node(
  node : TemplateNode,
  roots : Array[TemplateNode],
  stack : Array[TemplateFrame],
) -> Unit {
  if stack.is_empty() {
    roots.push(node)
  } else {
    let last_index = stack.length() - 1
    stack[last_index].children.push(node)
  }
}

///|
fn classify_template_attr(attr : ParsedTemplateAttr) -> TemplateAttr {
  if attr.name.has_prefix(":") {
    {
      kind: Dynamic,
      name: String::unsafe_substring(attr.name, start=1, end=attr.name.length()),
      value: if attr.has_value {
        attr.value
      } else {
        String::unsafe_substring(attr.name, start=1, end=attr.name.length())
      },
    }
  } else if attr.name.has_prefix("v-bind:") {
    {
      kind: Dynamic,
      name: String::unsafe_substring(attr.name, start=7, end=attr.name.length()),
      value: if attr.has_value {
        attr.value
      } else {
        String::unsafe_substring(attr.name, start=7, end=attr.name.length())
      },
    }
  } else if attr.name.has_prefix("@") {
    {
      kind: Event,
      name: String::unsafe_substring(attr.name, start=1, end=attr.name.length()),
      value: attr.value,
    }
  } else if attr.name.has_prefix("v-on:") {
    {
      kind: Event,
      name: String::unsafe_substring(attr.name, start=5, end=attr.name.length()),
      value: attr.value,
    }
  } else if attr.has_value {
    { kind: Static, name: attr.name, value: attr.value }
  } else {
    { kind: Boolean, name: attr.name, value: "true" }
  }
}

///|
fn parse_model_attr(attr : ParsedTemplateAttr) -> TemplateModel? {
  if not(attr.name.has_prefix("v-model")) {
    return None
  }
  let suffix = String::unsafe_substring(
    attr.name,
    start=7,
    end=attr.name.length(),
  )
  let mut argument : String? = None
  let modifiers : Array[String] = []
  if suffix.length() > 0 {
    let segments = suffix
      .split(".")
      .map(fn(part) { part.to_string() })
      .collect()
    if segments.length() > 0 && segments[0].has_prefix(":") {
      let arg = String::unsafe_substring(
        segments[0],
        start=1,
        end=segments[0].length(),
      )
      if arg.length() > 0 {
        argument = Some(arg)
      }
    }
    for index in 0..<segments.length() {
      if index == 0 && segments[index].has_prefix(":") {
        continue
      }
      if segments[index].length() > 0 {
        modifiers.push(segments[index])
      }
    }
  }
  Some({ argument, expression: attr.value, modifiers })
}

///|
fn quote_template_literal(source : String) -> String {
  let sb = StringBuilder::new()
  sb.write_char('"')
  for ch in source {
    match ch {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(ch)
    }
  }
  sb.write_char('"')
  sb.to_string()
}
