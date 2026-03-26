///|
fn ScriptSetupSource::is_import_statement(self : ScriptSetupSource) -> Bool {
  if not(self.source.has_prefix("import")) {
    return false
  }
  if self.chars.length() == 6 {
    return true
  }
  let next = self.skip_inline_gap(6)
  next >= self.chars.length() || self.chars[next] == '{'
}

///|
fn ScriptSetupSource::expand_import_statement(
  self : ScriptSetupSource,
) -> Array[ScriptSetupStatement] raise CompilerError {
  let statements : Array[ScriptSetupStatement] = []
  let import_entries : Array[String] = []
  let local_aliases : Array[String] = []
  for entry in self.parse_import_statement() {
    if entry.has_prefix("\"") {
      import_entries.push(entry)
    } else {
      local_aliases.push(entry)
    }
  }
  if not(import_entries.is_empty()) {
    statements.push(ImportStatement(import_entries))
  }
  for local_binding in local_aliases {
    if local_binding.has_prefix("let ") {
      statements.push(RawStatement(local_binding))
    } else {
      statements.push(RawStatement("let " + local_binding))
    }
  }
  statements
}

///|
fn ScriptSetupSource::parse_import_statement(
  self : ScriptSetupSource,
) -> Array[String] raise CompilerError {
  let open_brace = self.skip_inline_gap(6)
  if open_brace >= self.chars.length() || self.chars[open_brace] != '{' {
    raise CompilerError::InvalidScriptSetup(
      "script setup imports must use `import { ... }` in \{self.filename}",
    )
  }
  let close_brace = self.find_matching_delimiter(
    open_brace,
    '{',
    '}',
    "import block",
  )
  let trailing_start = self.skip_inline_gap(close_brace + 1)
  if trailing_start < self.chars.length() {
    raise CompilerError::InvalidScriptSetup(
      "script setup imports must end after `}` in \{self.filename}",
    )
  }
  let body = String::unsafe_substring(
    self.source,
    start=open_brace + 1,
    end=close_brace,
  )
  let entries : Array[String] = []
  for line in ScriptSetupSource::new(body, self.filename).split_top_level(',') {
    let trimmed = line.trim().to_string()
    if trimmed.is_empty() {
      continue
    }
    let entry = if trimmed.has_suffix(",") { trimmed } else { trimmed + "," }
    entries.push(entry)
  }
  entries
}
