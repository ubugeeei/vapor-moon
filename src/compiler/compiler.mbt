///|
/// SFC compiler entrypoint and code generators.

///|
pub fn compile(
  source : String,
  filename? : String = "Component.mbtv",
) -> CompileOutput raise CompilerError {
  let doc = @sfc.parse_sfc(source, filename~)
  let template = @template.parse_template(doc.template)
  reject_legacy_emit_calls(doc, template, filename)
  let component_name = @codegen.pascal_case(@codegen.base_name(filename))
  let scoped = doc.has_scoped_style()
  let scope_id = if scoped {
    Some("vm-" + @codegen.hash_string(filename))
  } else {
    None
  }
  let css_output = @codegen.emit_css(doc.styles, scope_id)
  {
    filename,
    component_name,
    extension: doc.extension,
    client_code: @codegen.emit_client_module(
      doc, template, component_name, scope_id,
    ),
    server_code: @codegen.emit_server_module(
      doc, template, component_name, scope_id,
    ),
    css_output,
    scope_id,
    island_components: @codegen.collect_island_components(template),
    generics: doc.generics,
    props_binding: doc.props_binding,
    props: doc.props,
    emits_binding: doc.emits_binding,
    emits: doc.emits,
    slots_binding: doc.slots_binding,
    slots: doc.slots,
  }
}

///|
fn reject_legacy_emit_calls(
  doc : SfcDocument,
  nodes : Array[TemplateNode],
  filename : String,
) -> Unit raise CompilerError {
  match doc.emits_binding {
    Some(binding) => {
      let legacy_pattern = binding + ".emit("
      match doc.script_setup_transformed {
        Some(script) if script.contains(legacy_pattern) =>
          raise CompilerError::InvalidScriptSetup(
            "legacy `\{legacy_pattern}...` is not supported in \{filename}; use typed event calls like `\{binding}.save()`",
          )
        _ => ()
      }
      for node in nodes {
        reject_legacy_emit_in_node(node, legacy_pattern, binding, filename)
      }
    }
    None => ()
  }
}

///|
fn reject_legacy_emit_in_node(
  node : TemplateNode,
  legacy_pattern : String,
  binding : String,
  filename : String,
) -> Unit raise CompilerError {
  match node {
    Text(_) => ()
    Interpolation(expr) =>
      reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
    Element(element) => {
      match element.if_expr {
        Some(expr) =>
          reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
        None => ()
      }
      match element.for_binding {
        Some(binding_) =>
          reject_legacy_emit_in_expr(
            binding_.source,
            legacy_pattern,
            binding,
            filename,
          )
        None => ()
      }
      match element.show_expr {
        Some(expr) =>
          reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
        None => ()
      }
      match element.html_expr {
        Some(expr) =>
          reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
        None => ()
      }
      match element.model {
        Some(model) =>
          reject_legacy_emit_in_expr(
            model.expression,
            legacy_pattern,
            binding,
            filename,
          )
        None => ()
      }
      match element.key_expr {
        Some(expr) =>
          reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
        None => ()
      }
      match element.ref_name {
        Some(expr) =>
          reject_legacy_emit_in_expr(expr, legacy_pattern, binding, filename)
        None => ()
      }
      for attr in element.attrs {
        reject_legacy_emit_in_expr(
          attr.value,
          legacy_pattern,
          binding,
          filename,
        )
      }
      for child in element.children {
        reject_legacy_emit_in_node(child, legacy_pattern, binding, filename)
      }
    }
  }
}

///|
fn reject_legacy_emit_in_expr(
  expr : String,
  legacy_pattern : String,
  binding : String,
  filename : String,
) -> Unit raise CompilerError {
  if expr.contains(legacy_pattern) {
    raise CompilerError::InvalidTemplate(
      "legacy `\{legacy_pattern}...` is not supported in \{filename}; use typed event calls like `\{binding}.save()`",
    )
  }
}
