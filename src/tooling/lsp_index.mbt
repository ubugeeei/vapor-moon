///|
priv struct ToolingMemberDef {
  contract_kind : String
  binding_name : String
  name : String
  signature : String?
  span : @compiler.SourceSpan
}

///|
priv struct ToolingBindingDef {
  contract_kind : String
  binding_name : String
  span : @compiler.SourceSpan
  fields : Array[@compiler.MacroField]
}

///|
priv struct ToolingMemberRef {
  contract_kind : String
  binding_name : String
  member_name : String
  binding_span : @compiler.SourceSpan
  member_span : @compiler.SourceSpan
}

///|
priv struct ToolingIndex {
  source : String
  diagnostics : Array[ToolingDiagnostic]
  bindings : Array[ToolingBindingDef]
  members : Array[ToolingMemberDef]
  refs : Array[ToolingMemberRef]
}

///|
fn build_tooling_index(source : String, filename : String) -> ToolingIndex {
  let diagnostics : Array[ToolingDiagnostic] = []
  let bindings : Array[ToolingBindingDef] = []
  let members : Array[ToolingMemberDef] = []
  let refs : Array[ToolingMemberRef] = []
  let doc = @compiler.parse_sfc(source, filename~) catch {
    err => {
      diagnostics.push({
        severity: "error",
        message: err.to_string(),
        location: location_from_span(source, filename, { start: 0, end: 0 }),
      })
      return { source, diagnostics, bindings, members, refs }
    }
  }
  let _ = @compiler.parse_template(doc.template) catch {
    err => {
      diagnostics.push({
        severity: "error",
        message: err.to_string(),
        location: location_from_span(
          source,
          filename,
          find_block_span(doc.blocks, @compiler_common.Template),
        ),
      })
      []
    }
  }
  let script_span = find_block_content_span(
    source,
    doc.blocks,
    @compiler_common.ScriptSetup,
  )
  let template_span = find_block_content_span(
    source,
    doc.blocks,
    @compiler_common.Template,
  )
  collect_contract_index(
    source,
    script_span,
    "props",
    doc.props_binding,
    doc.props,
    "defineProps",
    bindings,
    members,
  )
  collect_contract_index(
    source,
    script_span,
    "emit",
    doc.emits_binding,
    doc.emits,
    "defineEmits",
    bindings,
    members,
  )
  collect_contract_index(
    source,
    script_span,
    "slots",
    doc.slots_binding,
    doc.slots,
    "defineSlot",
    bindings,
    members,
  )
  collect_contract_refs(source, script_span, bindings, members, refs)
  collect_contract_refs(source, template_span, bindings, members, refs)
  collect_semantic_diagnostics(
    source, filename, bindings, members, refs, diagnostics,
  )
  { source, diagnostics, bindings, members, refs }
}

///|
fn collect_contract_index(
  source : String,
  block_span : @compiler.SourceSpan?,
  canonical_name : String,
  binding_name : String?,
  fields : Array[@compiler.MacroField],
  macro_name : String,
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
) -> Unit {
  match block_span {
    Some(content_span) =>
      match binding_name {
        Some(binding) => {
          let binding_span = find_binding_definition_span(
            source, content_span, binding,
          ).unwrap_or(content_span)
          bindings.push({
            contract_kind: canonical_name,
            binding_name: binding,
            span: binding_span,
            fields,
          })
          let macro_span = find_macro_call_span(
            source, content_span, macro_name,
          ).unwrap_or(content_span)
          let mut cursor = macro_span.start
          for field in fields {
            let span = find_field_definition_span(
              source,
              { start: cursor, end: macro_span.end },
              field.name,
            ).unwrap_or(binding_span)
            members.push({
              contract_kind: canonical_name,
              binding_name: binding,
              name: field.name,
              signature: field.signature,
              span,
            })
            cursor = span.end
          }
        }
        None => ()
      }
    None => ()
  }
}

///|
fn collect_contract_refs(
  source : String,
  block_span : @compiler.SourceSpan?,
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
  refs : Array[ToolingMemberRef],
) -> Unit {
  match block_span {
    Some(span) => {
      let candidates : Array[(String, String)] = []
      for binding in bindings {
        candidates.push((binding.contract_kind, binding.binding_name))
        let canonical = canonical_binding_name(binding.contract_kind)
        if canonical != binding.binding_name {
          candidates.push((binding.contract_kind, canonical))
        }
      }
      for candidate in candidates {
        for ref_ in find_member_refs(source, span, candidate.0, candidate.1) {
          if overlaps_definition(ref_, bindings, members) {
            continue
          }
          refs.push(ref_)
        }
      }
    }
    None => ()
  }
}

///|
fn collect_semantic_diagnostics(
  source : String,
  filename : String,
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
  refs : Array[ToolingMemberRef],
  diagnostics : Array[ToolingDiagnostic],
) -> Unit {
  for ref_ in refs {
    match find_binding(bindings, ref_.contract_kind, ref_.binding_name) {
      Some(binding) =>
        match find_member(members, binding.binding_name, ref_.member_name) {
          Some(_) => ()
          None =>
            diagnostics.push({
              severity: "error",
              message: unknown_member_message(ref_),
              location: location_from_span(source, filename, ref_.member_span),
            })
        }
      None => {
        let actual = find_binding_by_kind(bindings, ref_.contract_kind)
        let message = match actual {
          Some(binding) =>
            "`" +
            ref_.binding_name +
            "` is not the " +
            ref_.contract_kind +
            " binding; use `" +
            binding.binding_name +
            "`"
          None =>
            "missing define" +
            uppercase_first(ref_.contract_kind) +
            "() binding for `" +
            ref_.binding_name +
            "`"
        }
        diagnostics.push({
          severity: "error",
          message,
          location: location_from_span(source, filename, ref_.binding_span),
        })
      }
    }
  }
}

///|
fn unknown_member_message(ref_ : ToolingMemberRef) -> String {
  if ref_.contract_kind == "emit" && ref_.member_name == "emit" {
    "legacy `emit.emit(...)` is not supported; use typed event calls like `" +
    ref_.binding_name +
    ".save()`"
  } else {
    "unknown " + ref_.contract_kind + " member `" + ref_.member_name + "`"
  }
}
