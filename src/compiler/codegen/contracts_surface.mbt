///|
fn emit_component_contracts(
  doc : SfcDocument,
  component_name : String,
  client : Bool,
) -> String {
  let sections : Array[String] = []
  if has_props_contract(doc) {
    sections.push(emit_props_contract(component_name, doc.generics, doc.props))
  }
  if has_emits_contract(doc) {
    sections.push(emit_emits_contract(component_name, doc.generics, doc.emits))
  }
  if has_slots_contract(doc) {
    sections.push(
      emit_slots_contract(component_name, doc.generics, doc.slots, client),
    )
  }
  if sections.is_empty() {
    ""
  } else {
    sections.join("\n\n") + "\n\n"
  }
}

///|
fn render_component_signature(
  doc : SfcDocument,
  component_name : String,
  client : Bool,
) -> String {
  let name = if client { "render_dom" } else { "render_ssr" }
  let return_type = if client {
    "@luna_dom.DomNode"
  } else {
    "@luna_core.StaticDomNode"
  }
  "pub fn" +
  render_fn_generics(doc.generics) +
  " " +
  name +
  render_component_args(doc, component_name, client) +
  " -> " +
  return_type +
  " {\n"
}

///|
fn emit_render_html_bridge(
  doc : SfcDocument,
  component_name : String,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("pub fn")
  sb.write_string(render_fn_generics(doc.generics))
  sb.write_string(" render_html")
  sb.write_string(render_component_args(doc, component_name, false))
  sb.write_string(" -> String {\n")
  sb.write_string("  @vm_server.render_html(render_ssr")
  sb.write_string(render_component_forward_args(doc))
  sb.write_string(")\n")
  sb.write_string("}")
  sb.to_string()
}

///|
fn render_component_args(
  doc : SfcDocument,
  component_name : String,
  client : Bool,
) -> String {
  let args : Array[String] = []
  if has_props_contract(doc) {
    args.push(
      props_binding_name(doc) +
      " : " +
      props_type_name(component_name) +
      render_type_generics(doc.generics),
    )
  }
  if has_emits_contract(doc) {
    args.push(
      emits_binding_name(doc) +
      "? : " +
      emits_type_name(component_name) +
      render_type_generics(doc.generics) +
      " = " +
      default_emits_name() +
      "()",
    )
  }
  if has_slots_contract(doc) {
    args.push(
      slots_binding_name(doc) +
      "? : " +
      slots_type_name(component_name, client) +
      render_type_generics(doc.generics) +
      " = " +
      default_slots_name(client) +
      "()",
    )
  }
  "(" + args.join(", ") + ")"
}

///|
fn render_component_forward_args(doc : SfcDocument) -> String {
  let args : Array[String] = []
  if has_props_contract(doc) {
    args.push(props_binding_name(doc))
  }
  if has_emits_contract(doc) {
    let name = emits_binding_name(doc)
    args.push(name + "=" + name)
  }
  if has_slots_contract(doc) {
    let name = slots_binding_name(doc)
    args.push(name + "=" + name)
  }
  "(" + args.join(", ") + ")"
}

///|
fn has_props_contract(doc : SfcDocument) -> Bool {
  doc.props_binding is Some(_) || not(doc.props.is_empty())
}

///|
fn has_emits_contract(doc : SfcDocument) -> Bool {
  doc.emits_binding is Some(_) || not(doc.emits.is_empty())
}

///|
fn has_slots_contract(doc : SfcDocument) -> Bool {
  doc.slots_binding is Some(_) || not(doc.slots.is_empty())
}

///|
fn props_binding_name(doc : SfcDocument) -> String {
  doc.props_binding.unwrap_or("props")
}

///|
fn emits_binding_name(doc : SfcDocument) -> String {
  doc.emits_binding.unwrap_or("emit")
}

///|
fn slots_binding_name(doc : SfcDocument) -> String {
  doc.slots_binding.unwrap_or("slots")
}

///|
fn props_type_name(component_name : String) -> String {
  component_name + "Props"
}

///|
fn emits_type_name(component_name : String) -> String {
  component_name + "Emits"
}

///|
fn slots_type_name(component_name : String, client : Bool) -> String {
  component_name + (if client { "DomSlots" } else { "SsrSlots" })
}

///|
fn default_emits_name() -> String {
  "__vm_default_emits"
}

///|
fn default_slots_name(client : Bool) -> String {
  if client {
    "__vm_default_dom_slots"
  } else {
    "__vm_default_ssr_slots"
  }
}

///|
fn render_fn_generics(params : Array[GenericParam]) -> String {
  if params.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for param in params {
    parts.push(param.declaration)
  }
  "[" + parts.join(", ") + "]"
}

///|
fn render_type_generics(params : Array[GenericParam]) -> String {
  if params.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for param in params {
    parts.push(param.name)
  }
  "[" + parts.join(", ") + "]"
}
