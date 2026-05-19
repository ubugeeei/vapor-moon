///|
/// Minimal CLI for Vapor Moon compiler and tooling.

///|
pub(all) struct GeneratedOutputPaths {
  client : String
  server : String
  css : String
}

///|
extern "c" fn watch_sleep_micros(microseconds : UInt64) -> Int = "usleep"

///|
/// Dispatch the small CLI surface used for local compiler and tooling experiments.
pub fn run(args : Array[String]) -> Unit {
  if args.length() < 2 {
    exit_usage()
    return
  }
  match args[1] {
    "--help" | "-h" | "help" => {
      print_help()
      return
    }
    "--version" | "-V" => {
      println("vapor-moon " + @compiler_common.VERSION)
      return
    }
    _ => ()
  }
  // `doctor` is the one subcommand that does not take a file argument.
  // Handle it before the < 3 args guard so users can invoke it bare.
  if args[1] == "doctor" {
    run_doctor()
    return
  }
  // `new` takes a component name and optional `--force` flag; route it
  // before the generic < 3 args check so the usage message is correct.
  if args[1] == "new" {
    run_new(args[2:])
    return
  }
  if args.length() < 3 {
    exit_usage()
    return
  }
  let command = args[1]
  let path = args[2]
  match command {
    "watch" => watch_directory(path)
    "compile" => {
      let source = read_text_or_exit(path)
      let output = @compiler.compile(source, filename=path) catch {
        err => {
          println(err.to_string())
          @sys.exit(1)
          return
        }
      }
      println(output.snapshot())
    }
    "analyze" => {
      let source = read_text_or_exit(path)
      let analysis = @tooling.analyze(source, filename=path)
      println(analysis.to_string())
    }
    "diagnostics" => {
      let source = read_text_or_exit(path)
      println(@tooling.diagnostics(source, filename=path).to_string())
    }
    "check" => {
      // Pass/fail gate for CI and pre-commit hooks: silent on success,
      // exit 1 with one diagnostic line per file otherwise. Accepts one
      // or more file paths (everything from args[2] onward).
      let paths = args[2:]
      let mut had_error = false
      for p in paths {
        let source = read_text_or_exit(p)
        let diagnostics = @tooling.diagnostics(source, filename=p)
        if diagnostics.length() > 0 {
          had_error = true
          for d in diagnostics {
            // `file:line:col [severity] message` — line/character in
            // ToolingDiagnostic are zero-based (LSP), shift to one-based
            // for human / editor parity.
            let line = d.location.range.start.line + 1
            let col = d.location.range.start.character + 1
            println(
              p +
              ":" +
              line.to_string() +
              ":" +
              col.to_string() +
              " [" +
              d.severity +
              "] " +
              d.message,
            )
          }
        }
      }
      if had_error {
        @sys.exit(1)
      }
    }
    "hover" =>
      if args.length() < 5 {
        exit_usage()
      } else {
        let source = read_text_or_exit(path)
        println(query_hover(source, path, args[3], args[4]))
      }
    "definition" =>
      if args.length() < 5 {
        exit_usage()
      } else {
        let source = read_text_or_exit(path)
        println(query_definition(source, path, args[3], args[4]))
      }
    "references" =>
      if args.length() < 5 {
        exit_usage()
      } else {
        let source = read_text_or_exit(path)
        let include_declaration = if args.length() >= 6 {
          parse_cli_bool(args[5])
        } else {
          true
        }
        println(
          query_references(source, path, args[3], args[4], include_declaration),
        )
      }
    "complete" =>
      if args.length() < 5 {
        exit_usage()
      } else {
        let source = read_text_or_exit(path)
        println(query_completion(source, path, args[3], args[4]))
      }
    "format" => {
      let source = read_text_or_exit(path)
      println(query_format(source, path))
    }
    _ => exit_usage()
  }
}

///|
/// Read a UTF-8 source file, exiting nonzero when automation cannot trust input.
fn read_text_or_exit(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path) catch {
    err => {
      println("failed to read " + path + ": " + err.to_string())
      @sys.exit(1)
      return ""
    }
  }
  @utf8.decode_lossy(bytes[:])
}

///|
/// Watch a directory tree, recompiling `.mbtv` files on change and writing generated outputs.
fn watch_directory(root : String) -> Unit {
  let root_dir : @path.Path = root
  let resolved_root = root_dir.resolve().to_string()
  if !@fs.path_exists(resolved_root) {
    println("watch root does not exist: " + resolved_root)
    @sys.exit(1)
    return
  }
  let is_dir = @fs.is_dir(resolved_root) catch {
    err => {
      println(err.to_string())
      @sys.exit(1)
      return
    }
  }
  if !is_dir {
    println("watch root is not a directory: " + resolved_root)
    @sys.exit(1)
    return
  }
  println("watching " + resolved_root)
  let compiler = @incremental.IncrementalCompiler::new()
  let known_sources : Array[(String, String)] = []
  let initial_sources = collect_watch_sources(resolved_root) catch {
    err => {
      println(err.to_string())
      @sys.exit(1)
      return
    }
  }
  if initial_sources.is_empty() {
    println("no .mbtv files found")
  }
  sync_watch_sources(
    compiler, resolved_root, known_sources, initial_sources, true,
  )
  while true {
    sleep_watch_interval()
    let next_sources = collect_watch_sources(resolved_root) catch {
      err => {
        println("watch scan failed: " + err.to_string())
        continue
      }
    }
    sync_watch_sources(
      compiler, resolved_root, known_sources, next_sources, false,
    )
  }
}

///|
/// Polling delay between directory scans.
fn sleep_watch_interval() -> Unit {
  let _ = watch_sleep_micros(500_000UL)
}

///|
/// Synchronize the watcher state with the latest recursive scan.
fn sync_watch_sources(
  compiler : @incremental.IncrementalCompiler,
  root_dir : String,
  known_sources : Array[(String, String)],
  current_sources : Array[String],
  initial : Bool,
) -> Unit {
  let seen : Array[String] = []
  for source_path in current_sources {
    seen.push(source_path)
    let source = @fs.read_file_to_string(source_path, encoding="utf8") catch {
      err => {
        println(
          "[error] failed to read " +
          render_watch_label(root_dir, source_path) +
          ": " +
          err.to_string(),
        )
        continue
      }
    }
    match lookup_known_source(known_sources, source_path) {
      Some(previous) =>
        if previous != source {
          store_known_source(known_sources, source_path, source)
          compile_watched_source(
            compiler, root_dir, source_path, source, "changed",
          )
        }
      None => {
        store_known_source(known_sources, source_path, source)
        compile_watched_source(
          compiler,
          root_dir,
          source_path,
          source,
          if initial {
            "init"
          } else {
            "added"
          },
        )
      }
    }
  }
  let mut index = 0
  while index < known_sources.length() {
    let source_path = known_sources[index].0
    if contains_string(seen, source_path) {
      index += 1
      continue
    }
    remove_generated_outputs(source_path)
    println("[removed] " + render_watch_label(root_dir, source_path))
    remove_known_source(known_sources, source_path)
  }
}

///|
/// Compile a watched source and persist its generated outputs beside the source file.
fn compile_watched_source(
  compiler : @incremental.IncrementalCompiler,
  root_dir : String,
  source_path : String,
  source : String,
  change_kind : String,
) -> Unit {
  compiler.set_source(source_path, source) |> ignore
  let output = compiler.compile(source_path) catch {
    err => {
      remove_generated_outputs(source_path)
      println(
        "[error] " +
        change_kind +
        " " +
        render_watch_label(root_dir, source_path) +
        ": " +
        err.to_string(),
      )
      return
    }
  }
  let generated = generated_output_paths(source_path)
  write_compile_outputs(source_path, output) catch {
    err => {
      remove_generated_outputs(source_path)
      println(
        "[error] failed to write " +
        render_watch_label(root_dir, source_path) +
        ": " +
        err.to_string(),
      )
      return
    }
  }
  println(
    "[" +
    change_kind +
    "] " +
    render_watch_label(root_dir, source_path) +
    " -> " +
    render_watch_label(root_dir, generated.client) +
    ", " +
    render_watch_label(root_dir, generated.server) +
    ", " +
    render_watch_label(root_dir, generated.css),
  )
}

///|
/// Recursively collect `.mbtv` source files from a directory tree.
pub fn collect_watch_sources(root : String) -> Array[String] raise @fs.IOError {
  let sources : Array[String] = []
  collect_watch_sources_into(root, sources)
  sources
}

///|
/// Depth-first recursive helper for collecting watched source files.
fn collect_watch_sources_into(
  path : String,
  sources : Array[String],
) -> Unit raise @fs.IOError {
  if @fs.is_dir(path) {
    for entry in @fs.read_dir(path) {
      collect_watch_sources_into(join_path(path, entry), sources)
    }
    return
  }
  if is_watch_source_path(path) {
    sources.push(path)
  }
}

///|
/// Join two path segments using the platform path helper.
pub fn join_path(base : String, child : String) -> String {
  let base_path : @path.Path = base
  base_path.join(child).to_string()
}

///|
/// Return whether a path is a watchable `.mbtv` source file.
fn is_watch_source_path(path : String) -> Bool {
  path.has_suffix(".mbtv")
}

///|
/// Compute the generated output file paths written beside a source `.mbtv`.
pub fn generated_output_paths(source_path : String) -> GeneratedOutputPaths {
  let stem = strip_watch_source_extension(source_path)
  {
    client: stem + ".client.mbt",
    server: stem + ".server.mbt",
    css: stem + ".css",
  }
}

///|
/// Strip the trailing `.mbtv` extension used by Vapor Moon source files.
fn strip_watch_source_extension(path : String) -> String {
  if !path.has_suffix(".mbtv") {
    return path
  }
  String::unsafe_substring(path, start=0, end=path.length() - 5)
}

///|
/// Write the generated client, server, and CSS outputs to sibling files.
pub fn write_compile_outputs(
  source_path : String,
  output : @compiler.CompileOutput,
) -> Unit raise @fs.IOError {
  let generated = generated_output_paths(source_path)
  @fs.write_string_to_file(
    generated.client,
    output.client_code,
    encoding="utf8",
  )
  @fs.write_string_to_file(
    generated.server,
    output.server_code,
    encoding="utf8",
  )
  @fs.write_string_to_file(generated.css, output.css_output, encoding="utf8")
}

///|
/// Remove generated sibling outputs when a watched source disappears.
pub fn remove_generated_outputs(source_path : String) -> Unit {
  let generated = generated_output_paths(source_path)
  remove_file_if_exists(generated.client)
  remove_file_if_exists(generated.server)
  remove_file_if_exists(generated.css)
}

///|
/// Best-effort file removal helper used during watch cleanup.
fn remove_file_if_exists(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  ignore(@fs.remove_file(path) catch { _ => () })
}

///|
/// Render a stable label relative to the watched root when possible.
fn render_watch_label(root_dir : String, path : String) -> String {
  let prefix = if root_dir.has_suffix("/") { root_dir } else { root_dir + "/" }
  if path.has_prefix(prefix) {
    return String::unsafe_substring(
      path,
      start=prefix.length(),
      end=path.length(),
    )
  }
  if path == root_dir {
    return "."
  }
  path
}

///|
/// Look up the last seen source contents for one watched file.
fn lookup_known_source(
  known_sources : Array[(String, String)],
  source_path : String,
) -> String? {
  for entry in known_sources {
    if entry.0 == source_path {
      return Some(entry.1)
    }
  }
  None
}

///|
/// Insert or overwrite the last seen source contents for a watched file.
fn store_known_source(
  known_sources : Array[(String, String)],
  source_path : String,
  source : String,
) -> Unit {
  for index in 0..<known_sources.length() {
    if known_sources[index].0 == source_path {
      known_sources[index] = (source_path, source)
      return
    }
  }
  known_sources.push((source_path, source))
}

///|
/// Remove one tracked watched source from the state table.
fn remove_known_source(
  known_sources : Array[(String, String)],
  source_path : String,
) -> Unit {
  for index in 0..<known_sources.length() {
    if known_sources[index].0 == source_path {
      let last_index = known_sources.length() - 1
      known_sources[index] = known_sources[last_index]
      known_sources.unsafe_pop_back()
      return
    }
  }
}

///|
/// Small linear contains helper for string arrays.
pub fn contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
/// Run the hover query and stringify the result for CLI output.
fn query_hover(
  source : String,
  path : String,
  line : String,
  character : String,
) -> String {
  let line = parse_cli_int(line)
  let character = parse_cli_int(character)
  match @tooling.hover_at(source, line, character, filename=path) {
    Some(result) => result.to_string()
    None => "None"
  }
}

///|
/// Run the definition query and stringify the result for CLI output.
fn query_definition(
  source : String,
  path : String,
  line : String,
  character : String,
) -> String {
  let line = parse_cli_int(line)
  let character = parse_cli_int(character)
  match @tooling.definition_at(source, line, character, filename=path) {
    Some(result) => result.to_string()
    None => "None"
  }
}

///|
/// Run the references query and stringify the result for CLI output.
pub fn query_references(
  source : String,
  path : String,
  line : String,
  character : String,
  include_declaration : Bool,
) -> String {
  let line = parse_cli_int(line)
  let character = parse_cli_int(character)
  @tooling.references_at(
    source,
    line,
    character,
    include_declaration~,
    filename=path,
  ).to_string()
}

///|
/// Run the completion query and stringify the result for CLI output.
fn query_completion(
  source : String,
  path : String,
  line : String,
  character : String,
) -> String {
  let line = parse_cli_int(line)
  let character = parse_cli_int(character)
  @tooling.complete_at(source, line, character, filename=path).to_string()
}

///|
/// Run the formatter query and stringify the formatted output when available.
pub fn query_format(source : String, path : String) -> String {
  match @tooling.format_document(source, filename=path) {
    Some(formatted) => formatted
    None => "None"
  }
}

///|
/// Parse a CLI integer argument, exiting nonzero when invalid.
fn parse_cli_int(source : String) -> Int {
  @strconv.parse_int(source) catch {
    _ => {
      println("invalid integer argument: " + source)
      @sys.exit(2)
      0
    }
  }
}

///|
/// Parse a CLI boolean flag, defaulting to `true` when omitted or invalid.
pub fn parse_cli_bool(source : String) -> Bool {
  match source {
    "false" | "0" | "no" => false
    _ => true
  }
}

///|
/// Print usage and exit with the conventional command-line usage code.
fn exit_usage() -> Unit {
  print_usage()
  @sys.exit(2)
}

///|
/// Print the supported CLI command surface.
fn print_usage() -> Unit {
  println("Usage: vapor-moon <command> <file.mbtv|directory> [args...]")
  println("       vapor-moon --help | --version")
  println("Run `vapor-moon --help` for the full command list.")
}

///|
/// Print the full structured help, used by `--help`, `-h`, and `help`.
fn print_help() -> Unit {
  println("vapor-moon " + @compiler_common.VERSION)
  println("MoonBit-first Single File Component compiler and tooling.")
  println("")
  println("USAGE:")
  println("  vapor-moon <command> <file.mbtv|directory> [args...]")
  println("  vapor-moon --help | -h")
  println("  vapor-moon --version | -V")
  println("")
  println("COMMANDS:")
  println(
    "  compile     <file.mbtv>                            Compile one .mbtv file and print client/server/css snapshot.",
  )
  println(
    "  watch       <directory>                            Recompile .mbtv files in <directory> on change.",
  )
  println(
    "  analyze     <file.mbtv>                            Print the analyzed SFC structure.",
  )
  println(
    "  diagnostics <file.mbtv>                            Print diagnostics for one file.",
  )
  println(
    "  check       <file.mbtv> [more.mbtv...]             Validate one or more files; exit 0 silently on success, exit 1 with `file:line:col [severity] message` lines otherwise.",
  )
  println(
    "  hover       <file.mbtv> <line> <character>         Print the hover result at a position.",
  )
  println(
    "  definition  <file.mbtv> <line> <character>         Print the definition at a position.",
  )
  println(
    "  references  <file.mbtv> <line> <character> [bool]  Print references at a position; final arg toggles includeDeclaration (default true).",
  )
  println(
    "  complete    <file.mbtv> <line> <character>         Print completion items at a position.",
  )
  println(
    "  format      <file.mbtv>                            Print the formatted source.",
  )
  println(
    "  doctor                                             Print environment diagnostics (MOON_HOME, moon.mod.json detection, etc.).",
  )
  println(
    "  new         <Name> [--force]                       Scaffold ./<Name>.mbtv from a minimal starter template; refuses to overwrite unless --force is set.",
  )
  println("")
  println("Positions are zero-based (LSP semantics).")
}

///|
/// Print environment diagnostics. Exit nonzero when any critical
/// expectation fails (e.g. the workspace cannot be located).
///
/// What we check:
/// - vapor-moon's own version (from the shared VERSION constant).
/// - The expected MoonBit version this Vapor Moon was built against.
/// - MOON_HOME if the env var is set.
/// - Presence of a moon.mod.json walking up from the current directory.
/// - Presence of the `vapor_moon` package in that manifest.
///
/// Intentionally does not shell out to `moon version` — keeping doctor
/// Scaffold `./<Name>.mbtv` from a minimal starter template. Refuses to
/// overwrite an existing file unless `--force` is passed so a stray
/// `vapor-moon new Counter` doesn't clobber a real component.
///
/// `name` becomes the file stem; bare component names map to
/// `./<Name>.mbtv`. A name with a `/` is treated as a path: the leading
/// directories are taken as-is, the final segment becomes the stem.
fn run_new(extra : ArrayView[String]) -> Unit {
  if extra.length() < 1 {
    println(
      "Usage: vapor-moon new <Name> [--force]",
    )
    @sys.exit(2)
    return
  }
  let name = extra[0]
  let mut force = false
  let mut index = 1
  while index < extra.length() {
    match extra[index] {
      "--force" | "-f" => force = true
      other => {
        println("vapor-moon new: unknown flag `" + other + "`")
        @sys.exit(2)
        return
      }
    }
    index += 1
  }
  if name.is_empty() {
    println("vapor-moon new: <Name> cannot be empty")
    @sys.exit(2)
    return
  }
  // Strip a trailing `.mbtv` if the user typed one — the subcommand
  // appends the extension itself so authors can write either spelling.
  let stem = if name.has_suffix(".mbtv") {
    name.substring(start=0, end=name.length() - 5).to_string()
  } else {
    name
  }
  let target = stem + ".mbtv"
  if @fs.path_exists(target) && !force {
    println(
      "vapor-moon new: " + target + " already exists. Pass --force to overwrite.",
    )
    @sys.exit(1)
    return
  }
  @fs.write_string_to_file(target, starter_template(stem), encoding="utf8") catch {
    err => {
      println("vapor-moon new: failed to write " + target + ": " + err.to_string())
      @sys.exit(1)
      return
    }
  }
  println("created " + target)
}

///|
/// Starter SFC body for `vapor-moon new`. Kept small enough to feel
/// like a stub but complete enough to compile and round-trip through
/// every stage of the pipeline (script + template + scoped style).
fn starter_template(name : String) -> String {
  // The unscoped class name uses the component stem so the rendered
  // markup is easy to recognize in dev tools without a manual rename.
  let css_class = "vapor-moon-" + name.to_lower()
  "<script>\n" +
  "import {\n" +
  "  \"mizchi/luna/js/resource\" @reactivity,\n" +
  "  let signal = @reactivity.signal,\n" +
  "}\n" +
  "\n" +
  "let count = signal(0)\n" +
  "</script>\n" +
  "\n" +
  "<template>\n" +
  "  <button class=\"" +
  css_class +
  "\" @click='count.update(fn(n) { n + 1 })'>\n" +
  "    {{ \"" +
  name +
  ": \" + count.get().to_string() }}\n" +
  "  </button>\n" +
  "</template>\n" +
  "\n" +
  "<style>\n" +
  "." +
  css_class +
  " {\n" +
  "  padding: 0.5rem 1rem;\n" +
  "  border-radius: 4px;\n" +
  "  border: 1px solid #ccc;\n" +
  "  background: #f5f5f5;\n" +
  "  cursor: pointer;\n" +
  "}\n" +
  "</style>\n"
}

///|
/// dependency-free means it works in environments where moon is not on
/// PATH (which is itself a useful diagnostic).
fn run_doctor() -> Unit {
  let mut failures = 0
  println("vapor-moon doctor")
  println("=================")
  println("vapor-moon version : " + @compiler_common.VERSION)
  println("expected MoonBit   : 0.1.20260512")
  match @env.get_env_var("MOON_HOME") {
    Some(home) => println("MOON_HOME          : " + home)
    None =>
      println("MOON_HOME          : <unset> (will fall back to $HOME/.moon)")
  }
  match find_moon_mod_json(".") {
    Some(path) => {
      println("moon.mod.json      : " + path)
      let content = @fs.read_file_to_string(path, encoding="utf8") catch {
        err => {
          println("  ! failed to read moon.mod.json: " + err.to_string())
          failures = failures + 1
          ""
        }
      }
      if content.contains("vapor_moon") {
        println("  ✓ contains a vapor_moon dependency reference")
      } else {
        println("  ! no vapor_moon dependency found in manifest")
        failures = failures + 1
      }
    }
    None => {
      println(
        "moon.mod.json      : <not found> (run `vapor-moon doctor` inside a moon workspace)",
      )
      failures = failures + 1
    }
  }
  println("")
  if failures == 0 {
    println("All checks passed.")
  } else {
    println(
      "" + failures.to_string() + " check(s) failed. See above for details.",
    )
    @sys.exit(1)
  }
}

///|
/// Walk up from `start` looking for a moon.mod.json. Returns the
/// resolved absolute path or None.
fn find_moon_mod_json(start : String) -> String? {
  let start_path : @path.Path = start
  let mut cursor : @path.Path = start_path.resolve()
  // 32 hops is way more than any real filesystem nests; the guard is a
  // belt-and-braces against cursor.dirname() returning the same path
  // and looping.
  for _ in 0..<32 {
    let candidate = cursor.join("moon.mod.json")
    if @fs.path_exists(candidate.to_string()) {
      return Some(candidate.to_string())
    }
    let parent = cursor.dirname()
    if parent.to_string() == cursor.to_string() {
      return None
    }
    cursor = parent
  }
  None
}
