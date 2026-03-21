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
  validate_finalized_element(frame.element, frame.children)
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
  let mut island_directive : String? = None
  let final_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    reject_unsupported_slot_outlet(attr, tag)
    match attr.name {
      "v-if" => {
        ensure_empty_expr_directive(if_expr, attr, tag)
        if_expr = Some(expect_attr_value(attr, tag))
      }
      "v-for" => {
        ensure_empty_expr_directive(
          occupied_directive_value(for_binding.map(fn(_) { "used" })),
          attr,
          tag,
        )
        for_binding = Some(parse_for_binding(expect_attr_value(attr, tag)))
      }
      "client:load" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Load,
        )
        island_directive = Some(attr.name)
      }
      "client:idle" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Idle,
        )
        island_directive = Some(attr.name)
      }
      "client:visible" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Visible,
        )
        island_directive = Some(attr.name)
      }
      "client:none" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::None,
        )
        island_directive = Some(attr.name)
      }
      "client:only" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Only,
        )
        island_directive = Some(attr.name)
      }
      "server:defer" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::ServerDefer,
        )
        island_directive = Some(attr.name)
      }
      "client:media" => {
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Media(expect_attr_value(attr, tag)),
        )
        island_directive = Some(attr.name)
      }
      "v-show" => {
        ensure_empty_expr_directive(show_expr, attr, tag)
        show_expr = Some(expect_attr_value(attr, tag))
      }
      "v-html" => {
        ensure_empty_expr_directive(html_expr, attr, tag)
        html_expr = Some(expect_attr_value(attr, tag))
      }
      "v-once" => once = true
      "key" => {
        ensure_empty_expr_directive(key_expr, attr, tag)
        key_expr = Some(quote_template_literal(expect_attr_value(attr, tag)))
      }
      ":key" | "v-bind:key" => {
        ensure_empty_expr_directive(key_expr, attr, tag)
        key_expr = Some(expect_attr_value(attr, tag))
      }
      "ref" => {
        ensure_empty_expr_directive(ref_name, attr, tag)
        ref_name = Some(quote_template_literal(expect_attr_value(attr, tag)))
      }
      ":ref" | "v-bind:ref" => {
        ensure_empty_expr_directive(ref_name, attr, tag)
        ref_name = Some(expect_attr_value(attr, tag))
      }
      _ =>
        match parse_model_attr(attr) {
          Some(binding) => {
            ensure_empty_expr_directive(
              occupied_directive_value(model.map(fn(_) { "used" })),
              attr,
              tag,
            )
            validate_model_target(tag, is_component)
            model = Some(binding)
          }
          None => {
            let normalized = classify_template_attr(attr)
            validate_normalized_attr(attr, normalized, tag)
            final_attrs.push(normalized)
          }
        }
    }
  }
  validate_component_bindings(
    tag, is_component, final_attrs, model, island_directive,
  )
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
