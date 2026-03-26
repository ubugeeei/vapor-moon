///|
/// Extract compiler macros from `<script setup>` and lower only runtime-bound helpers.

///|
priv struct ScriptSetupContractAnalysis {
  props_declaration : String?
  props_binding : String?
  props : Array[MacroField]
  prop_defaults : Array[PropDefault]
  emits_binding : String?
  emits : Array[MacroField]
  slots_binding : String?
  slots : Array[MacroField]
  expose_binding : String?
  expose : Array[MacroField]
}

///|
pub fn analyze_script_setup(
  source : String,
  filename : String,
) -> ScriptSetupInfo raise CompilerError {
  let source = ScriptSetupSource::new(source, filename)
  let (ir, contract_types) = source.parse_module_with_contracts()
  let resolver = ScriptSetupContractResolver::new(filename, contract_types)
  let contracts = ir.analyze_contracts(resolver)
  let lowered = ir.lowered()
  {
    source: ir.render(false),
    transformed: lowered.render(false),
    import_entries: ir.import_entries(),
    template_refs: ir.template_refs(),
    props_declaration: contracts.props_declaration,
    props_binding: contracts.props_binding,
    props: contracts.props,
    prop_defaults: contracts.prop_defaults,
    emits_binding: contracts.emits_binding,
    emits: contracts.emits,
    slots_binding: contracts.slots_binding,
    slots: contracts.slots,
    expose_binding: contracts.expose_binding,
    expose: contracts.expose,
  }
}

///|
pub fn analyze_script_extern(
  source : String,
  filename : String,
) -> ScriptExternInfo raise CompilerError {
  let source = ScriptSetupSource::new(source, filename)
  let (ir, _) = source.parse_module_with_contracts()
  ir.validate_script_extern(filename)
  let transformed = ir.render(false)
  {
    source: transformed,
    transformed,
    import_entries: ir.import_entries(),
  }
}

///|
fn ScriptSetupModule::analyze_contracts(
  self : ScriptSetupModule,
  resolver : ScriptSetupContractResolver,
) -> ScriptSetupContractAnalysis raise CompilerError {
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

  for statement in self.statements {
    match statement {
      LetStatement(let_stmt) =>
        match let_stmt.expr {
          MacroExpr(macro_) =>
            match macro_.name {
              "defineProps" =>
                match props_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineProps() in \{resolver.filename}",
                    )
                  None => {
                    props_declaration = Some(let_stmt.declaration)
                    props_binding = let_stmt.binding
                    props = resolver.resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                    )
                    prop_defaults = resolver.resolve_prop_defaults(
                      macro_,
                      props,
                      Some(let_stmt.declaration),
                    )
                  }
                }
              "defineEmits" =>
                match emits_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineEmits() in \{resolver.filename}",
                    )
                  None => {
                    emits_binding = let_stmt.binding
                    emits = resolver.resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                    )
                  }
                }
              "defineSlots" =>
                match slots_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineSlots() in \{resolver.filename}",
                    )
                  None => {
                    slots_binding = let_stmt.binding
                    slots = resolver.resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
                    )
                  }
                }
              "defineExpose" =>
                match expose_binding {
                  Some(_) =>
                    raise CompilerError::InvalidScriptSetup(
                      "duplicate defineExpose() in \{resolver.filename}",
                    )
                  None => {
                    expose_binding = let_stmt.binding
                    expose = resolver.resolve_macro_fields(
                      macro_,
                      let_stmt.annotation,
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
                    "duplicate defineProps() in \{resolver.filename}",
                  )
                } else {
                  props = resolver.resolve_macro_fields(macro_, None)
                  prop_defaults = resolver.resolve_prop_defaults(
                    macro_,
                    props,
                    None,
                  )
                }
              "defineEmits" =>
                if emits_binding is Some(_) || not(emits.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineEmits() in \{resolver.filename}",
                  )
                } else {
                  emits = resolver.resolve_macro_fields(macro_, None)
                }
              "defineSlots" =>
                if slots_binding is Some(_) || not(slots.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineSlots() in \{resolver.filename}",
                  )
                } else {
                  slots = resolver.resolve_macro_fields(macro_, None)
                }
              "defineExpose" =>
                if expose_binding is Some(_) || not(expose.is_empty()) {
                  raise CompilerError::InvalidScriptSetup(
                    "duplicate defineExpose() in \{resolver.filename}",
                  )
                } else {
                  expose = resolver.resolve_macro_fields(macro_, None)
                }
              _ => ()
            }
          _ => ()
        }
      _ => ()
    }
  }

  {
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
fn ScriptSetupModule::validate_script_extern(
  self : ScriptSetupModule,
  filename : String,
) -> Unit raise CompilerError {
  for statement in self.statements {
    match statement {
      LetStatement(let_stmt) => let_stmt.expr.validate_script_extern(filename)
      ExpressionStatement(expr) => expr.validate_script_extern(filename)
      ImportStatement(_) | RawStatement(_) => ()
    }
  }
}

///|
fn ScriptSetupExpression::validate_script_extern(
  self : ScriptSetupExpression,
  filename : String,
) -> Unit raise CompilerError {
  match self {
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
fn ScriptSetupModule::lowered(self : ScriptSetupModule) -> ScriptSetupModule {
  let statements : Array[ScriptSetupStatement] = []
  let mut use_id_index = 0
  for statement in self.statements {
    match statement {
      ImportStatement(_) => ()
      LetStatement(let_stmt) =>
        match let_stmt.expr {
          MacroExpr(macro_) if is_interface_macro(macro_.name) => ()
          _ => {
            let (expr, next_index) = let_stmt.expr.lower(use_id_index)
            use_id_index = next_index
            statements.push(LetStatement({ ..let_stmt, expr, }))
          }
        }
      ExpressionStatement(expr) =>
        match expr {
          MacroExpr(macro_) if is_interface_macro(macro_.name) => ()
          _ => {
            let (lowered, next_index) = expr.lower(use_id_index)
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
fn ScriptSetupExpression::lower(
  self : ScriptSetupExpression,
  use_id_index : Int,
) -> (ScriptSetupExpression, Int) {
  match self {
    RawExpr(_) => (self, use_id_index)
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
        _ => (self, use_id_index)
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
fn ScriptSetupModule::import_entries(self : ScriptSetupModule) -> Array[String] {
  let entries : Array[String] = []
  for statement in self.statements {
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
fn ScriptSetupModule::template_refs(
  self : ScriptSetupModule,
) -> Array[ScriptSetupTemplateRef] {
  let refs : Array[ScriptSetupTemplateRef] = []
  for statement in self.statements {
    match statement {
      LetStatement(let_stmt) =>
        let_stmt.expr.collect_template_refs(let_stmt.binding, refs)
      ExpressionStatement(expr) => expr.collect_template_refs(None, refs)
      ImportStatement(_) | RawStatement(_) => ()
    }
  }
  refs
}

///|
fn ScriptSetupExpression::collect_template_refs(
  self : ScriptSetupExpression,
  binding_name : String?,
  refs : Array[ScriptSetupTemplateRef],
) -> Unit {
  match self {
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
