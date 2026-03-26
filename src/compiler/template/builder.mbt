///|
/// Lower token visitor callbacks into normalized template AST nodes.
/// Start tags are accumulated in a temporary element state so structural
/// directives can be rewritten before code generation consumes the tree.

///|
/// Convert a raw text token into a `Text` node when it contains visible content.
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
    Text(
      decode_html_entities(String::unsafe_substring(source, start~, end=end_)),
    ),
    visitor.roots,
    visitor.stack,
  )
}

///|
/// Convert an interpolation token into an `Interpolation` node.
fn visitor_on_interpolation(
  visitor : TemplateTokenVisitor,
  expr : String,
) -> Unit raise CompilerError {
  append_node(Interpolation(expr), visitor.roots, visitor.stack)
}

///|
/// Handle an opening tag token by normalizing its attributes into a `TemplateElement`.
fn visitor_on_start_tag(
  visitor : TemplateTokenVisitor,
  tag : String,
  attrs : Array[ParsedTemplateAttr],
  self_closing : Bool,
) -> Unit raise CompilerError {
  on_start_tag({ name: tag, attrs, self_closing }, visitor.roots, visitor.stack)
}

///|
/// Close the current element frame and emit its finalized node.
fn visitor_on_end_tag(
  visitor : TemplateTokenVisitor,
  name : String,
) -> Unit raise CompilerError {
  on_end_tag(name, visitor.roots, visitor.stack)
}

///|
/// Start a new element frame or emit a self-closing node immediately.
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
/// Finalize the top frame, folding `v-match` containers into `Match` nodes.
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
/// Incrementally collects element-level metadata while raw attributes are parsed.
priv struct TemplateElementBuildState {
  tag : String
  is_component : Bool
  self_closing : Bool
  if_expr : String?
  else_if_expr : String?
  is_else : Bool
  for_binding : ForBinding?
  island_mode : IslandMode
  show_expr : String?
  html_expr : String?
  model : TemplateModel?
  key_expr : String?
  ref_name : String?
  ref_static_name : String?
  once : Bool
  match_expr : String?
  case_pattern : String?
  is_case_default : Bool
  slot_name : String?
  island_directive : String?
}

///|
/// Create the default build state for a newly opened template element.
fn new_template_element_build_state(
  tag : String,
  is_component : Bool,
  self_closing : Bool,
) -> TemplateElementBuildState {
  {
    tag,
    is_component,
    self_closing,
    if_expr: None,
    else_if_expr: None,
    is_else: false,
    for_binding: None,
    island_mode: IslandMode::None,
    show_expr: None,
    html_expr: None,
    model: None,
    key_expr: None,
    ref_name: None,
    ref_static_name: None,
    once: false,
    match_expr: None,
    case_pattern: None,
    is_case_default: false,
    slot_name: None,
    island_directive: None,
  }
}

///|
/// Normalize one start tag into a `TemplateElement`.
/// Structural directives fill dedicated element fields, while plain attributes
/// are normalized into `TemplateAttr` entries for later validation and codegen.
fn build_template_element(
  tag : String,
  attrs : Array[ParsedTemplateAttr],
  self_closing : Bool,
) -> TemplateElement raise CompilerError {
  validate_element_tag_form(tag, self_closing)
  let is_component = is_component_name(tag)
  let mut state = new_template_element_build_state(
    tag, is_component, self_closing,
  )
  let final_attrs : Array[TemplateAttr] = []
  for attr in attrs {
    state = apply_template_attr(state, attr, final_attrs)
  }
  finish_template_element(state, final_attrs)
}

///|
/// Dispatch one raw attribute through structural, hydration, and plain-attr handlers.
fn apply_template_attr(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
  final_attrs : Array[TemplateAttr],
) -> TemplateElementBuildState raise CompilerError {
  reject_unsupported_slot_outlet(attr, state.tag)
  reject_unknown_directive(attr, state.tag)
  match apply_structural_directive(state, attr) {
    Some(next) => next
    None =>
      match apply_island_directive(state, attr) {
        Some(next) => next
        None =>
          match apply_element_meta_directive(state, attr) {
            Some(next) => next
            None =>
              match apply_slot_directive(state, attr) {
                Some(next) => next
                None => apply_model_or_normal_attr(state, attr, final_attrs)
              }
          }
      }
  }
}

///|
/// Apply directives that affect control flow or element placement in the tree.
fn apply_structural_directive(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
) -> TemplateElementBuildState? raise CompilerError {
  let tag = state.tag
  match attr.name {
    "v-if" => {
      ensure_empty_expr_directive(state.if_expr, attr, tag)
      Some({ ..state, if_expr: Some(expect_attr_value(attr, tag)) })
    }
    "v-else-if" => {
      ensure_empty_expr_directive(state.else_if_expr, attr, tag)
      Some({ ..state, else_if_expr: Some(expect_attr_value(attr, tag)) })
    }
    "v-else" => {
      reject_unexpected_attr_value(attr, tag)
      if state.is_else {
        raise CompilerError::InvalidDirective("duplicate `v-else` on <\{tag}>")
      }
      Some({ ..state, is_else: true })
    }
    "v-match" => {
      ensure_empty_expr_directive(state.match_expr, attr, tag)
      Some({ ..state, match_expr: Some(expect_attr_value(attr, tag)) })
    }
    "v-case" => Some(apply_case_directive(state, attr))
    "v-default" => {
      reject_unexpected_attr_value(attr, tag)
      if state.case_pattern is Some(_) {
        raise CompilerError::InvalidDirective(
          "`v-default` cannot be combined with `v-case` on <\{tag}>",
        )
      }
      if state.is_case_default {
        raise CompilerError::InvalidDirective(
          "duplicate `v-default` on <\{tag}>",
        )
      }
      Some({ ..state, is_case_default: true })
    }
    "v-for" => {
      ensure_empty_expr_directive(
        occupied_directive_value(state.for_binding.map(fn(_) { "used" })),
        attr,
        tag,
      )
      Some({
        ..state,
        for_binding: Some(parse_for_binding(expect_attr_value(attr, tag))),
      })
    }
    _ => None
  }
}

///|
/// Parse one `v-case` branch, including `_` as the default branch shorthand.
fn apply_case_directive(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
) -> TemplateElementBuildState raise CompilerError {
  let tag = state.tag
  if state.is_case_default {
    raise CompilerError::InvalidDirective(
      "`v-case` cannot be combined with `v-default` on <\{tag}>",
    )
  }
  ensure_empty_expr_directive(state.case_pattern, attr, tag)
  if not(attr.has_value) {
    raise CompilerError::InvalidDirective(
      "`v-case` requires a pattern value on <\{tag}>; use `v-default` for the fallback branch",
    )
  }
  let value = attr.value.trim().to_string()
  if value == "_" {
    { ..state, is_case_default: true }
  } else {
    { ..state, case_pattern: Some(value) }
  }
}

///|
/// Apply island/hydration directives, enforcing the single-island-mode rule.
fn apply_island_directive(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
) -> TemplateElementBuildState? raise CompilerError {
  match attr.name {
    "client:load" =>
      Some(with_island_mode(state, attr, IslandMode::Load, false))
    "client:idle" =>
      Some(with_island_mode(state, attr, IslandMode::Idle, false))
    "client:visible" =>
      Some(with_island_mode(state, attr, IslandMode::Visible, false))
    "client:none" =>
      Some(with_island_mode(state, attr, IslandMode::None, false))
    "client:only" =>
      Some(with_island_mode(state, attr, IslandMode::Only, false))
    "server:defer" =>
      Some(with_island_mode(state, attr, IslandMode::ServerDefer, false))
    "client:media" =>
      Some(
        with_island_mode(
          state,
          attr,
          IslandMode::Media(expect_attr_value(attr, state.tag)),
          true,
        ),
      )
    _ => None
  }
}

///|
/// Record the chosen island mode and remember which directive claimed it first.
fn with_island_mode(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
  next_mode : IslandMode,
  keeps_value : Bool,
) -> TemplateElementBuildState raise CompilerError {
  if not(keeps_value) {
    reject_unexpected_attr_value(attr, state.tag)
  }
  {
    ..state,
    island_mode: register_island_mode(
      state.island_directive,
      attr,
      state.tag,
      next_mode,
    ),
    island_directive: Some(attr.name),
  }
}

///|
/// Apply non-structural directives that populate dedicated `TemplateElement` fields.
fn apply_element_meta_directive(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
) -> TemplateElementBuildState? raise CompilerError {
  let tag = state.tag
  match attr.name {
    "v-show" => {
      ensure_empty_expr_directive(state.show_expr, attr, tag)
      Some({ ..state, show_expr: Some(expect_attr_value(attr, tag)) })
    }
    "v-unsafe-html" => {
      ensure_empty_expr_directive(state.html_expr, attr, tag)
      Some({ ..state, html_expr: Some(expect_attr_value(attr, tag)) })
    }
    "v-once" => {
      reject_unexpected_attr_value(attr, tag)
      if state.once {
        raise CompilerError::InvalidDirective("duplicate `v-once` on <\{tag}>")
      }
      Some({ ..state, once: true })
    }
    "key" => {
      ensure_empty_expr_directive(state.key_expr, attr, tag)
      Some({
        ..state,
        key_expr: Some(quote_template_literal(expect_attr_value(attr, tag))),
      })
    }
    ":key" | "v-bind:key" => {
      ensure_empty_expr_directive(state.key_expr, attr, tag)
      Some({ ..state, key_expr: Some(expect_attr_value(attr, tag)) })
    }
    "ref" => {
      ensure_empty_expr_directive(state.ref_name, attr, tag)
      let value = expect_attr_value(attr, tag)
      Some({
        ..state,
        ref_name: Some(quote_template_literal(value)),
        ref_static_name: Some(value),
      })
    }
    ":ref" | "v-bind:ref" => {
      ensure_empty_expr_directive(state.ref_name, attr, tag)
      Some({
        ..state,
        ref_name: Some(expect_attr_value(attr, tag)),
        ref_static_name: None,
      })
    }
    _ => None
  }
}

///|
/// Capture the slot outlet name used by component children.
fn apply_slot_directive(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
) -> TemplateElementBuildState? raise CompilerError {
  if attr.name == "v-slot" {
    ensure_empty_expr_directive(state.slot_name, attr, state.tag)
    return Some({ ..state, slot_name: Some("default") })
  }
  if attr.name.has_prefix("v-slot:") {
    ensure_empty_expr_directive(state.slot_name, attr, state.tag)
    return Some({
      ..state,
      slot_name: Some(
        String::unsafe_substring(attr.name, start=7, end=attr.name.length()),
      ),
    })
  }
  if attr.name.has_prefix("#") {
    ensure_empty_expr_directive(state.slot_name, attr, state.tag)
    return Some({
      ..state,
      slot_name: Some(normalize_shorthand_slot_name(attr.name)),
    })
  }
  None
}

///|
/// Normalize `#default`-style shorthand into the internal slot name representation.
fn normalize_shorthand_slot_name(raw_name : String) -> String {
  let name = String::unsafe_substring(raw_name, start=1, end=raw_name.length())
  if name == "default" || name.length() == 0 {
    "default"
  } else {
    name
  }
}

///|
/// Either claim the attribute as `v-model` metadata or normalize it as a plain attr.
fn apply_model_or_normal_attr(
  state : TemplateElementBuildState,
  attr : ParsedTemplateAttr,
  final_attrs : Array[TemplateAttr],
) -> TemplateElementBuildState raise CompilerError {
  match parse_model_attr(attr) {
    Some(binding) => {
      ensure_empty_expr_directive(
        occupied_directive_value(state.model.map(fn(_) { "used" })),
        attr,
        state.tag,
      )
      validate_model_target(state.tag, state.is_component)
      { ..state, model: Some(binding) }
    }
    None => {
      let normalized = classify_template_attr(attr)
      validate_normalized_attr(attr, normalized, state.tag)
      validate_normalized_attr_conflict(final_attrs, normalized, state.tag)
      final_attrs.push(normalized)
      state
    }
  }
}

///|
/// Run final cross-field validation and freeze the accumulated element state.
fn finish_template_element(
  state : TemplateElementBuildState,
  final_attrs : Array[TemplateAttr],
) -> TemplateElement raise CompilerError {
  validate_component_bindings(
    state.tag,
    state.is_component,
    final_attrs,
    state.model,
    state.island_directive,
    state.show_expr,
    state.html_expr,
  )
  {
    tag: state.tag,
    attrs: final_attrs,
    children: [],
    is_component: state.is_component,
    is_self_closing: state.self_closing,
    if_expr: state.if_expr,
    for_binding: state.for_binding,
    island_mode: state.island_mode,
    show_expr: state.show_expr,
    html_expr: state.html_expr,
    model: state.model,
    key_expr: state.key_expr,
    ref_name: state.ref_name,
    ref_static_name: state.ref_static_name,
    ref_binding_name: None,
    once: state.once,
    else_if_expr: state.else_if_expr,
    is_else: state.is_else,
    match_expr: state.match_expr,
    case_pattern: state.case_pattern,
    is_case_default: state.is_case_default,
    slot_name: state.slot_name,
  }
}

///|
/// Append one node to either the current frame or the root list, rewriting `v-if` chains.
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
/// Extend the preceding `v-if` chain with `v-else-if` or `v-else`.
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
/// Guard against invalid branch ordering such as `v-else-if` after `v-else`.
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
/// Convert a branch marker element back into the directive name used by diagnostics.
fn conditional_directive_name(element : TemplateElement) -> String {
  if element.is_else {
    "v-else"
  } else {
    "v-else-if"
  }
}

///|
/// Collapse a `v-match` container into normalized branches with explicit default handling.
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
/// Normalize raw attribute syntax into one of the codegen-facing attribute kinds.
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
