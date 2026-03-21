///|
/// Extract compiler macros from `<script setup>` and lower only runtime-bound helpers.

///|
pub fn analyze_script_setup(
  source : String,
  filename : String,
) -> ScriptSetupInfo raise CompilerError {
  let ir = parse_script_setup_module(source, filename)
  let contract_types = collect_script_setup_contract_types(source, filename)
  let mut props_declaration : String? = None
  let mut props_binding : String? = None
  let mut emits_binding : String? = None
  let mut slots_binding : String? = None
  let mut props : Array[MacroField] = []
  let mut prop_defaults : Array[PropDefault] = []
  let mut emits : Array[MacroField] = []
  let mut slots : Array[MacroField] = []

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
                      let_stmt.annotation_name,
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
                      let_stmt.annotation_name,
                      contract_types,
                      filename,
                    )
                  }
                }
              "defineSlot" =>
                match slots_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineSlot() in \{filename}",
                    )
                  None => {
                    slots_binding = let_stmt.binding
                    slots = resolve_macro_fields(
                      macro_,
                      let_stmt.annotation_name,
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
              "defineSlot" =>
                if slots_binding is Some(_) || not(slots.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineSlot() in \{filename}",
                  )
                } else {
                  slots = resolve_macro_fields(
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
    props_declaration,
    props_binding,
    props,
    prop_defaults,
    emits_binding,
    emits,
    slots_binding,
    slots,
  }
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
              "@vm.use_id(component_name, " + use_id_index.to_string() + ")",
            ),
            use_id_index + 1,
          )
        "useTemplateRef" =>
          (RawExpr("@vm.use_template_ref(" + macro_.args + ")"), use_id_index)
        _ => (expr, use_id_index)
      }
  }
}

///|
fn is_interface_macro(name : String) -> Bool {
  name == "defineProps" || name == "defineEmits" || name == "defineSlot"
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
fn array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
