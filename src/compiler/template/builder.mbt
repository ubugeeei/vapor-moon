///|
fn visitor_on_text(
  visitor : TemplateTokenVisitor,
  source : String,
  start : Int,
  end_ : Int,
  has_content : Bool,
) -> Unit raise CompilerError {
  if not(has_content) {
    return
  }
  append_node(
    Text(String::unsafe_substring(source, start~, end=end_)),
    visitor.roots,
    visitor.stack,
  )
}

///|
fn visitor_on_interpolation(
  visitor : TemplateTokenVisitor,
  expr : String,
) -> Unit raise CompilerError {
  append_node(Interpolation(expr), visitor.roots, visitor.stack)
}

///|
fn visitor_on_start_tag(
  visitor : TemplateTokenVisitor,
  tag : String,
  attrs : Array[ParsedTemplateAttr],
  self_closing : Bool,
) -> Unit raise CompilerError {
  on_start_tag({ name: tag, attrs, self_closing }, visitor.roots, visitor.stack)
}

///|
fn visitor_on_end_tag(
  visitor : TemplateTokenVisitor,
  name : String,
) -> Unit raise CompilerError {
  on_end_tag(name, visitor.roots, visitor.stack)
}

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
  match frame.element.match_expr {
    Some(expr) => {
      let match_node = build_match_node(expr, frame.children, frame.element.tag)
      append_node(Match(match_node), roots, stack)
    }
    None =>
      append_node(
        Element({ ..frame.element, children: frame.children }),
        roots,
        stack,
      )
  }
}

///|
fn build_template_element(
  tag : String,
  attrs : Array[ParsedTemplateAttr],
  self_closing : Bool,
) -> TemplateElement raise CompilerError {
  validate_element_tag_form(tag, self_closing)
  let is_component = is_component_name(tag)
  let mut if_expr : String? = None
  let mut else_if_expr : String? = None
  let mut is_else = false
  let mut for_binding : ForBinding? = None
  let mut island_mode = IslandMode::None
  let mut show_expr : String? = None
  let mut html_expr : String? = None
  let mut model : TemplateModel? = None
  let mut key_expr : String? = None
  let mut ref_name : String? = None
  let mut ref_static_name : String? = None
  let mut once = false
  let mut match_expr : String? = None
  let mut case_pattern : String? = None
  let mut is_case_default = false
  let mut slot_name : String? = None
  let mut island_directive : String? = None
  let final_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    reject_unsupported_slot_outlet(attr, tag)
    reject_unknown_directive(attr, tag)
    match attr.name {
      "v-if" => {
        ensure_empty_expr_directive(if_expr, attr, tag)
        if_expr = Some(expect_attr_value(attr, tag))
      }
      "v-else-if" => {
        ensure_empty_expr_directive(else_if_expr, attr, tag)
        else_if_expr = Some(expect_attr_value(attr, tag))
      }
      "v-else" => {
        reject_unexpected_attr_value(attr, tag)
        if is_else {
          raise CompilerError::InvalidDirective(
            "duplicate `v-else` on <\{tag}>",
          )
        }
        is_else = true
      }
      "v-match" => {
        ensure_empty_expr_directive(match_expr, attr, tag)
        match_expr = Some(expect_attr_value(attr, tag))
      }
      "v-case" => {
        if is_case_default {
          raise CompilerError::InvalidDirective(
            "`v-case` cannot be combined with `v-default` on <\{tag}>",
          )
        }
        ensure_empty_expr_directive(case_pattern, attr, tag)
        if attr.has_value {
          let value = attr.value.trim().to_string()
          if value == "_" {
            is_case_default = true
          } else {
            case_pattern = Some(value)
          }
        } else {
          raise CompilerError::InvalidDirective(
            "`v-case` requires a pattern value on <\{tag}>; use `v-default` for the fallback branch",
          )
        }
      }
      "v-default" => {
        reject_unexpected_attr_value(attr, tag)
        if case_pattern is Some(_) {
          raise CompilerError::InvalidDirective(
            "`v-default` cannot be combined with `v-case` on <\{tag}>",
          )
        }
        if is_case_default {
          raise CompilerError::InvalidDirective(
            "duplicate `v-default` on <\{tag}>",
          )
        }
        is_case_default = true
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
        reject_unexpected_attr_value(attr, tag)
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Load,
        )
        island_directive = Some(attr.name)
      }
      "client:idle" => {
        reject_unexpected_attr_value(attr, tag)
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Idle,
        )
        island_directive = Some(attr.name)
      }
      "client:visible" => {
        reject_unexpected_attr_value(attr, tag)
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Visible,
        )
        island_directive = Some(attr.name)
      }
      "client:none" => {
        reject_unexpected_attr_value(attr, tag)
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::None,
        )
        island_directive = Some(attr.name)
      }
      "client:only" => {
        reject_unexpected_attr_value(attr, tag)
        island_mode = register_island_mode(
          island_directive,
          attr,
          tag,
          IslandMode::Only,
        )
        island_directive = Some(attr.name)
      }
      "server:defer" => {
        reject_unexpected_attr_value(attr, tag)
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
      "v-unsafe-html" => {
        ensure_empty_expr_directive(html_expr, attr, tag)
        html_expr = Some(expect_attr_value(attr, tag))
      }
      "v-once" => {
        reject_unexpected_attr_value(attr, tag)
        if once {
          raise CompilerError::InvalidDirective(
            "duplicate `v-once` on <\{tag}>",
          )
        }
        once = true
      }
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
        let value = expect_attr_value(attr, tag)
        ref_name = Some(quote_template_literal(value))
        ref_static_name = Some(value)
      }
      ":ref" | "v-bind:ref" => {
        ensure_empty_expr_directive(ref_name, attr, tag)
        ref_name = Some(expect_attr_value(attr, tag))
        ref_static_name = None
      }
      _ if attr.name == "v-slot" => {
        ensure_empty_expr_directive(slot_name, attr, tag)
        slot_name = Some("default")
      }
      _ if attr.name.has_prefix("v-slot:") => {
        ensure_empty_expr_directive(slot_name, attr, tag)
        slot_name = Some(
          String::unsafe_substring(attr.name, start=7, end=attr.name.length()),
        )
      }
      _ if attr.name.has_prefix("#") => {
        ensure_empty_expr_directive(slot_name, attr, tag)
        let name = String::unsafe_substring(
          attr.name, start=1, end=attr.name.length(),
        )
        slot_name = Some(if name == "default" || name.length() == 0 {
          "default"
        } else {
          name
        })
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
            validate_normalized_attr_conflict(final_attrs, normalized, tag)
            final_attrs.push(normalized)
          }
        }
    }
  }
  validate_component_bindings(
    tag, is_component, final_attrs, model, island_directive, show_expr, html_expr,
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
    ref_static_name,
    ref_binding_name: None,
    once,
    else_if_expr,
    is_else,
    match_expr,
    case_pattern,
    is_case_default,
    slot_name,
  }
}

///|
fn append_node(
  node : TemplateNode,
  roots : Array[TemplateNode],
  stack : Array[TemplateFrame],
) -> Unit raise CompilerError {
  let target = if stack.is_empty() {
    roots
  } else {
    stack[stack.length() - 1].children
  }
  let parent_has_match = if stack.is_empty() {
    false
  } else {
    stack[stack.length() - 1].element.match_expr is Some(_)
  }
  match node {
    Element(element) =>
      if element.else_if_expr is Some(_) || element.is_else {
        append_conditional_branch(target, element)
      } else if (element.case_pattern is Some(_) || element.is_case_default) &&
        not(parent_has_match) {
        raise CompilerError::InvalidDirective(
          "`v-case` must be a direct child of a `v-match` element on <" +
          element.tag +
          ">",
        )
      } else {
        target.push(node)
      }
    _ => target.push(node)
  }
}

///|
fn append_conditional_branch(
  siblings : Array[TemplateNode],
  element : TemplateElement,
) -> Unit raise CompilerError {
  let tag = element.tag
  let branch : ConditionalBranch = {
    condition: element.else_if_expr,
    element: { ..element, else_if_expr: None, is_else: false },
  }
  if siblings.is_empty() {
    raise CompilerError::InvalidDirective(
      "`\{conditional_directive_name(element)}` requires a preceding `v-if` on <\{tag}>",
    )
  }
  let last_index = siblings.length() - 1
  match siblings[last_index] {
    Conditional(branches) => {
      validate_conditional_chain(branches, element, tag)
      branches.push(branch)
    }
    Element(prev) if prev.if_expr is Some(condition) => {
      let first_branch : ConditionalBranch = {
        condition: Some(condition),
        element: { ..prev, if_expr: None },
      }
      siblings[last_index] = Conditional([first_branch, branch])
    }
    _ =>
      raise CompilerError::InvalidDirective(
        "`\{conditional_directive_name(element)}` requires a preceding `v-if` on <\{tag}>",
      )
  }
}

///|
fn validate_conditional_chain(
  branches : Array[ConditionalBranch],
  element : TemplateElement,
  tag : String,
) -> Unit raise CompilerError {
  if branches.length() > 0 {
    let last = branches[branches.length() - 1]
    if last.condition is None {
      raise CompilerError::InvalidDirective(
        "`\{conditional_directive_name(element)}` cannot follow `v-else` on <\{tag}>",
      )
    }
  }
}

///|
fn conditional_directive_name(element : TemplateElement) -> String {
  if element.is_else {
    "v-else"
  } else {
    "v-else-if"
  }
}

///|
fn build_match_node(
  expr : String,
  children : Array[TemplateNode],
  tag : String,
) -> MatchNode raise CompilerError {
  let branches : Array[MatchBranch] = []
  let mut has_default = false
  for child in children {
    match child {
      Text(content) =>
        if content.trim().length() > 0 {
          raise CompilerError::InvalidDirective(
            "non-whitespace text is not allowed as direct child of `v-match` on <\{tag}>",
          )
        }
      Interpolation(_) =>
        raise CompilerError::InvalidDirective(
          "interpolation is not allowed as direct child of `v-match` on <\{tag}>",
        )
      Element(element) => {
        if element.case_pattern is None && not(element.is_case_default) {
          raise CompilerError::InvalidDirective(
            "direct children of `v-match` must use `v-case` on <\{tag}>: found <\{element.tag}> without `v-case`",
          )
        }
        if element.is_case_default {
          if has_default {
            raise CompilerError::InvalidDirective(
              "duplicate `v-default` in `v-match` on <\{tag}>",
            )
          }
          has_default = true
          branches.push({
            pattern: "_",
            is_default: true,
            element: { ..element, case_pattern: None, is_case_default: false },
          })
        } else {
          branches.push({
            pattern: element.case_pattern.unwrap(),
            is_default: false,
            element: { ..element, case_pattern: None, is_case_default: false },
          })
        }
      }
      Conditional(_) =>
        raise CompilerError::InvalidDirective(
          "conditional chains are not allowed inside `v-match` on <\{tag}>",
        )
      Match(_) =>
        raise CompilerError::InvalidDirective(
          "nested `v-match` is not allowed as direct child of `v-match` on <\{tag}>",
        )
    }
  }
  if branches.is_empty() {
    raise CompilerError::InvalidDirective(
      "`v-match` on <\{tag}> has no `v-case` children",
    )
  }
  { expr, branches }
}

///|
fn classify_template_attr(
  attr : ParsedTemplateAttr,
) -> TemplateAttr raise CompilerError {
  if attr.name.has_prefix(":") {
    {
      kind: Dynamic,
      name: String::unsafe_substring(attr.name, start=1, end=attr.name.length()),
      value: if attr.has_value {
        attr.value
      } else {
        String::unsafe_substring(attr.name, start=1, end=attr.name.length())
      },
      modifiers: [],
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
      modifiers: [],
    }
  } else if attr.name.has_prefix("@") {
    let (name, modifiers) = parse_event_attr(
      String::unsafe_substring(attr.name, start=1, end=attr.name.length()),
      attr.name,
    )
    { kind: Event, name, value: attr.value, modifiers }
  } else if attr.name.has_prefix("v-on:") {
    let (name, modifiers) = parse_event_attr(
      String::unsafe_substring(attr.name, start=5, end=attr.name.length()),
      attr.name,
    )
    { kind: Event, name, value: attr.value, modifiers }
  } else if attr.has_value {
    { kind: Static, name: attr.name, value: attr.value, modifiers: [] }
  } else {
    { kind: Boolean, name: attr.name, value: "true", modifiers: [] }
  }
}
