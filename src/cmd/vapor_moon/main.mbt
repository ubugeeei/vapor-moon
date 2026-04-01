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
fn main {
  let args = @env.args()
  if args.length() < 3 {
    print_usage()
    return
  }
  let command = args[1]
  let path = args[2]
  match command {
    "watch" => watch_directory(path)
    "compile" => {
      let source = read_text(path)
      let output = @compiler.compile(source, filename=path) catch {
        err => {
          println(err.to_string())
          return
        }
      }
      println(output.snapshot())
    }
    "analyze" => {
      let source = read_text(path)
      let analysis = @tooling.analyze(source, filename=path)
      println(analysis.to_string())
    }
    "diagnostics" => {
      let source = read_text(path)
      println(@tooling.diagnostics(source, filename=path).to_string())
    }
    "hover" =>
      if args.length() < 5 {
        print_usage()
      } else {
        let source = read_text(path)
        println(query_hover(source, path, args[3], args[4]))
      }
    "definition" =>
      if args.length() < 5 {
        print_usage()
      } else {
        let source = read_text(path)
        println(query_definition(source, path, args[3], args[4]))
      }
    "complete" =>
      if args.length() < 5 {
        print_usage()
      } else {
        let source = read_text(path)
        println(query_completion(source, path, args[3], args[4]))
      }
    _ => print_usage()
  }
}

///|
/// Read a UTF-8 source file, returning an empty string on failure.
fn read_text(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path) catch { _ => return "" }
  @utf8.decode_lossy(bytes[:])
}

///|
/// Watch a directory tree, recompiling `.mbtv` files on change and writing generated outputs.
fn watch_directory(root : String) -> Unit {
  let root_dir : @path.Path = root
  let resolved_root = root_dir.resolve().to_string()
  if not(@fs.path_exists(resolved_root)) {
    println("watch root does not exist: " + resolved_root)
    return
  }
  let is_dir = @fs.is_dir(resolved_root) catch {
    err => {
      println(err.to_string())
      return
    }
  }
  if not(is_dir) {
    println("watch root is not a directory: " + resolved_root)
    return
  }
  println("watching " + resolved_root)
  let compiler = @incremental.IncrementalCompiler::new()
  let known_sources : Array[(String, String)] = []
  let initial_sources = collect_watch_sources(resolved_root) catch {
    err => {
      println(err.to_string())
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
  if not(path.has_suffix(".mbtv")) {
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
  if not(@fs.path_exists(path)) {
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
/// Parse a CLI integer argument, defaulting to `0` when invalid.
fn parse_cli_int(source : String) -> Int {
  @strconv.parse_int(source) catch {
    _ => 0
  }
}

///|
/// Print the supported CLI command surface.
fn print_usage() -> Unit {
  println(
    "Usage: moon run src/cmd/vapor_moon -- <compile|watch|analyze|diagnostics|hover|definition|complete> <file.mbtv|directory> [line] [character]",
  )
}
