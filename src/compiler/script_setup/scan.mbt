///|
fn parse_script_setup_module_with_contracts(
  source : String,
  filename : String,
) -> (ScriptSetupModule, Array[ScriptSetupContractType]) raise CompilerError {
  let statements : Array[ScriptSetupStatement] = []
  let contracts : Array[ScriptSetupContractType] = []
  for chunk in split_top_level_statements(source) {
    let trimmed = chunk.trim().to_string()
    if trimmed.length() == 0 {
      continue
    }
    if is_script_setup_import_statement(trimmed) {
      for statement in expand_import_statement(trimmed, filename) {
        statements.push(statement)
      }
      continue
    }
    let (impls, reports) = @mbt_parser.parse_string(trimmed, name=filename)
    if not(reports.is_empty()) {
      raise CompilerError::InvalidScriptSetup(reports[0].to_string())
    }
    for impl_ in impls {
      match impl_ {
        TopTypeDef(type_decl) =>
          contracts.push(parse_contract_type_decl(trimmed, type_decl))
        _ => ()
      }
      statements.push(script_setup_statement_from_ast(trimmed, impl_, filename))
    }
  }
  ({ statements, }, contracts)
}

