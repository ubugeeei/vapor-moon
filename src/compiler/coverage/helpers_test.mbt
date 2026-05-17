///|
fn compile(
  source : String,
  filename? : String = "Component.mbtv",
) -> @compiler.CompileOutput raise @compiler.CompilerError {
  @support.compile(source, filename~)
}

///|
fn compile_snapshot(source : String, filename : String) -> String {
  @support.compile_snapshot(source, filename)
}

///|
fn compile_error(source : String, filename : String) -> String {
  @support.compile_error(source, filename)
}

///|
fn basic_source() -> String {
  @support.basic_source()
}
