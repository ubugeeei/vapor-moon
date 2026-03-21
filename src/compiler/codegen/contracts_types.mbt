///|
fn emit_props_contract(
  component_name : String,
  generics : Array[GenericParam],
  fields : Array[MacroField],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("pub struct ")
  sb.write_string(props_type_name(component_name))
  sb.write_string(render_fn_generics(generics))
  if fields.is_empty() {
    sb.write_string(" {} derive(Eq, Show)")
    return sb.to_string()
  }
  sb.write_string(" {\n")
  for field in fields {
    sb.write_string("  ")
    sb.write_string(field.name)
    sb.write_string(" : ")
    sb.write_string(field.signature.unwrap_or("String"))
    sb.write_string("\n")
  }
  sb.write_string("} derive(Eq, Show)")
  sb.to_string()
}

///|
fn emit_emits_contract(
  component_name : String,
  generics : Array[GenericParam],
  fields : Array[MacroField],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("pub struct ")
  sb.write_string(emits_type_name(component_name))
  sb.write_string(render_fn_generics(generics))
  if fields.is_empty() {
    sb.write_string(" {}")
  } else {
    sb.write_string(" {\n")
    for field in fields {
      sb.write_string("  ")
      sb.write_string(field.name)
      sb.write_string(" : ")
      sb.write_string(render_emit_callback_type(field))
      sb.write_string("\n")
    }
    sb.write_string("}")
  }
  sb.write_string("\n\n")
  sb.write_string(render_generic_fn_keyword(generics))
  sb.write_string(" ")
  sb.write_string(default_emits_name())
  sb.write_string("() -> ")
  sb.write_string(emits_type_name(component_name))
  sb.write_string(render_type_generics(generics))
  sb.write_string(" {\n")
  if fields.is_empty() {
    sb.write_string("  {}\n")
  } else {
    sb.write_string("  {\n")
    for field in fields {
      sb.write_string("    ")
      sb.write_string(field.name)
      sb.write_string(": ")
      sb.write_string(render_noop_callback(field.signature))
      sb.write_string(",\n")
    }
    sb.write_string("  }\n")
  }
  sb.write_string("}")
  sb.to_string()
}

///|
fn emit_slots_contract(
  component_name : String,
  generics : Array[GenericParam],
  fields : Array[MacroField],
  client : Bool,
) -> String {
  let node_type = if client {
    "@luna_dom.DomNode"
  } else {
    "@luna_core.StaticDomNode"
  }
  let type_name = slots_type_name(component_name, client)
  let sb = StringBuilder::new()
  sb.write_string("pub struct ")
  sb.write_string(type_name)
  sb.write_string(render_fn_generics(generics))
  if fields.is_empty() {
    sb.write_string(" {}")
  } else {
    sb.write_string(" {\n")
    for field in fields {
      sb.write_string("  ")
      sb.write_string(field.name)
      sb.write_string(" : ")
      sb.write_string(render_slot_callback_type(field, node_type))
      sb.write_string("?\n")
    }
    sb.write_string("}")
  }
  sb.write_string("\n\n")
  sb.write_string(render_generic_fn_keyword(generics))
  sb.write_string(" ")
  sb.write_string(default_slots_name(client))
  sb.write_string("() -> ")
  sb.write_string(type_name)
  sb.write_string(render_type_generics(generics))
  sb.write_string(" {\n")
  if fields.is_empty() {
    sb.write_string("  {}\n")
  } else {
    sb.write_string("  {\n")
    for field in fields {
      sb.write_string("    ")
      sb.write_string(field.name)
      sb.write_string(": None,\n")
    }
    sb.write_string("  }\n")
  }
  sb.write_string("}")
  sb.to_string()
}

///|
fn render_emit_callback_type(field : MacroField) -> String {
  match field.signature {
    Some(signature) if is_unit_contract_signature(signature) => "() -> Unit"
    Some(signature) => render_function_type(signature, "Unit")
    None => "() -> Unit"
  }
}

///|
fn render_slot_callback_type(field : MacroField, node_type : String) -> String {
  match field.signature {
    Some(signature) if is_unit_contract_signature(signature) =>
      "() -> Array[" + node_type + "]"
    Some(signature) =>
      render_function_type(signature, "Array[" + node_type + "]")
    None => "() -> Array[" + node_type + "]"
  }
}

///|
fn render_function_type(signature : String, return_type : String) -> String {
  let trimmed = signature.trim().to_string()
  if trimmed.has_prefix("(") && trimmed.has_suffix(")") {
    trimmed + " -> " + return_type
  } else {
    "(" + trimmed + ") -> " + return_type
  }
}

///|
fn render_noop_callback(signature : String?) -> String {
  match signature {
    Some(raw) if is_unit_contract_signature(raw) => "fn() { () }"
    Some(raw) => {
      let params = callback_param_names(raw)
      "fn(" + params.join(", ") + ") { () }"
    }
    None => "fn() { () }"
  }
}

///|
fn is_unit_contract_signature(signature : String) -> Bool {
  let trimmed = signature.trim().to_string()
  trimmed == "Unit" || trimmed == "()"
}

///|
fn callback_param_names(signature : String) -> Array[String] {
  let trimmed = signature.trim().to_string()
  if trimmed == "()" || trimmed.length() == 0 {
    return []
  }
  if trimmed.has_prefix("(") && trimmed.has_suffix(")") {
    let body = String::unsafe_substring(
        trimmed,
        start=1,
        end=trimmed.length() - 1,
      )
      .trim()
      .to_string()
    if body.length() == 0 {
      return []
    }
    let parts = body
      .split(",")
      .map(fn(part) { part.trim().to_string() })
      .collect()
    let names : Array[String] = []
    for index in 0..<parts.length() {
      names.push("_arg" + index.to_string())
    }
    return names
  }
  ["_payload"]
}

///|
fn render_generic_fn_keyword(generics : Array[GenericParam]) -> String {
  "fn" + render_fn_generics(generics)
}
