///|
fn parse_model_attr(
  attr : ParsedTemplateAttr,
) -> TemplateModel? raise CompilerError {
  if not(attr.name.has_prefix("v-model")) {
    return None
  }
  if not(attr.has_value) || attr.value.trim().is_empty() {
    raise CompilerError::InvalidDirective(
      "`\{attr.name}` requires an expression",
    )
  }
  let suffix = String::unsafe_substring(
    attr.name,
    start=7,
    end=attr.name.length(),
  )
  let mut argument : String? = None
  let modifiers : Array[String] = []
  if suffix.length() > 0 {
    if suffix.has_prefix(":") {
      let remainder = String::unsafe_substring(
        suffix,
        start=1,
        end=suffix.length(),
      )
      let segments = remainder
        .split(".")
        .map(fn(part) { part.to_string() })
        .collect()
      if segments.length() == 0 || segments[0].length() == 0 {
        raise CompilerError::InvalidDirective(
          "invalid v-model syntax: `\{attr.name}`",
        )
      }
      argument = Some(segments[0])
      for index in 1..<segments.length() {
        if segments[index].length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-model syntax: `\{attr.name}`",
          )
        }
        modifiers.push(segments[index])
      }
    } else if suffix.has_prefix(".") {
      let remainder = String::unsafe_substring(
        suffix,
        start=1,
        end=suffix.length(),
      )
      let segments = remainder
        .split(".")
        .map(fn(part) { part.to_string() })
        .collect()
      for segment in segments {
        if segment.length() == 0 {
          raise CompilerError::InvalidDirective(
            "invalid v-model syntax: `\{attr.name}`",
          )
        }
        modifiers.push(segment)
      }
    } else {
      raise CompilerError::InvalidDirective(
        "invalid v-model syntax: `\{attr.name}`",
      )
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
