///|
/// Parse the `<template>` body into a lightweight HTML-like AST.

///|
pub fn parse_template(
  source : String,
) -> Array[TemplateNode] raise CompilerError {
  let chars = source.to_array()
  let roots : Array[TemplateNode] = []
  let stack : Array[TemplateFrame] = []
  let mut cursor = 0
  while cursor < chars.length() {
    let (token, next) = read_template_token(source, chars, cursor)
    cursor = next
    match token {
      Comment => ()
      TextToken(text) => append_text_like_nodes(text, roots, stack)
      InterpolationToken(expr) => append_node(Interpolation(expr), roots, stack)
      StartTagToken(tag) => on_start_tag(tag, roots, stack)
      EndTagToken(name) => on_end_tag(name, roots, stack)
    }
  }
  if stack.length() > 0 {
    let frame = stack[stack.length() - 1]
    raise CompilerError::InvalidTemplate(
      "missing closing tag </\{frame.element.tag}>",
    )
  }
  roots
}

///|
fn parse_for_binding(source : String) -> ForBinding raise CompilerError {
  match source.find(" in ") {
    Some(index) => {
      let left = String::unsafe_substring(source, start=0, end=index)
        .trim()
        .to_string()
      let right = String::unsafe_substring(
          source,
          start=index + 4,
          end=source.length(),
        )
        .trim()
        .to_string()
      if right.length() == 0 {
        raise CompilerError::InvalidDirective("invalid v-for source: \{source}")
      }
      if left.has_prefix("(") && left.has_suffix(")") {
        let body = String::unsafe_substring(
          left,
          start=1,
          end=left.length() - 1,
        )
        let items = body
          .split(",")
          .map(fn(part) { part.trim().to_string() })
          .collect()
        if items.length() == 0 || items[0].length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        {
          value: items[0],
          index: if items.length() > 1 && items[1].length() > 0 {
            Some(items[1])
          } else {
            None
          },
          source: right,
        }
      } else {
        if left.length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-for binding: \{source}",
          )
        }
        { value: left, index: None, source: right }
      }
    }
    None =>
      raise CompilerError::InvalidDirective(
        "expected `item in items`, got: \{source}",
      )
  }
}

///|
pub(all) enum TemplateToken {
  TextToken(String)
  InterpolationToken(String)
  StartTagToken(ParsedTemplateTag)
  EndTagToken(String)
  Comment
} derive(Eq, Show)

///|
struct ParsedTemplateTag {
  name : String
  attrs : Array[ParsedTemplateAttr]
  self_closing : Bool
} derive(Eq, Show)

///|
priv struct TemplateFrame {
  element : TemplateElement
  children : Array[TemplateNode]
}

///|
pub struct ParsedTemplateAttr {
  name : String
  value : String
  has_value : Bool
} derive(Eq, Show)
