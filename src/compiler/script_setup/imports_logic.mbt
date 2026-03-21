///|
fn is_script_setup_import_statement(source : String) -> Bool {
  if not(source.has_prefix("import")) {
    return false
  }
  if source.length() == 6 {
    return true
  }
  let next = source.to_array()[6]
  next == ' ' || next == '\n' || next == '\t' || next == '\r' || next == '{'
}

///|
fn expand_import_statement(
  source : String,
  filename : String,
) -> Array[ScriptSetupStatement] raise CompilerError {
  let statements : Array[ScriptSetupStatement] = []
  let import_entries : Array[String] = []
  let local_aliases : Array[String] = []
  for entry in parse_import_statement(source, filename) {
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
fn parse_import_statement(
  source : String,
  filename : String,
) -> Array[String] raise CompilerError {
  let chars = source.to_array()
  let open_brace = skip_inline_ws(chars, 6)
  if open_brace >= chars.length() || chars[open_brace] != '{' {
    raise CompilerError::InvalidScriptSetup(
      "script setup imports must use `import { ... }` in \{filename}",
    )
  }
  let close_brace = find_matching_delimiter(
    source, chars, open_brace, '{', '}', filename, "import block",
  )
  let body = String::unsafe_substring(
    source,
    start=open_brace + 1,
    end=close_brace,
  )
  let entries : Array[String] = []
  for line in split_top_level(body, ',') {
    let trimmed = line.trim().to_string()
    if trimmed.length() == 0 {
      continue
    }
    let entry = if trimmed.has_suffix(",") { trimmed } else { trimmed + "," }
    entries.push(entry)
  }
  entries
}
