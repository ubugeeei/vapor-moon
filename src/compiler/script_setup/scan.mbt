///|
fn parse_script_setup_module(
  source : String,
  filename : String,
) -> ScriptSetupModule raise CompilerError {
  let statements : Array[ScriptSetupStatement] = []
  for chunk in split_top_level_statements(source) {
    let trimmed = chunk.trim().to_string()
    if trimmed.length() == 0 {
      continue
    }
    if trimmed.has_prefix("import") {
      for statement in expand_import_statement(trimmed, filename) {
        statements.push(statement)
      }
      continue
    }
    for statement in parse_script_setup_chunk_ast(trimmed, filename) {
      statements.push(statement)
    }
  }
  { statements, }
}
