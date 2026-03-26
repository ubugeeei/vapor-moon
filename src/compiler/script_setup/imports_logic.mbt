///|
fn is_script_setup_import_statement(source : String) -> Bool {
  if not(source.has_prefix("import")) {
    return false
  }
  let chars = source.to_array()
  if chars.length() == 6 {
    return true
  }
  let next = skip_inline_gap(source, chars, 6)
  next >= chars.length() || chars[next] == '{'
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
  let open_brace = skip_inline_gap(source, chars, 6)
  if open_brace >= chars.length() || chars[open_brace] != '{' {
    raise CompilerError::InvalidScriptSetup(
      "script setup imports must use `import { ... }` in \{filename}",
    )
  }
  let close_brace = find_matching_delimiter(
    source, chars, open_brace, '{', '}', filename, "import block",
  )
  let trailing_start = skip_inline_gap(source, chars, close_brace + 1)
  if trailing_start < chars.length() {
    raise CompilerError::InvalidScriptSetup(
      "script setup imports must end after `}` in \{filename}",
    )
  }
  let body = String::unsafe_substring(
    source,
    start=open_brace + 1,
    end=close_brace,
  )
  let entries : Array[String] = []
  for line in split_top_level(body, ',') {
    let trimmed = line.trim().to_string()
    if trimmed.is_empty() {
      continue
    }
    let entry = if trimmed.has_suffix(",") { trimmed } else { trimmed + "," }
    entries.push(entry)
  }
  entries
}
