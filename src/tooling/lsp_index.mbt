///|
/// Semantic index shared by hover, definition, completion, and diagnostics queries.

///|
/// Distinguishes direct macro access from accesses that go through `resolve_template_ref`.
priv enum ToolingBindingAccessMode {
  Direct
  ResolveTemplateRef
} derive(Eq)

///|
/// Definition site for one contract field that can appear in hover/definition results.
priv struct ToolingMemberDef {
  contract_kind : String
  binding_name : String
  name : String
  signature : String?
  span : @compiler.SourceSpan
}

///|
/// Definition site for a binding such as `props`, `emit`, or a template ref.
priv struct ToolingBindingDef {
  contract_kind : String
  binding_name : String
  span : @compiler.SourceSpan
  fields : Array[@compiler.MacroField]
  type_name : String?
  access_mode : ToolingBindingAccessMode
}

///|
/// One resolved member access found in source code.
priv struct ToolingMemberRef {
  contract_kind : String
  binding_name : String
  member_name : String
  binding_span : @compiler.SourceSpan
  member_span : @compiler.SourceSpan
}

///|
/// Full semantic index derived from a single `.mbtv` source document.
priv struct ToolingIndex {
  source : String
  diagnostics : Array[ToolingDiagnostic]
  bindings : Array[ToolingBindingDef]
  members : Array[ToolingMemberDef]
  refs : Array[ToolingMemberRef]
}

///|
/// Static target inferred from a named template ref in the template tree.
priv struct ToolingStaticTemplateRefTarget {
  ref_name : String
  type_name : String
  fields : Array[@compiler.MacroField]
}

///|
/// Script-side template ref binding after its target type has been inferred.
priv struct ToolingResolvedTemplateRef {
  binding_name : String
  type_name : String
  fields : Array[@compiler.MacroField]
}

///|
/// Build the semantic index consumed by editor queries and diagnostics.
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
  let template = @compiler.parse_template(doc.template) catch {
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
  let resolved_template_refs = resolve_tooling_template_refs(
    doc, template, filename,
  )
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
    bindings,
    members,
  )
  collect_contract_index(
    source,
    script_span,
    "emit",
    doc.emits_binding,
    doc.emits,
    bindings,
    members,
  )
  collect_contract_index(
    source,
    script_span,
    "slots",
    doc.slots_binding,
    doc.slots,
    bindings,
    members,
  )
  collect_contract_index(
    source,
    script_span,
    "expose",
    doc.expose_binding,
    doc.expose,
    bindings,
    members,
  )
  collect_template_ref_index(
    source, script_span, resolved_template_refs, bindings, members,
  )
  collect_contract_refs(source, script_span, bindings, members, refs)
  collect_contract_refs(source, template_span, bindings, members, refs)
  collect_template_ref_refs(source, script_span, bindings, members, refs)
  collect_template_ref_refs(source, template_span, bindings, members, refs)
  collect_semantic_diagnostics(
    source, filename, bindings, members, refs, diagnostics,
  )
  { source, diagnostics, bindings, members, refs }
}

///|
/// Register one macro contract binding and all of its declared fields.
fn collect_contract_index(
  source : String,
  block_span : @compiler.SourceSpan?,
  canonical_name : String,
  binding_name : String?,
  fields : Array[@compiler.MacroField],
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
            type_name: None,
            access_mode: Direct,
          })
          for field in fields {
            let span = find_contract_field_definition_span(
              source,
              content_span,
              binding,
              field.name,
            ).unwrap_or(binding_span)
            members.push({
              contract_kind: canonical_name,
              binding_name: binding,
              name: field.name,
              signature: field.signature,
              span,
            })
          }
        }
        None => ()
      }
    None => ()
  }
}

///|
/// Register `use_template_ref()` bindings together with their inferred member sets.
fn collect_template_ref_index(
  source : String,
  block_span : @compiler.SourceSpan?,
  resolved_template_refs : Array[ToolingResolvedTemplateRef],
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
) -> Unit {
  match block_span {
    Some(content_span) =>
      for resolved_ref in resolved_template_refs {
        let binding_span = find_binding_definition_span(
          source,
          content_span,
          resolved_ref.binding_name,
        ).unwrap_or(content_span)
        bindings.push({
          contract_kind: "template ref",
          binding_name: resolved_ref.binding_name,
          span: binding_span,
          fields: resolved_ref.fields,
          type_name: Some(resolved_ref.type_name),
          access_mode: ResolveTemplateRef,
        })
        for field in resolved_ref.fields {
          members.push({
            contract_kind: "template ref",
            binding_name: resolved_ref.binding_name,
            name: field.name,
            signature: field.signature,
            span: binding_span,
          })
        }
      }
    None => ()
  }
}

///|
/// Scan source spans for member accesses against direct macro bindings.
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
        if binding.access_mode != Direct {
          continue
        }
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
/// Scan source spans for member accesses behind `resolve_template_ref(...)`.
fn collect_template_ref_refs(
  source : String,
  block_span : @compiler.SourceSpan?,
  bindings : Array[ToolingBindingDef],
  members : Array[ToolingMemberDef],
  refs : Array[ToolingMemberRef],
) -> Unit {
  match block_span {
    Some(span) =>
      for binding in bindings {
        if binding.access_mode != ResolveTemplateRef {
          continue
        }
        for
          ref_ in find_resolved_template_ref_member_refs(
            source,
            span,
            binding.binding_name,
          ) {
          if overlaps_definition(ref_, bindings, members) {
            continue
          }
          refs.push(ref_)
        }
      }
    None => ()
  }
}

///|
/// Emit semantic diagnostics such as unknown members or mismatched bindings.
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
          None if binding.access_mode == ResolveTemplateRef &&
            binding.fields.is_empty() => ()
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
          None if ref_.contract_kind == "template ref" =>
            "missing template ref binding for `" + ref_.binding_name + "`"
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
/// Render the diagnostic shown for an unresolved member access.
fn unknown_member_message(ref_ : ToolingMemberRef) -> String {
  if ref_.contract_kind == "emit" && ref_.member_name == "emit" {
    "legacy `emit.emit(...)` is not supported; use typed event calls like `" +
    ref_.binding_name +
    ".save()`"
  } else if ref_.contract_kind == "template ref" {
    "unknown template ref member `" + ref_.member_name + "`"
  } else {
    "unknown " + ref_.contract_kind + " member `" + ref_.member_name + "`"
  }
}

///|
/// Infer template-ref binding types by combining script metadata with template refs.
fn resolve_tooling_template_refs(
  doc : @compiler.SfcDocument,
  nodes : Array[@compiler.TemplateNode],
  filename : String,
) -> Array[ToolingResolvedTemplateRef] {
  let static_targets = collect_static_template_ref_targets(nodes, filename)
  let resolved : Array[ToolingResolvedTemplateRef] = []
  for template_ref in doc.template_refs {
    match template_ref.binding_name {
      Some(binding_name) => {
        let target = match template_ref.ref_name {
          Some(name) =>
            find_static_template_ref_target(static_targets, name).unwrap_or({
              ref_name: name,
              type_name: "@js_dom.Element",
              fields: [],
            })
          None =>
            {
              ref_name: template_ref.arg_source,
              type_name: "@js_dom.Element",
              fields: [],
            }
        }
        resolved.push({
          binding_name,
          type_name: target.type_name,
          fields: target.fields,
        })
      }
      None => ()
    }
  }
  resolved
}

///|
/// Gather the static template refs declared in the template tree.
fn collect_static_template_ref_targets(
  nodes : Array[@compiler.TemplateNode],
  filename : String,
) -> Array[ToolingStaticTemplateRefTarget] {
  let targets : Array[ToolingStaticTemplateRefTarget] = []
  for node in nodes {
    collect_static_template_ref_targets_into(node, filename, targets)
  }
  targets
}

///|
/// Walk one template subtree and register any statically named refs it contains.
fn collect_static_template_ref_targets_into(
  node : @compiler.TemplateNode,
  filename : String,
  targets : Array[ToolingStaticTemplateRefTarget],
) -> Unit {
  match node {
    @compiler_common.Text(_) | @compiler_common.Interpolation(_) => ()
    @compiler_common.Element(element) => {
      match element.ref_static_name {
        Some(name) =>
          register_static_template_ref_target(
            targets,
            name,
            infer_tooling_template_ref_target(element, filename),
          )
        None => ()
      }
      for child in element.children {
        collect_static_template_ref_targets_into(child, filename, targets)
      }
    }
    @compiler_common.Conditional(branches) =>
      for branch in branches {
        collect_static_template_ref_targets_into(
          @compiler_common.Element(branch.element),
          filename,
          targets,
        )
      }
    @compiler_common.Match(node) =>
      for branch in node.branches {
        collect_static_template_ref_targets_into(
          @compiler_common.Element(branch.element),
          filename,
          targets,
        )
      }
  }
}

///|
/// Merge a newly inferred target into the table keyed by ref name.
fn register_static_template_ref_target(
  targets : Array[ToolingStaticTemplateRefTarget],
  ref_name : String,
  next_target : (String, Array[@compiler.MacroField]),
) -> Unit {
  let next = { ref_name, type_name: next_target.0, fields: next_target.1 }
  for i in 0..<targets.length() {
    if targets[i].ref_name == ref_name {
      targets[i] = merge_static_template_ref_target(targets[i], next)
      return
    }
  }
  targets.push(next)
}

///|
/// Downgrade conflicting static ref targets to a generic DOM element type.
fn merge_static_template_ref_target(
  current : ToolingStaticTemplateRefTarget,
  next_ : ToolingStaticTemplateRefTarget,
) -> ToolingStaticTemplateRefTarget {
  if current.type_name == next_.type_name &&
    macro_fields_equal(current.fields, next_.fields) {
    return current
  }
  { ref_name: current.ref_name, type_name: "@js_dom.Element", fields: [] }
}

///|
/// Compare macro field lists exactly so ref targets can be merged safely.
fn macro_fields_equal(
  left : Array[@compiler.MacroField],
  right : Array[@compiler.MacroField],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i] != right[i] {
      return false
    }
  }
  true
}

///|
/// Infer the exposed type and fields for a single template ref target element.
fn infer_tooling_template_ref_target(
  element : @compiler.TemplateElement,
  filename : String,
) -> (String, Array[@compiler.MacroField]) {
  if element.is_component {
    return infer_component_template_ref_target(element.tag, filename)
  }
  (infer_native_template_ref_type_name(element.tag), [])
}

///|
/// Resolve component refs by reading the referenced component file when possible.
fn infer_component_template_ref_target(
  tag : String,
  filename : String,
) -> (String, Array[@compiler.MacroField]) {
  for path in component_template_ref_candidate_paths(filename, tag) {
    if not(@fs.path_exists(path)) {
      continue
    }
    let source = @fs.read_file_to_string(path) catch { _ => continue }
    let doc = @compiler.parse_sfc(source, filename=path) catch { _ => continue }
    if not(doc.expose.is_empty()) || doc.expose_binding is Some(_) {
      return (tag + " expose", doc.expose)
    }
    return ("component " + tag, [])
  }
  ("component " + tag, [])
}

///|
fn component_template_ref_candidate_paths(
  filename : String,
  tag : String,
) -> Array[String] {
  let candidates : Array[String] = []
  let dir = path_dirname(filename)
  push_unique_string(candidates, join_path(dir, tag + ".mbtv"))
  push_unique_string(candidates, join_path(dir, kebab_case_tag(tag) + ".mbtv"))
  candidates
}

///|
fn find_static_template_ref_target(
  targets : Array[ToolingStaticTemplateRefTarget],
  ref_name : String,
) -> ToolingStaticTemplateRefTarget? {
  for target in targets {
    if target.ref_name == ref_name {
      return Some(target)
    }
  }
  None
}

///|
fn infer_native_template_ref_type_name(tag : String) -> String {
  match tag {
    "a" => "@js_dom.HTMLAnchorElement"
    "body" => "@js_dom.HTMLBodyElement"
    "button" => "@js_dom.HTMLButtonElement"
    "canvas" => "@js_dom.HTMLCanvasElement"
    "div" => "@js_dom.HTMLDivElement"
    "form" => "@js_dom.HTMLFormElement"
    "h1" | "h2" | "h3" | "h4" | "h5" | "h6" => "@js_dom.HTMLHeadingElement"
    "head" => "@js_dom.HTMLHeadElement"
    "html" => "@js_dom.HTMLHtmlElement"
    "iframe" => "@js_dom.HTMLIFrameElement"
    "img" => "@js_dom.HTMLImageElement"
    "input" => "@js_dom.HTMLInputElement"
    "label" => "@js_dom.HTMLLabelElement"
    "li" => "@js_dom.HTMLLIElement"
    "ol" => "@js_dom.HTMLOListElement"
    "option" => "@js_dom.HTMLOptionElement"
    "p" => "@js_dom.HTMLParagraphElement"
    "select" => "@js_dom.HTMLSelectElement"
    "span" => "@js_dom.HTMLSpanElement"
    "textarea" => "@js_dom.HTMLTextAreaElement"
    "ul" => "@js_dom.HTMLUListElement"
    _ => "@js_dom.HTMLElement"
  }
}

///|
fn path_dirname(path : String) -> String {
  let chars = path.to_array()
  let mut cursor = chars.length()
  while cursor > 0 {
    let ch = chars[cursor - 1]
    if ch == '/' || ch == '\\' {
      return String::unsafe_substring(path, start=0, end=cursor - 1)
    }
    cursor -= 1
  }
  ""
}

///|
fn join_path(dir : String, base : String) -> String {
  if dir.length() == 0 {
    return base
  }
  dir + "/" + base
}

///|
fn kebab_case_tag(tag : String) -> String {
  let sb = StringBuilder::new()
  let chars = tag.to_array()
  for i in 0..<chars.length() {
    let ch = chars[i]
    if ch >= 'A' && ch <= 'Z' {
      if i > 0 {
        let prev = chars[i - 1]
        if (prev >= 'a' && prev <= 'z') || (prev >= '0' && prev <= '9') {
          sb.write_char('-')
        }
      }
      sb.write_char(
        (ch.to_int() - 'A'.to_int() + 'a'.to_int()).unsafe_to_char(),
      )
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn push_unique_string(values : Array[String], next_ : String) -> Unit {
  for value in values {
    if value == next_ {
      return
    }
  }
  values.push(next_)
}
