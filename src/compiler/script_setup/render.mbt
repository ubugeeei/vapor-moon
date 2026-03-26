///|
fn ScriptSetupModule::render(
  self : ScriptSetupModule,
  include_imports : Bool,
) -> String {
  let lines : Array[String] = []
  for statement in self.statements {
    match statement {
      ImportStatement(entries) =>
        if include_imports {
          lines.push(render_import_statement(entries))
        }
      LetStatement(let_stmt) =>
        lines.push(
          let_stmt.declaration + " = " + let_stmt.expr.render(),
        )
      ExpressionStatement(expr) => lines.push(expr.render())
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
fn ScriptSetupExpression::render(self : ScriptSetupExpression) -> String {
  match self {
    RawExpr(source) => source
    MacroExpr(macro_) => macro_.name + "(" + macro_.args + ")"
  }
}
