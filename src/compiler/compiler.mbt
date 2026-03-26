///|
/// SFC compiler entrypoint and code generators.

///|
pub fn compile(
  source : String,
  filename? : String = "Component.mbtv",
) -> CompileOutput raise CompilerError {
  let doc = @sfc.parse_sfc(source, filename~)
  let template = @template.parse_template(doc.template)
  compile_from_parts(doc, template, filename)
}

///|
/// Assemble CompileOutput from pre-parsed SFC document and template nodes.
/// Use this when you already have parsed results (e.g. from incremental queries).
pub fn compile_from_parts(
  doc : SfcDocument,
  template : Array[TemplateNode],
  filename : String,
) -> CompileOutput raise CompilerError {
  reject_legacy_emit_calls(doc, template, filename)
  let resolved_template_refs = resolve_template_refs(doc.template_refs, template)
  let resolved_doc = resolve_template_ref_doc(doc, resolved_template_refs)
  let bound_template = bind_template_ref_nodes(template, resolved_template_refs)
  let component_name = @codegen.pascal_case(@codegen.base_name(filename))
  let scope_id = compute_scope_id(resolved_doc, filename)
  let css_output = @codegen.emit_css(resolved_doc.styles, scope_id)
  {
    filename,
    component_name,
    extension: resolved_doc.extension,
    client_code: @codegen.emit_client_module(
      resolved_doc,
      bound_template,
      component_name,
      scope_id,
    ),
    server_code: @codegen.emit_server_module(
      resolved_doc,
      bound_template,
      component_name,
      scope_id,
    ),
    css_output,
    scope_id,
    island_components: @codegen.collect_island_components(bound_template),
    generics: resolved_doc.generics,
    props_binding: resolved_doc.props_binding,
    props: resolved_doc.props,
    emits_binding: resolved_doc.emits_binding,
    emits: resolved_doc.emits,
    slots_binding: resolved_doc.slots_binding,
    slots: resolved_doc.slots,
  }
}

///|
priv struct ResolvedTemplateRef {
  binding_name : String?
  arg_source : String
  ref_name : String?
  type_name : String
}

///|
pub fn compute_scope_id(doc : SfcDocument, filename : String) -> String? {
  if doc.has_scoped_style() {
    Some("vm-" + @codegen.hash_string(filename))
  } else {
    None
  }
}

///|
fn reject_legacy_emit_calls(
  doc : SfcDocument,
  nodes : Array[TemplateNode],
  filename : String,
) -> Unit raise CompilerError {
  validate_template_expressions(nodes, doc.emits_binding, filename)
  match doc.emits_binding {
    Some(binding) =>
      match doc.script_setup {
        Some(script) if script_setup_contains_legacy_emit_call(
            script, binding, filename,
          ) =>
          raise CompilerError::InvalidScriptSetup(
            legacy_emit_message(binding, filename),
          )
        _ => ()
      }
    None => ()
  }
}

///|
fn validate_template_expressions(
  nodes : Array[TemplateNode],
  binding : String?,
  filename : String,
) -> Unit raise CompilerError {
  for node in nodes {
    validate_template_node(node, binding, filename)
  }
}

///|
fn validate_template_node(
  node : TemplateNode,
  binding : String?,
  filename : String,
) -> Unit raise CompilerError {
  match node {
    Text(_) => ()
    Interpolation(expr) => validate_template_expr(expr, binding, filename)
    Element(element) => {
      match element.if_expr {
        Some(expr) => validate_template_expr(expr, binding, filename)
        None => ()
      }
      match element.for_binding {
        Some(binding_) =>
          validate_template_expr(binding_.source, binding, filename)
        None => ()
      }
      match element.show_expr {
        Some(expr) => validate_template_expr(expr, binding, filename)
        None => ()
      }
      match element.html_expr {
        Some(expr) => validate_template_expr(expr, binding, filename)
        None => ()
      }
      match element.model {
        Some(model) => {
          let parsed = validate_template_expr_with_ast(
            model.expression,
            binding,
            filename,
          )
          validate_model_target_expr(parsed, model.expression, element.tag)
        }
        None => ()
      }
      match element.key_expr {
        Some(expr) => validate_template_expr(expr, binding, filename)
        None => ()
      }
      match element.ref_name {
        Some(expr) => validate_template_expr(expr, binding, filename)
        None => ()
      }
      for attr in element.attrs {
        match attr.kind {
          Dynamic | Event =>
            validate_template_expr(attr.value, binding, filename)
          Static | Boolean => ()
        }
      }
      for child in element.children {
        validate_template_node(child, binding, filename)
      }
    }
    Conditional(branches) =>
      for branch in branches {
        match branch.condition {
          Some(expr) => validate_template_expr(expr, binding, filename)
          None => ()
        }
        validate_template_node(Element(branch.element), binding, filename)
      }
    Match(node) =>
      for branch in node.branches {
        validate_template_node(Element(branch.element), binding, filename)
      }
  }
}

///|
fn resolve_template_refs(
  template_refs : Array[ScriptSetupTemplateRef],
  nodes : Array[TemplateNode],
) -> Array[ResolvedTemplateRef] {
  let static_ref_types = collect_static_template_ref_types(nodes)
  let resolved : Array[ResolvedTemplateRef] = []
  for template_ref in template_refs {
    let type_name = match template_ref.ref_name {
      Some(name) =>
        find_static_template_ref_type(static_ref_types, name)
        .unwrap_or("@js_dom.Element")
      None => "@js_dom.Element"
    }
    resolved.push({
      binding_name: template_ref.binding_name,
      arg_source: template_ref.arg_source,
      ref_name: template_ref.ref_name,
      type_name,
    })
  }
  resolved
}

///|
fn collect_static_template_ref_types(
  nodes : Array[TemplateNode],
) -> Array[(String, String)] {
  let refs : Array[(String, String)] = []
  for node in nodes {
    collect_static_template_ref_types_into(node, refs)
  }
  refs
}

///|
fn collect_static_template_ref_types_into(
  node : TemplateNode,
  refs : Array[(String, String)],
) -> Unit {
  match node {
    Text(_) | Interpolation(_) => ()
    Element(element) => {
      match element.ref_static_name {
        Some(name) =>
          register_static_template_ref_type(
            refs,
            name,
            infer_template_ref_type(element),
          )
        None => ()
      }
      for child in element.children {
        collect_static_template_ref_types_into(child, refs)
      }
    }
    Conditional(branches) =>
      for branch in branches {
        collect_static_template_ref_types_into(Element(branch.element), refs)
      }
    Match(node) =>
      for branch in node.branches {
        collect_static_template_ref_types_into(Element(branch.element), refs)
      }
  }
}

///|
fn register_static_template_ref_type(
  refs : Array[(String, String)],
  name : String,
  next_type : String,
) -> Unit {
  for i in 0..<refs.length() {
    if refs[i].0 == name {
      refs[i] = (name, merge_template_ref_type(refs[i].1, next_type))
      return
    }
  }
  refs.push((name, next_type))
}

///|
fn infer_template_ref_type(element : TemplateElement) -> String {
  if element.is_component {
    return "@js_dom.HTMLElement"
  }
  infer_native_template_ref_type(element.tag)
}

///|
fn infer_native_template_ref_type(tag : String) -> String {
  match tag {
    "a" => "@js_dom.HTMLAnchorElement"
    "body" => "@js_dom.HTMLBodyElement"
    "button" => "@js_dom.HTMLButtonElement"
    "canvas" => "@js_dom.HTMLCanvasElement"
    "div" => "@js_dom.HTMLDivElement"
    "form" => "@js_dom.HTMLFormElement"
    "h1" | "h2" | "h3" | "h4" | "h5" | "h6" =>
      "@js_dom.HTMLHeadingElement"
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
fn merge_template_ref_type(current : String, next_ : String) -> String {
  if current == next_ {
    return current
  }
  if current == "@js_dom.Element" || next_ == "@js_dom.Element" {
    return "@js_dom.Element"
  }
  "@js_dom.HTMLElement"
}

///|
fn find_static_template_ref_type(
  refs : Array[(String, String)],
  name : String,
) -> String? {
  for ref_ in refs {
    if ref_.0 == name {
      return Some(ref_.1)
    }
  }
  None
}

///|
fn resolve_template_ref_doc(
  doc : SfcDocument,
  resolved_refs : Array[ResolvedTemplateRef],
) -> SfcDocument {
  if resolved_refs.is_empty() {
    return doc
  }
  let transformed = match doc.script_setup_transformed {
    Some(script_setup) => Some(
      specialize_template_ref_calls(script_setup, resolved_refs),
    )
    None => None
  }
  let imports = append_unique_import(
    doc.script_setup_import_entries,
    "\"mizchi/js/browser/dom\" @js_dom,",
  )
  { ..doc, script_setup_transformed: transformed, script_setup_import_entries: imports }
}

///|
fn specialize_template_ref_calls(
  script_setup : String,
  resolved_refs : Array[ResolvedTemplateRef],
) -> String {
  let mut current = script_setup
  for ref_ in resolved_refs {
    current = current.replace_all(
      old="@vm.use_template_ref(" + ref_.arg_source + ")",
      new="@vm.use_template_ref[" + ref_.type_name + "](" + ref_.arg_source + ")",
    )
  }
  current
}

///|
fn append_unique_import(entries : Array[String], entry : String) -> Array[String] {
  let merged = entries.copy()
  for current in merged {
    if current == entry {
      return merged
    }
  }
  merged.push(entry)
  merged
}

///|
fn bind_template_ref_nodes(
  nodes : Array[TemplateNode],
  resolved_refs : Array[ResolvedTemplateRef],
) -> Array[TemplateNode] {
  let bound : Array[TemplateNode] = []
  for node in nodes {
    bound.push(bind_template_ref_node(node, resolved_refs))
  }
  bound
}

///|
fn bind_template_ref_node(
  node : TemplateNode,
  resolved_refs : Array[ResolvedTemplateRef],
) -> TemplateNode {
  match node {
    Text(_) | Interpolation(_) => node
    Element(element) =>
      Element(bind_template_ref_element(element, resolved_refs))
    Conditional(branches) => {
      let next_branches = []
      for branch in branches {
        next_branches.push({
          ..branch,
          element: bind_template_ref_element(branch.element, resolved_refs),
        })
      }
      Conditional(next_branches)
    }
    Match(node) => {
      let next_branches = []
      for branch in node.branches {
        next_branches.push({
          ..branch,
          element: bind_template_ref_element(branch.element, resolved_refs),
        })
      }
      Match({ expr: node.expr, branches: next_branches })
    }
  }
}

///|
fn bind_template_ref_element(
  element : TemplateElement,
  resolved_refs : Array[ResolvedTemplateRef],
) -> TemplateElement {
  let children = bind_template_ref_nodes(element.children, resolved_refs)
  let ref_binding_name = match element.ref_static_name {
    Some(name) => find_template_ref_binding_name(resolved_refs, name)
    None => None
  }
  { ..element, children, ref_binding_name }
}

///|
fn find_template_ref_binding_name(
  resolved_refs : Array[ResolvedTemplateRef],
  name : String,
) -> String? {
  for ref_ in resolved_refs {
    if ref_.binding_name is Some(binding_name) &&
      ref_.ref_name == Some(name) {
      return Some(binding_name)
    }
  }
  None
}

///|
fn validate_template_expr(
  expr : String,
  binding : String?,
  filename : String,
) -> Unit raise CompilerError {
  ignore(validate_template_expr_with_ast(expr, binding, filename))
}

///|
fn validate_template_expr_with_ast(
  expr : String,
  binding : String?,
  filename : String,
) -> @mbt_syntax.Expr raise CompilerError {
  let parsed = parse_template_expr_ast(expr, filename)
  match binding {
    Some(binding) =>
      if expr_contains_legacy_emit_call(parsed, binding) {
        raise CompilerError::InvalidTemplate(
          legacy_emit_message(binding, filename),
        )
      }
    None => ()
  }
  parsed
}

///|
fn legacy_emit_message(binding : String, filename : String) -> String {
  "legacy `\{binding}.emit(...` is not supported in \{filename}; use typed event calls like `\{binding}.save()`"
}

///|
fn script_setup_contains_legacy_emit_call(
  source : String,
  binding : String,
  filename : String,
) -> Bool {
  let (impls, reports) = @mbt_parser.parse_string(source, name=filename)
  if not(reports.is_empty()) {
    return false
  }
  for impl_ in impls {
    if impl_contains_legacy_emit_call(impl_, binding) {
      return true
    }
  }
  false
}

///|
fn parse_template_expr_ast(
  expr : String,
  filename : String,
) -> @mbt_syntax.Expr raise CompilerError {
  let wrapped = "let __vm_probe = " + expr
  let (impls, reports) = @mbt_parser.parse_string(
    wrapped,
    name=filename + "#template-expr",
  )
  if not(reports.is_empty()) {
    raise CompilerError::InvalidTemplate(
      invalid_template_expression_message(expr, filename, reports[0].msg),
    )
  }
  for impl_ in impls {
    match impl_ {
      TopLetDef(expr~, ..) => return expr
      _ => ()
    }
  }
  raise CompilerError::InvalidTemplate(
    invalid_template_expression_message(
      expr, filename, "failed to parse expression",
    ),
  )
}

///|
fn invalid_template_expression_message(
  expr : String,
  filename : String,
  message : String,
) -> String {
  "invalid template expression `\{expr.trim().to_string()}` in \{filename}: \{message}"
}

///|
fn validate_model_target_expr(
  expr : @mbt_syntax.Expr,
  source : String,
  tag : String,
) -> Unit raise CompilerError {
  if expr_is_assignable_model_target(expr) ||
    expr_is_signal_getter_model_target(expr) {
    return
  }
  raise CompilerError::InvalidDirective(
    "v-model requires an assignable target or signal getter on <\{tag}>: `\{source}`",
  )
}

///|
fn expr_is_assignable_model_target(expr : @mbt_syntax.Expr) -> Bool {
  let expr = unwrap_group_expr_local(expr)
  match expr {
    Ident(..) => true
    Field(record~, ..) => expr_is_assignable_model_target(record)
    ArrayGet(array~, ..) => expr_is_assignable_model_target(array)
    _ => false
  }
}

///|
fn expr_is_signal_getter_model_target(expr : @mbt_syntax.Expr) -> Bool {
  let expr = unwrap_group_expr_local(expr)
  match expr {
    Apply(func~, args~, ..) => is_field_getter_call_model_target(func, args)
    DotApply(self~, method_name~, args~, ..) => {
      ignore(self)
      method_name.name == "get" && argument_list_is_empty_model_target(args)
    }
    _ => false
  }
}

///|
fn is_field_getter_call_model_target(
  func : @mbt_syntax.Expr,
  args : @list.List[@mbt_syntax.Argument],
) -> Bool {
  if not(argument_list_is_empty_model_target(args)) {
    return false
  }
  let func = unwrap_group_expr_local(func)
  match func {
    Field(record~, accessor~, ..) => {
      ignore(record)
      accessor_label_name(accessor) == Some("get")
    }
    _ => false
  }
}

///|
fn argument_list_is_empty_model_target(
  args : @list.List[@mbt_syntax.Argument],
) -> Bool {
  match args {
    @list.Empty => true
    @list.More(_, ..) => false
  }
}

///|
fn impl_contains_legacy_emit_call(
  impl_ : @mbt_syntax.Impl,
  binding : String,
) -> Bool {
  match impl_ {
    TopExpr(expr~, ..) | TopTest(expr~, ..) | TopLetDef(expr~, ..) =>
      expr_contains_legacy_emit_call(expr, binding)
    TopFuncDef(decl_body~, ..) =>
      decl_body_contains_legacy_emit_call(decl_body, binding)
    TopImpl(body~, ..) => decl_body_contains_legacy_emit_call(body, binding)
    TopView(body~, ..) => expr_contains_legacy_emit_call(body, binding)
    TopTypeDef(_)
    | TopFuncAlias(..)
    | TopTrait(_)
    | TopBatchTypeAlias(..)
    | TopBatchTraitAlias(..)
    | TopImplRelation(..)
    | _ => false
  }
}

///|
fn decl_body_contains_legacy_emit_call(
  body : @mbt_syntax.DeclBody,
  binding : String,
) -> Bool {
  match body {
    DeclBody(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    DeclStubs(_) | DeclNone => false
  }
}

///|
fn expr_contains_legacy_emit_call(
  expr : @mbt_syntax.Expr,
  binding : String,
) -> Bool {
  let expr = unwrap_group_expr_local(expr)
  match expr {
    Apply(func~, args~, ..) =>
      is_legacy_emit_callee(func, binding) ||
      expr_contains_legacy_emit_call(func, binding) ||
      argument_list_contains_legacy_emit_call(args, binding)
    Infix(lhs~, rhs~, ..) =>
      expr_contains_legacy_emit_call(lhs, binding) ||
      expr_contains_legacy_emit_call(rhs, binding)
    Unary(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    Array(exprs~, ..) | Tuple(exprs~, ..) =>
      expr_list_contains_legacy_emit_call(exprs, binding)
    Continue(args~, ..) => expr_list_contains_legacy_emit_call(args, binding)
    ArraySpread(elems~, ..) =>
      spreadable_exprs_contain_legacy_emit_call(elems, binding)
    ArrayGet(array~, index~, ..) =>
      expr_contains_legacy_emit_call(array, binding) ||
      expr_contains_legacy_emit_call(index, binding)
    ArrayGetSlice(array~, start_index~, end_index~, ..) =>
      expr_contains_legacy_emit_call(array, binding) ||
      expr_option_contains_legacy_emit_call(start_index, binding) ||
      expr_option_contains_legacy_emit_call(end_index, binding)
    ArraySet(array~, index~, value~, ..) =>
      expr_contains_legacy_emit_call(array, binding) ||
      expr_contains_legacy_emit_call(index, binding) ||
      expr_contains_legacy_emit_call(value, binding)
    ArrayAugmentedSet(array~, index~, value~, ..) =>
      expr_contains_legacy_emit_call(array, binding) ||
      expr_contains_legacy_emit_call(index, binding) ||
      expr_contains_legacy_emit_call(value, binding)
    Constant(..) | Constr(..) | Ident(..) | Method(..) | Hole(..) | Unit(..) =>
      false
    MultilineString(elems~, ..) =>
      multiline_string_elems_contain_legacy_emit_call(elems, binding)
    Interp(elems~, ..) => interp_elems_contain_legacy_emit_call(elems, binding)
    Constraint(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    As(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    Assign(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    Raise(err_value~, ..) => expr_contains_legacy_emit_call(err_value, binding)
    TryOperator(body~, ..) => expr_contains_legacy_emit_call(body, binding)
    Group(expr~, ..) => expr_contains_legacy_emit_call(expr, binding)
    While(loop_cond~, loop_body~, while_else~, ..) =>
      expr_contains_legacy_emit_call(loop_cond, binding) ||
      expr_contains_legacy_emit_call(loop_body, binding) ||
      expr_option_contains_legacy_emit_call(while_else, binding)
    Function(func~, ..) => func_contains_legacy_emit_call(func, binding)
    If(cond~, ifso~, ifnot~, ..) =>
      expr_contains_legacy_emit_call(cond, binding) ||
      expr_contains_legacy_emit_call(ifso, binding) ||
      expr_option_contains_legacy_emit_call(ifnot, binding)
    Guard(cond~, otherwise~, body~, ..) =>
      expr_contains_legacy_emit_call(cond, binding) ||
      expr_option_contains_legacy_emit_call(otherwise, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    Is(expr~, ..) | IsLexMatch(expr~, ..) =>
      expr_contains_legacy_emit_call(expr, binding)
    Defer(expr~, body~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    Let(expr~, body~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    LetMut(expr~, body~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    Pipe(lhs~, rhs~, ..) =>
      expr_contains_legacy_emit_call(lhs, binding) ||
      expr_contains_legacy_emit_call(rhs, binding)
    LetFn(func~, body~, ..) =>
      func_contains_legacy_emit_call(func, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    LetRec(bindings~, body~, ..) =>
      function_binding_list_contains_legacy_emit_call(bindings, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    LetAnd(bindings~, body~, ..) =>
      typed_function_binding_list_contains_legacy_emit_call(bindings, binding) ||
      expr_contains_legacy_emit_call(body, binding)
    Sequence(exprs~, last_expr~, ..) =>
      expr_list_contains_legacy_emit_call(exprs, binding) ||
      expr_contains_legacy_emit_call(last_expr, binding)
    Record(fields~, ..) => field_defs_contain_legacy_emit_call(fields, binding)
    RecordUpdate(record~, fields~, ..) =>
      expr_contains_legacy_emit_call(record, binding) ||
      field_defs_contain_legacy_emit_call(fields, binding)
    Field(record~, ..) => expr_contains_legacy_emit_call(record, binding)
    DotApply(self~, method_name~, args~, ..) =>
      (is_binding_expr(self, binding) && method_name.name == "emit") ||
      expr_contains_legacy_emit_call(self, binding) ||
      argument_list_contains_legacy_emit_call(args, binding)
    Mutate(record~, field~, ..) =>
      expr_contains_legacy_emit_call(record, binding) ||
      expr_contains_legacy_emit_call(field, binding)
    Match(expr~, cases~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      case_list_contains_legacy_emit_call(cases, binding)
    LexMatch(expr~, cases~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      lex_case_list_contains_legacy_emit_call(cases, binding)
    Return(return_value~, ..) =>
      expr_option_contains_legacy_emit_call(return_value, binding)
    Break(arg~, ..) => expr_option_contains_legacy_emit_call(arg, binding)
    Loop(arg~, body~, ..) =>
      expr_contains_legacy_emit_call(arg, binding) ||
      case_list_contains_legacy_emit_call(body, binding)
    For(
      binders~,
      condition~,
      continue_block~,
      body~,
      for_else~,
      where_clause~,
      ..
    ) =>
      binder_expr_pairs_contain_legacy_emit_call(binders, binding) ||
      expr_option_contains_legacy_emit_call(condition, binding) ||
      binder_expr_pairs_contain_legacy_emit_call(continue_block, binding) ||
      expr_contains_legacy_emit_call(body, binding) ||
      expr_option_contains_legacy_emit_call(for_else, binding) ||
      where_clause_contains_legacy_emit_call(where_clause, binding)
    ForEach(expr~, body~, else_block~, ..) =>
      expr_contains_legacy_emit_call(expr, binding) ||
      expr_contains_legacy_emit_call(body, binding) ||
      expr_option_contains_legacy_emit_call(else_block, binding)
    Try(body~, catch_~, try_else~, ..) =>
      expr_contains_legacy_emit_call(body, binding) ||
      case_list_contains_legacy_emit_call(catch_, binding) ||
      case_list_option_contains_legacy_emit_call(try_else, binding)
    Map(elems~, ..) => map_expr_elems_contain_legacy_emit_call(elems, binding)
    StaticAssert(body~, ..) => expr_contains_legacy_emit_call(body, binding)
  }
}

///|
fn unwrap_group_expr_local(expr : @mbt_syntax.Expr) -> @mbt_syntax.Expr {
  match expr {
    Group(expr~, ..) => unwrap_group_expr_local(expr)
    _ => expr
  }
}

///|
fn is_legacy_emit_callee(func : @mbt_syntax.Expr, binding : String) -> Bool {
  let func = unwrap_group_expr_local(func)
  match func {
    Field(record~, accessor~, ..) =>
      is_binding_expr(record, binding) &&
      accessor_label_name(accessor) == Some("emit")
    _ => false
  }
}

///|
fn is_binding_expr(expr : @mbt_syntax.Expr, binding : String) -> Bool {
  let expr = unwrap_group_expr_local(expr)
  match expr {
    Ident(id~, ..) => long_ident_matches_binding(id.name, binding)
    _ => false
  }
}

///|
fn long_ident_matches_binding(
  ident : @mbt_syntax.LongIdent,
  binding : String,
) -> Bool {
  match ident {
    Ident(name~) => name == binding
    Dot(..) => false
  }
}

///|
fn accessor_label_name(accessor : @mbt_syntax.Accessor) -> String? {
  match accessor {
    Label(label) => Some(label.name)
    Index(..) | Newtype(..) => None
  }
}

///|
fn func_contains_legacy_emit_call(
  func : @mbt_syntax.Func,
  binding : String,
) -> Bool {
  expr_contains_legacy_emit_call(func.body, binding)
}

///|
fn expr_list_contains_legacy_emit_call(
  exprs : @list.List[@mbt_syntax.Expr],
  binding : String,
) -> Bool {
  for expr in exprs {
    if expr_contains_legacy_emit_call(expr, binding) {
      return true
    }
  }
  false
}

///|
fn expr_option_contains_legacy_emit_call(
  expr : @mbt_syntax.Expr?,
  binding : String,
) -> Bool {
  match expr {
    Some(expr) => expr_contains_legacy_emit_call(expr, binding)
    None => false
  }
}

///|
fn argument_list_contains_legacy_emit_call(
  args : @list.List[@mbt_syntax.Argument],
  binding : String,
) -> Bool {
  for arg in args {
    if expr_contains_legacy_emit_call(arg.value, binding) {
      return true
    }
  }
  false
}

///|
fn spreadable_exprs_contain_legacy_emit_call(
  elems : @list.List[@mbt_syntax.SpreadableElem],
  binding : String,
) -> Bool {
  for elem in elems {
    match elem {
      Regular(expr) | Spread(expr~, ..) =>
        if expr_contains_legacy_emit_call(expr, binding) {
          return true
        }
    }
  }
  false
}

///|
fn field_defs_contain_legacy_emit_call(
  fields : @list.List[@mbt_syntax.FieldDef],
  binding : String,
) -> Bool {
  for field in fields {
    if expr_contains_legacy_emit_call(field.expr, binding) {
      return true
    }
  }
  false
}

///|
fn case_list_contains_legacy_emit_call(
  cases : @list.List[@mbt_syntax.Case],
  binding : String,
) -> Bool {
  for case_ in cases {
    if expr_option_contains_legacy_emit_call(case_.guard_, binding) ||
      expr_contains_legacy_emit_call(case_.body, binding) {
      return true
    }
  }
  false
}

///|
fn case_list_option_contains_legacy_emit_call(
  cases : @list.List[@mbt_syntax.Case]?,
  binding : String,
) -> Bool {
  match cases {
    Some(cases) => case_list_contains_legacy_emit_call(cases, binding)
    None => false
  }
}

///|
fn lex_case_list_contains_legacy_emit_call(
  cases : @list.List[@mbt_syntax.LexCase],
  binding : String,
) -> Bool {
  for case_ in cases {
    if expr_contains_legacy_emit_call(case_.body, binding) {
      return true
    }
  }
  false
}

///|
fn binder_expr_pairs_contain_legacy_emit_call(
  bindings : @list.List[(@mbt_syntax.Binder, @mbt_syntax.Expr)],
  binding : String,
) -> Bool {
  for entry in bindings {
    if expr_contains_legacy_emit_call(entry.1, binding) {
      return true
    }
  }
  false
}

///|
fn function_binding_list_contains_legacy_emit_call(
  bindings : @list.List[(@mbt_syntax.Binder, @mbt_syntax.Func)],
  binding : String,
) -> Bool {
  for entry in bindings {
    if func_contains_legacy_emit_call(entry.1, binding) {
      return true
    }
  }
  false
}

///|
fn typed_function_binding_list_contains_legacy_emit_call(
  bindings : @list.List[
    (@mbt_syntax.Binder, @mbt_syntax.Type?, @mbt_syntax.Func),
  ],
  binding : String,
) -> Bool {
  for entry in bindings {
    if func_contains_legacy_emit_call(entry.2, binding) {
      return true
    }
  }
  false
}

///|
fn where_clause_contains_legacy_emit_call(
  clause : @mbt_syntax.WhereClause?,
  binding : String,
) -> Bool {
  match clause {
    Some(clause) => field_defs_contain_legacy_emit_call(clause.fields, binding)
    None => false
  }
}

///|
fn map_expr_elems_contain_legacy_emit_call(
  elems : @list.List[@mbt_syntax.MapExprElem],
  binding : String,
) -> Bool {
  for elem in elems {
    if expr_contains_legacy_emit_call(elem.expr, binding) {
      return true
    }
  }
  false
}

///|
fn interp_elems_contain_legacy_emit_call(
  elems : @list.List[@mbt_syntax.InterpElem],
  binding : String,
) -> Bool {
  for elem in elems {
    match elem {
      Expr(expr~, ..) =>
        if expr_contains_legacy_emit_call(expr, binding) {
          return true
        }
      Literal(..) | Source(_) => ()
    }
  }
  false
}

///|
fn multiline_string_elems_contain_legacy_emit_call(
  elems : @list.List[@mbt_syntax.MultilineStringElem],
  binding : String,
) -> Bool {
  for elem in elems {
    match elem {
      String(_) => ()
      Interp(interp_elems) =>
        if interp_elems_contain_legacy_emit_call(interp_elems, binding) {
          return true
        }
    }
  }
  false
}
