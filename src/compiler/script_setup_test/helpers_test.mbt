///|
fn compile(
  source : String,
  filename? : String = "Component.mbtv",
) -> @compiler.CompileOutput raise @compiler.CompilerError {
  @support.compile(source, filename~)
}

///|
fn compile_error(source : String, filename : String) -> String {
  @support.compile_error(source, filename)
}

///|
fn parse_sfc(
  source : String,
  filename? : String = "Component.mbtv",
) -> @compiler.SfcDocument raise @compiler.CompilerError {
  @support.parse_sfc(source, filename~)
}

///|
fn analyze_script_setup(
  source : String,
  filename : String,
) -> @compiler.ScriptSetupInfo raise @compiler.CompilerError {
  @support.analyze_script_setup(source, filename)
}

///|
fn generic_source() -> String {
  @support.generic_source()
}
