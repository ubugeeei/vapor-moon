///|
pub fn emit_client_module(
  doc : SfcDocument,
  template : Array[TemplateNode],
  component_name : String,
  scope_id : String?,
) -> String {
  let sb = StringBuilder::new()
  let base_imports = [
    "\"mizchi/luna/dom\" @luna_dom,", "\"ubugeeei/vapor_moon/src/runtime\" @vm,",
    "\"ubugeeei/vapor_moon/src/runtime/dom\" @vm_dom,",
  ]
  sb.write_string(
    emit_import_block(base_imports, doc.script_setup_import_entries),
  )
  sb.write_string(emit_component_contracts(doc, component_name, true))
  sb.write_string(render_component_signature(doc, component_name, true))
  if doc.script_setup_transformed is Some(script_setup) &&
    script_setup.trim().length() > 0 {
    sb.write_string(indent_block(script_setup.trim().to_string(), 2))
    sb.write_string("\n")
  }
  sb.write_string(render_client_nodes(template, 2, scope_id))
  sb.write_string("\n}\n\n")
  sb.write_string(emit_component_metadata(doc))
  sb.write_string("\n")
  sb.write_string("pub let component_name : String = ")
  sb.write_string(quote(component_name))
  sb.write_string("\n")
  sb.to_string()
}

///|
pub fn emit_server_module(
  doc : SfcDocument,
  template : Array[TemplateNode],
  component_name : String,
  scope_id : String?,
) -> String {
  let sb = StringBuilder::new()
  let base_imports = [
    "\"mizchi/luna/core\" @luna_core,", "\"ubugeeei/vapor_moon/src/runtime\" @vm,",
    "\"ubugeeei/vapor_moon/src/runtime/server\" @vm_server,",
  ]
  sb.write_string(
    emit_import_block(base_imports, doc.script_setup_import_entries),
  )
  sb.write_string(emit_component_contracts(doc, component_name, false))
  sb.write_string(render_component_signature(doc, component_name, false))
  if doc.script_setup_transformed is Some(script_setup) &&
    script_setup.trim().length() > 0 {
    sb.write_string(indent_block(script_setup.trim().to_string(), 2))
    sb.write_string("\n")
  }
  sb.write_string(render_server_nodes(template, 2, scope_id))
  sb.write_string("\n}\n\n")
  sb.write_string(emit_render_html_bridge(doc, component_name))
  sb.write_string("\n\n")
  sb.write_string(emit_component_metadata(doc))
  sb.write_string("\n")
  sb.write_string("pub let component_name : String = ")
  sb.write_string(quote(component_name))
  sb.write_string("\n")
  sb.to_string()
}

///|
fn emit_import_block(
  base_entries : Array[String],
  extra_entries : Array[String],
) -> String {
  let merged : Array[String] = []
  for entry in base_entries {
    if not(string_array_contains(merged, entry)) {
      merged.push(entry)
    }
  }
  for entry in extra_entries {
    if not(string_array_contains(merged, entry)) {
      merged.push(entry)
    }
  }
  let sb = StringBuilder::new()
  sb.write_string("import {\n")
  for entry in merged {
    sb.write_string("  ")
    sb.write_string(entry)
    sb.write_string("\n")
  }
  sb.write_string("}\n\n")
  sb.to_string()
}

///|
fn emit_component_metadata(doc : SfcDocument) -> String {
  let sb = StringBuilder::new()
  sb.write_string("pub fn declared_props() -> Array[String] {\n")
  sb.write_string("  ")
  sb.write_string(render_macro_names(doc.props))
  sb.write_string("\n}\n\n")
  sb.write_string("pub fn declared_emits() -> Array[String] {\n")
  sb.write_string("  ")
  sb.write_string(render_macro_names(doc.emits))
  sb.write_string("\n}\n\n")
  sb.write_string("pub fn declared_slots() -> Array[String] {\n")
  sb.write_string("  ")
  sb.write_string(render_macro_names(doc.slots))
  sb.write_string("\n}\n")
  sb.to_string()
}

///|
fn render_macro_names(fields : Array[MacroField]) -> String {
  if fields.is_empty() {
    return "[]"
  }
  let names : Array[String] = []
  for field in fields {
    names.push(quote(field.name))
  }
  "[" + names.join(", ") + "]"
}

///|
fn string_array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
