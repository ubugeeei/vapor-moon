///|
fn emit_props_contract(
  component_name : String,
  generics : Array[GenericParam],
  fields : Array[MacroField],
  defaults : Array[PropDefault],
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
    sb.write_string(render_public_prop_type(field, defaults))
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
      sb.write_string(render_noop_callback(field))
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
    Some(signature) => render_callback_type(signature, field.type_shape, "Unit")
    None => "() -> Unit"
  }
}

///|
fn render_slot_callback_type(field : MacroField, node_type : String) -> String {
  let return_type = "Array[" + node_type + "]"
  match field.signature {
    Some(signature) => render_callback_type(signature, field.type_shape, return_type)
    None => "() -> Array[" + node_type + "]"
  }
}

///|
fn render_callback_type(
  signature : String,
  type_shape : MacroFieldTypeShape,
  return_type : String,
) -> String {
  let trimmed = signature.trim().to_string()
  match type_shape {
    UnitLike => "() -> " + return_type
    TupleValues(_) => trimmed + " -> " + return_type
    SingleValue => "(" + trimmed + ") -> " + return_type
  }
}

///|
fn render_noop_callback(field : MacroField) -> String {
  match field.type_shape {
    UnitLike => "fn() { () }"
    TupleValues(count) => {
      let params = callback_param_names_from_count(count)
      "fn(" + params.join(", ") + ") { () }"
    }
    SingleValue => "fn(_payload) { () }"
  }
}

///|
fn callback_param_names_from_count(count : Int) -> Array[String] {
  let names : Array[String] = []
  for index in 0..<count {
    names.push("_arg" + index.to_string())
  }
  names
}

///|
fn render_generic_fn_keyword(generics : Array[GenericParam]) -> String {
  "fn" + render_fn_generics(generics)
}

///|
fn render_public_prop_type(
  field : MacroField,
  defaults : Array[PropDefault],
) -> String {
  let base = field.signature.unwrap_or("String")
  if has_prop_default_name(defaults, field.name) {
    base + "?"
  } else {
    base
  }
}

///|
fn has_prop_default_name(defaults : Array[PropDefault], name : String) -> Bool {
  for default_ in defaults {
    if default_.name == name {
      return true
    }
  }
  false
}
