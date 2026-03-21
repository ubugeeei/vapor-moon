///|
/// Minimal CLI for Vapor Moon compiler and tooling.

///|
fn main {
  let args = @env.args()
  if args.length() < 3 {
    print_usage()
    return
  }
  let command = args[1]
  let path = args[2]
  let source = read_text(path)
  match command {
    "compile" => {
      let output = @compiler.compile(source, filename=path) catch {
        err => {
          println(err.to_string())
          return
        }
      }
      println(output.snapshot())
    }
    "analyze" => {
      let analysis = @tooling.analyze(source, filename=path)
      println(analysis.to_string())
    }
    "diagnostics" =>
      println(@tooling.diagnostics(source, filename=path).to_string())
    "hover" =>
      if args.length() < 5 {
        print_usage()
      } else {
        println(query_hover(source, path, args[3], args[4]))
      }
    "definition" =>
      if args.length() < 5 {
        print_usage()
      } else {
        println(query_definition(source, path, args[3], args[4]))
      }
    "complete" =>
      if args.length() < 5 {
        print_usage()
      } else {
        println(query_completion(source, path, args[3], args[4]))
      }
    _ => print_usage()
  }
}

///|
fn read_text(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path) catch { _ => return "" }
  @utf8.decode_lossy(bytes[:])
}

///|
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
fn parse_cli_int(source : String) -> Int {
  @strconv.parse_int(source) catch {
    _ => 0
  }
}

///|
fn print_usage() -> Unit {
  println(
    "Usage: moon run src/cmd/vapor_moon -- <compile|analyze|diagnostics|hover|definition|complete> <file.mbtv> [line] [character]",
  )
}
