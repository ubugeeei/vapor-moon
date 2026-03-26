///|
/// Extract compiler macros from `<script setup>` and lower only runtime-bound helpers.

///|
pub fn analyze_script_setup(
  source : String,
  filename : String,
) -> ScriptSetupInfo raise CompilerError {
  let (ir, contract_types) = parse_script_setup_module_with_contracts(
    source, filename,
  )
  let template_refs = collect_script_setup_template_refs(ir)
  let mut props_declaration : String? = None
  let mut props_binding : String? = None
  let mut emits_binding : String? = None
  let mut slots_binding : String? = None
  let mut expose_binding : String? = None
  let mut props : Array[MacroField] = []
  let mut prop_defaults : Array[PropDefault] = []
  let mut emits : Array[MacroField] = []
  let mut slots : Array[MacroField] = []
  let mut expose : Array[MacroField] = []

  for statement in ir.statements {
    match statement {
      LetStatement(let_stmt) =>
        match let_stmt.expr {
          MacroExpr(macro_) =>
            match macro_.name {
              "defineProps" =>
                match props_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineProps() in \{filename}",
                    )
                  None => {
                    props_declaration = Some(let_stmt.declaration)
                    props_binding = let_stmt.binding
                    props = resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                      contract_types,
                      filename,
                    )
                    prop_defaults = resolve_prop_defaults(
                      macro_,
                      props,
                      Some(let_stmt.declaration),
                      filename,
                    )
                  }
                }
              "defineEmits" =>
                match emits_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineEmits() in \{filename}",
                    )
                  None => {
                    emits_binding = let_stmt.binding
                    emits = resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                      contract_types,
                      filename,
                    )
                  }
                }
              "defineSlots" =>
                match slots_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineSlots() in \{filename}",
                    )
                  None => {
                    slots_binding = let_stmt.binding
                    slots = resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                      contract_types,
                      filename,
                    )
                  }
                }
              "defineExpose" =>
                match expose_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineExpose() in \{filename}",
                    )
                  None => {
                    expose_binding = let_stmt.binding
                    expose = resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                      contract_types,
                      filename,
                    )
                  }
                }
              _ => ()
            }
          _ => ()
        }
      ExpressionStatement(expr) =>
        match expr {
          MacroExpr(macro_) =>
            match macro_.name {
              "defineProps" =>
                if props_binding is Some(_) || not(props.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineProps() in \{filename}",
                  )
                } else {
                  props = resolve_macro_fields(
                    macro_,
                    None,
                    contract_types,
                    filename,
                  )
                  prop_defaults = resolve_prop_defaults(
                    macro_,
                    props,
                    None,
                    filename,
                  )
                }
              "defineEmits" =>
                if emits_binding is Some(_) || not(emits.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineEmits() in \{filename}",
                  )
                } else {
                  emits = resolve_macro_fields(
                    macro_,
                    None,
                    contract_types,
                    filename,
                  )
                }
              "defineSlots" =>
                if slots_binding is Some(_) || not(slots.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineSlots() in \{filename}",
                  )
                } else {
                  slots = resolve_macro_fields(
                    macro_,
                    None,
                    contract_types,
                    filename,
                  )
                }
              "defineExpose" =>
                if expose_binding is Some(_) || not(expose.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineExpose() in \{filename}",
                  )
                } else {
                  expose = resolve_macro_fields(
                    macro_,
                    None,
                    contract_types,
                    filename,
                  )
                }
              _ => ()
            }
          _ => ()
        }
      _ => ()
    }
  }

  let lowered = lower_script_setup_module(ir)

  {
    source: render_script_setup_module(ir, false),
    transformed: render_script_setup_module(lowered, false),
    import_entries: collect_script_setup_import_entries(ir),
    template_refs,
    props_declaration,
    props_binding,
    props,
    prop_defaults,
    emits_binding,
    emits,
    slots_binding,
    slots,
    expose_binding,
    expose,
  }
}

///|
pub fn analyze_script_extern(
  source : String,
  filename : String,
) -> ScriptExternInfo raise CompilerError {
  let (ir, _) = parse_script_setup_module_with_contracts(source, filename)
  validate_script_extern_module(ir, filename)
  let transformed = render_script_setup_module(ir, false)
  {
    source: transformed,
    transformed,
    import_entries: collect_script_setup_import_entries(ir),
  }
}

///|
fn validate_script_extern_module(
  ir : ScriptSetupModule,
  filename : String,
) -> Unit raise CompilerError {
  for statement in ir.statements {
    match statement {
      LetStatement(let_stmt) =>
        validate_script_extern_expr(let_stmt.expr, filename)
      ExpressionStatement(expr) => validate_script_extern_expr(expr, filename)
      ImportStatement(_) | RawStatement(_) => ()
    }
  }
}

///|
fn validate_script_extern_expr(
  expr : ScriptSetupExpression,
  filename : String,
) -> Unit raise CompilerError {
  match expr {
    MacroExpr(macro_) =>
      match macro_.name {
        "defineProps"
        | "defineEmits"
        | "defineSlots"
        | "defineExpose"
        | "useId"
        | "useTemplateRef" =>
          raise CompilerError::InvalidScriptExtern(
            script_extern_setup_only_message(macro_.name, filename),
          )
        _ => ()
      }
    RawExpr(_) => ()
  }
}

///|
fn script_extern_setup_only_message(name : String, filename : String) -> String {
  "`" +
  name +
  "()` is only supported in <script> setup scope in " +
  filename +
  "; move it from <script extern> to <script>"
}

///|
fn lower_script_setup_module(ir : ScriptSetupModule) -> ScriptSetupModule {
  let statements : Array[ScriptSetupStatement] = []
  let mut use_id_index = 0
  for statement in ir.statements {
    match statement {
      ImportStatement(_) => ()
      LetStatement(let_stmt) =>
        match let_stmt.expr {
          MacroExpr(macro_) if is_interface_macro(macro_.name) => ()
          _ => {
            let (expr, next_index) = lower_script_setup_expr(
              let_stmt.expr,
              use_id_index,
            )
            use_id_index = next_index
            statements.push(LetStatement({ ..let_stmt, expr, }))
          }
        }
      ExpressionStatement(expr) =>
        match expr {
          MacroExpr(macro_) if is_interface_macro(macro_.name) => ()
          _ => {
            let (lowered, next_index) = lower_script_setup_expr(
              expr, use_id_index,
            )
            use_id_index = next_index
            statements.push(ExpressionStatement(lowered))
          }
        }
      RawStatement(raw) => statements.push(RawStatement(raw))
    }
  }
  { statements, }
}

///|
fn lower_script_setup_expr(
  expr : ScriptSetupExpression,
  use_id_index : Int,
) -> (ScriptSetupExpression, Int) {
  match expr {
    RawExpr(_) => (expr, use_id_index)
    MacroExpr(macro_) =>
      match macro_.name {
        "useId" =>
          (
            RawExpr(
              "@hlp.use_id(component_name, " + use_id_index.to_string() + ")",
            ),
            use_id_index + 1,
          )
        "useTemplateRef" =>
          (RawExpr("@hlp.use_template_ref(" + macro_.args + ")"), use_id_index)
        _ => (expr, use_id_index)
      }
  }
}

///|
fn is_interface_macro(name : String) -> Bool {
  name == "defineProps" ||
  name == "defineEmits" ||
  name == "defineSlots" ||
  name == "defineExpose"
}

///|
fn collect_script_setup_import_entries(ir : ScriptSetupModule) -> Array[String] {
  let entries : Array[String] = []
  for statement in ir.statements {
    match statement {
      ImportStatement(parts) =>
        for entry in parts {
          if not(array_contains(entries, entry)) {
            entries.push(entry)
          }
        }
      _ => ()
    }
  }
  entries
}

///|
fn collect_script_setup_template_refs(
  ir : ScriptSetupModule,
) -> Array[ScriptSetupTemplateRef] {
  let refs : Array[ScriptSetupTemplateRef] = []
  for statement in ir.statements {
    match statement {
      LetStatement(let_stmt) =>
        collect_template_ref_expr(let_stmt.binding, let_stmt.expr, refs)
      ExpressionStatement(expr) => collect_template_ref_expr(None, expr, refs)
      ImportStatement(_) | RawStatement(_) => ()
    }
  }
  refs
}

///|
fn collect_template_ref_expr(
  binding_name : String?,
  expr : ScriptSetupExpression,
  refs : Array[ScriptSetupTemplateRef],
) -> Unit {
  match expr {
    MacroExpr(macro_) if macro_.name == "useTemplateRef" =>
      refs.push({
        binding_name,
        arg_source: macro_.args,
        ref_name: macro_.static_string_arg,
      })
    _ => ()
  }
}

///|
fn array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
