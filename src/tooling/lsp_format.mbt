///|
/// Best-effort whole-document formatter used by the `.mbtv` language server.
pub fn format_document(
  source : String,
  filename? : String = "Component.mbtv",
) -> String? {
  let doc = @compiler.parse_sfc(source, filename~) catch { _ => return None }
  let template_nodes = @compiler.parse_template(doc.template) catch {
    _ =>
      return Some(
        format_blocks(doc.blocks, normalize_raw_block_content(doc.template)),
      )
  }
  Some(
    format_blocks(
      doc.blocks,
      render_template_block(doc.template, template_nodes),
    ),
  )
}

///|
/// Convert a successful format into one full-document text edit.
pub fn formatting_edit(
  source : String,
  filename? : String = "Component.mbtv",
) -> ToolingTextEdit? {
  match format_document(source, filename~) {
    Some(formatted) =>
      if formatted == source {
        None
      } else {
        Some({ range: full_document_range(source), new_text: formatted })
      }
    None => None
  }
}

///|
/// Re-render all top-level blocks with stable spacing between them.
fn format_blocks(
  blocks : Array[@compiler.SfcBlock],
  rendered_template : String,
) -> String {
  let rendered : Array[String] = []
  for block in blocks {
    rendered.push(
      match block.kind {
        @compiler_common.Template =>
          render_named_block("template", block.attrs, rendered_template)
        @compiler_common.Style =>
          render_named_block(
            "style",
            block.attrs,
            normalize_raw_block_content(block.content),
          )
        @compiler_common.ScriptSetup | @compiler_common.ScriptExtern =>
          render_named_block(
            "script",
            block.attrs,
            normalize_raw_block_content(block.content),
          )
      },
    )
  }
  rendered.join("\n\n") + "\n"
}

///|
/// Render one top-level SFC block using its original attribute set.
fn render_named_block(
  tag : String,
  attrs : Array[@compiler.BlockAttr],
  content : String,
) -> String {
  let sb = StringBuilder::new()
  sb.write_char('<')
  sb.write_string(tag)
  for attr in attrs {
    sb.write_char(' ')
    sb.write_string(attr.name)
    match attr.value {
      Some(value) => {
        sb.write_string("=\"")
        sb.write_string(escape_block_attr_value(value))
        sb.write_char('"')
      }
      None => ()
    }
  }
  sb.write_string(">\n")
  if content.length() > 0 {
    sb.write_string(content)
    sb.write_char('\n')
  }
  sb.write_string("</")
  sb.write_string(tag)
  sb.write_char('>')
  sb.to_string()
}

///|
/// Normalize script/style block bodies without trying to rewrite MoonBit or CSS syntax.
fn normalize_raw_block_content(content : String) -> String {
  let lines = content.split("\n").map(fn(line) { line.to_string() }).collect()
  let normalized : Array[String] = []
  for line in lines {
    normalized.push(line.trim_end(chars=" \t\r").to_string())
  }
  let mut start = 0
  let mut end_ = normalized.length()
  while start < end_ && normalized[start].trim().length() == 0 {
    start += 1
  }
  while end_ > start && normalized[end_ - 1].trim().length() == 0 {
    end_ -= 1
  }
  let trimmed : Array[String] = []
  for index in start..<end_ {
    trimmed.push(normalized[index])
  }
  trimmed.join("\n")
}

///|
/// Format the `<template>` block when the AST can be rendered safely.
fn render_template_block(
  raw_template : String,
  nodes : Array[@compiler.TemplateNode],
) -> String {
  if raw_template.contains("<!--") || template_contains_match(nodes) {
    return normalize_raw_block_content(raw_template)
  }
  render_template_nodes(nodes, 2)
}

///|
fn template_contains_match(nodes : Array[@compiler.TemplateNode]) -> Bool {
  for node in nodes {
    if template_node_contains_match(node) {
      return true
    }
  }
  false
}

///|
fn template_node_contains_match(node : @compiler.TemplateNode) -> Bool {
  match node {
    @compiler_common.Match(_) => true
    @compiler_common.Text(_) | @compiler_common.Interpolation(_) => false
    @compiler_common.Element(element) =>
      template_contains_match(element.children)
    @compiler_common.Conditional(branches) => {
      for branch in branches {
        if template_contains_match(branch.element.children) {
          return true
        }
      }
      false
    }
  }
}

///|
fn render_template_nodes(
  nodes : Array[@compiler.TemplateNode],
  indent : Int,
) -> String {
  let rendered : Array[String] = []
  for node in nodes {
    rendered.push(render_template_node(node, indent))
  }
  rendered.join("\n")
}

///|
fn render_template_node(node : @compiler.TemplateNode, indent : Int) -> String {
  let prefix = format_indent(indent)
  match node {
    @compiler_common.Text(content) => prefix + escape_template_text(content)
    @compiler_common.Interpolation(expr) => prefix + "{{ " + expr + " }}"
    @compiler_common.Element(element) =>
      render_template_element(element, indent, false, [])
    @compiler_common.Conditional(branches) =>
      render_conditional_branches(branches, indent, false)
    @compiler_common.Match(_) => prefix
  }
}

///|
fn render_conditional_branches(
  branches : Array[@compiler.ConditionalBranch],
  indent : Int,
  force_inline : Bool,
) -> String {
  let rendered : Array[String] = []
  for index, branch in branches {
    let attrs = [
      if index == 0 {
        "v-if='" + escape_template_attr_value(branch.condition.unwrap()) + "'"
      } else {
        match branch.condition {
          Some(condition) =>
            "v-else-if='" + escape_template_attr_value(condition) + "'"
          None => "v-else"
        }
      },
    ]
    rendered.push(
      render_template_element(branch.element, indent, force_inline, attrs),
    )
  }
  if force_inline {
    rendered.join("")
  } else {
    rendered.join("\n")
  }
}

///|
fn render_template_element(
  element : @compiler.TemplateElement,
  indent : Int,
  force_inline : Bool,
  extra_attrs : Array[String],
) -> String {
  let prefix = format_indent(indent)
  let attrs = render_template_attr_parts(element, extra_attrs)
  if element.is_self_closing && element.children.is_empty() {
    return prefix + render_start_tag(element.tag, attrs, true)
  }
  let close = "</" + element.tag + ">"
  if force_inline || should_render_inline_children(element.children) {
    return prefix +
      render_start_tag(element.tag, attrs, false) +
      render_inline_children(element.children) +
      close
  }
  prefix +
  render_start_tag(element.tag, attrs, false) +
  "\n" +
  render_template_nodes(element.children, indent + 2) +
  "\n" +
  prefix +
  close
}

///|
fn should_render_inline_children(
  children : Array[@compiler.TemplateNode],
) -> Bool {
  if children.is_empty() {
    return true
  }
  for child in children {
    match child {
      @compiler_common.Text(_) | @compiler_common.Interpolation(_) =>
        return true
      _ => ()
    }
  }
  false
}

///|
fn render_inline_children(children : Array[@compiler.TemplateNode]) -> String {
  let sb = StringBuilder::new()
  for child in children {
    sb.write_string(render_inline_template_node(child))
  }
  sb.to_string()
}

///|
fn render_inline_template_node(node : @compiler.TemplateNode) -> String {
  match node {
    @compiler_common.Text(content) => escape_template_text(content)
    @compiler_common.Interpolation(expr) => "{{ " + expr + " }}"
    @compiler_common.Element(element) =>
      render_template_element(element, 0, true, [])
    @compiler_common.Conditional(branches) =>
      render_conditional_branches(branches, 0, true)
    @compiler_common.Match(_) => ""
  }
}

///|
fn render_start_tag(
  tag : String,
  attrs : Array[String],
  self_closing : Bool,
) -> String {
  let sb = StringBuilder::new()
  sb.write_char('<')
  sb.write_string(tag)
  for attr in attrs {
    sb.write_char(' ')
    sb.write_string(attr)
  }
  if self_closing {
    sb.write_string(" />")
  } else {
    sb.write_char('>')
  }
  sb.to_string()
}

///|
fn render_template_attr_parts(
  element : @compiler.TemplateElement,
  extra_attrs : Array[String],
) -> Array[String] {
  let attrs = extra_attrs.copy()
  match element.if_expr {
    Some(expr) => attrs.push("v-if='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  match element.else_if_expr {
    Some(expr) =>
      attrs.push("v-else-if='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  if element.is_else {
    attrs.push("v-else")
  }
  match element.match_expr {
    Some(expr) =>
      attrs.push("v-match='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  match element.case_pattern {
    Some(pattern) =>
      attrs.push("v-case='" + escape_template_attr_value(pattern) + "'")
    None => ()
  }
  if element.is_case_default {
    attrs.push("v-default")
  }
  match element.for_binding {
    Some(binding) =>
      attrs.push(
        "v-for='" +
        escape_template_attr_value(render_for_binding(binding)) +
        "'",
      )
    None => ()
  }
  match element.island_mode {
    @compiler_common.Load => attrs.push("client:load")
    @compiler_common.Idle => attrs.push("client:idle")
    @compiler_common.Visible => attrs.push("client:visible")
    @compiler_common.Media(query) =>
      attrs.push("client:media='" + escape_template_attr_value(query) + "'")
    @compiler_common.Only => attrs.push("client:only")
    @compiler_common.ServerDefer => attrs.push("server:defer")
    @compiler_common.None => ()
  }
  match element.show_expr {
    Some(expr) =>
      attrs.push("v-show='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  match element.html_expr {
    Some(expr) =>
      attrs.push("v-unsafe-html='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  match element.model {
    Some(model) => attrs.push(render_model_attr(model))
    None => ()
  }
  if element.once {
    attrs.push("v-once")
  }
  match element.key_expr {
    Some(expr) => attrs.push(":key='" + escape_template_attr_value(expr) + "'")
    None => ()
  }
  match element.ref_static_name {
    Some(name) => attrs.push("ref='" + escape_template_attr_value(name) + "'")
    None =>
      match element.ref_name {
        Some(expr) =>
          attrs.push(":ref='" + escape_template_attr_value(expr) + "'")
        None => ()
      }
  }
  match element.slot_name {
    Some(name) =>
      if name == "default" {
        attrs.push("v-slot")
      } else {
        attrs.push("v-slot:" + name)
      }
    None => ()
  }
  for attr in element.attrs {
    attrs.push(render_template_attr(attr))
  }
  attrs
}

///|
fn render_for_binding(binding : @compiler.ForBinding) -> String {
  match binding.index {
    Some(index) => "(" + binding.value + ", " + index + ") in " + binding.source
    None => binding.value + " in " + binding.source
  }
}

///|
fn render_model_attr(model : @compiler.TemplateModel) -> String {
  let sb = StringBuilder::new()
  sb.write_string("v-model")
  match model.argument {
    Some(argument) => sb.write_string(":" + argument)
    None => ()
  }
  for modifier in model.modifiers {
    sb.write_char('.')
    sb.write_string(modifier)
  }
  sb.write_string("='")
  sb.write_string(escape_template_attr_value(model.expression))
  sb.write_char('\'')
  sb.to_string()
}

///|
fn render_template_attr(attr : @compiler.TemplateAttr) -> String {
  match attr.kind {
    @compiler_common.Static =>
      attr.name + "='" + escape_template_attr_value(attr.value) + "'"
    @compiler_common.Dynamic =>
      ":" + attr.name + "='" + escape_template_attr_value(attr.value) + "'"
    @compiler_common.Event => {
      let parts : Array[String] = []
      for modifier in attr.modifiers {
        parts.push("." + modifier)
      }
      let suffix = parts.join("")
      "@" +
      attr.name +
      suffix +
      "='" +
      escape_template_attr_value(attr.value) +
      "'"
    }
    @compiler_common.Boolean => attr.name
  }
}

///|
fn format_indent(indent : Int) -> String {
  let sb = StringBuilder::new()
  for _ in 0..<indent {
    sb.write_char(' ')
  }
  sb.to_string()
}

///|
fn escape_template_text(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn escape_template_attr_value(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn escape_block_attr_value(source : String) -> String {
  let sb = StringBuilder::new()
  for ch in source {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '"' => sb.write_string("&quot;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}
