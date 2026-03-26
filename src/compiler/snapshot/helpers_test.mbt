///|
fn assert_snapshot(actual : String, expected : String) -> Unit raise {
  @support.assert_snapshot(actual, expected)
}

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

///|
fn macros_source() -> String {
  @support.macros_source()
}

///|
fn slots_source() -> String {
  @support.slots_source()
}

///|
fn generic_source() -> String {
  @support.generic_source()
}

///|
fn island_visible_source() -> String {
  @support.island_visible_source()
}

///|
fn directives_source() -> String {
  @support.directives_source()
}

///|
fn media_and_defer_source() -> String {
  @support.media_and_defer_source()
}

///|
fn reactivity_basics_source() -> String {
  @support.reactivity_basics_source()
}

///|
fn lifecycle_refs_source() -> String {
  @support.lifecycle_refs_source()
}

///|
fn composable_counter_source() -> String {
  @support.composable_counter_source()
}
