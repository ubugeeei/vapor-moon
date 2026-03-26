fn ScriptSetupSource::parse_module_with_contracts(
  self : ScriptSetupSource,
) -> (ScriptSetupModule, Array[ScriptSetupContractType]) raise CompilerError {
  let statements : Array[ScriptSetupStatement] = []
  let contracts : Array[ScriptSetupContractType] = []
  for chunk in self.split_top_level_statements() {
    if chunk.trim().is_empty() {
      continue
    }
    let trimmed = chunk.trim().to_string()
    let chunk_source = ScriptSetupSource::new(trimmed, self.filename)
    if chunk_source.is_import_statement() {
      for statement in chunk_source.expand_import_statement() {
        statements.push(statement)
      }
      continue
    }
    let (impls, reports) = @mbt_parser.parse_string(trimmed, name=self.filename)
    if not(reports.is_empty()) {
      raise CompilerError::InvalidScriptSetup(reports[0].to_string())
    }
    for impl_ in impls {
      match impl_ {
        TopTypeDef(type_decl) =>
          contracts.push(chunk_source.parse_contract_type_decl(type_decl))
        _ => ()
      }
      statements.push(chunk_source.statement_from_ast(impl_))
    }
  }
  ({ statements, }, contracts)
}
