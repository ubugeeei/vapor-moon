///|
fn render_script_setup_module(
  ir : ScriptSetupModule,
  include_imports : Bool,
) -> String {
  let lines : Array[String] = []
  for statement in ir.statements {
    match statement {
      ImportStatement(entries) =>
        if include_imports {
          lines.push(render_import_statement(entries))
        }
      LetStatement(let_stmt) =>
        lines.push(
          let_stmt.declaration + " = " + render_script_setup_expr(let_stmt.expr),
        )
      ExpressionStatement(expr) => lines.push(render_script_setup_expr(expr))
      RawStatement(raw) => lines.push(raw)
    }
  }
  lines.join("\n")
}

///|
fn render_import_statement(entries : Array[String]) -> String {
  let sb = StringBuilder::new()
  sb.write_string("import {\n")
  for entry in entries {
    sb.write_string("  ")
    sb.write_string(entry)
    sb.write_string("\n")
  }
  sb.write_char('}')
  sb.to_string()
}

///|
fn render_script_setup_expr(expr : ScriptSetupExpression) -> String {
  match expr {
    RawExpr(source) => source
    MacroExpr(macro_) => macro_.name + "(" + macro_.args + ")"
  }
}
