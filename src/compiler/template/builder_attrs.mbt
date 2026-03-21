///|
fn parse_model_attr(
  attr : ParsedTemplateAttr,
) -> TemplateModel? raise CompilerError {
  if not(attr.name.has_prefix("v-model")) {
    return None
  }
  if not(attr.has_value) || attr.value.trim().length() == 0 {
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
