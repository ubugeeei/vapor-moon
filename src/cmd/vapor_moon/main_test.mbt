///|
fn command_test_dir(name : String) -> String {
  let cwd = @env.current_dir().unwrap_or(".")
  let root = join_path(
    cwd,
    ".vapor_moon_cmd_test_" + name + "_" + @env.now().to_string(),
  )
  @fs.create_dir(root) catch {
    _ => panic()
  }
  root
}

///|
fn cleanup_command_test_dir(root : String) -> Unit {
  cleanup_command_test_tree(root)
  ignore(@fs.remove_dir(root) catch { _ => () })
}

///|
fn cleanup_command_test_tree(path : String) -> Unit {
  if not(@fs.path_exists(path)) {
    return
  }
  let is_dir = @fs.is_dir(path) catch { _ => false }
  if is_dir {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for entry in entries {
      cleanup_command_test_tree(join_path(path, entry))
    }
    ignore(@fs.remove_dir(path) catch { _ => () })
    return
  }
  ignore(@fs.remove_file(path) catch { _ => () })
}

///|
fn assert_contains_path(paths : Array[String], target : String) -> Unit raise {
  assert_true(contains_string(paths, target))
}

///|
fn find_offset(source : String, needle : String) -> Int {
  let chars = source.to_array()
  let pattern = needle.to_array()
  let last = chars.length() - pattern.length()
  let mut cursor = 0
  while cursor <= last {
    let mut matched = true
    for index in 0..<pattern.length() {
      if chars[cursor + index] != pattern[index] {
        matched = false
        break
      }
    }
    if matched {
      return cursor
    }
    cursor += 1
  }
  0
}

///|
fn line_character_at(source : String, needle : String) -> (Int, Int) {
  let start = find_offset(source, needle)
  let chars = source.to_array()
  let mut line = 0
  let mut character = 0
  let mut cursor = 0
  while cursor < start {
    if chars[cursor] == '\n' {
      line += 1
      character = 0
    } else {
      character += if chars[cursor].to_int() > 0xFFFF { 2 } else { 1 }
    }
    cursor += 1
  }
  (line, character)
}

///|
test "generated output paths use sibling client server css files" {
  let generated = generated_output_paths("/tmp/examples/Panel.mbtv")
  assert_eq(generated.client, "/tmp/examples/Panel.client.mbt")
  assert_eq(generated.server, "/tmp/examples/Panel.server.mbt")
  assert_eq(generated.css, "/tmp/examples/Panel.css")
}

///|
test "collect watch sources finds nested mbtv files only" {
  let root = command_test_dir("scan")
  let nested = join_path(root, "nested")
  @fs.create_dir(nested) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  let root_source = join_path(root, "Root.mbtv")
  let nested_source = join_path(nested, "Child.mbtv")
  let note = join_path(root, "note.txt")
  @fs.write_string_to_file(
    root_source,
    "<template><div /></template>",
    encoding="utf8",
  ) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  @fs.write_string_to_file(
    nested_source,
    "<template><span /></template>",
    encoding="utf8",
  ) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  @fs.write_string_to_file(note, "ignore me", encoding="utf8") catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  let sources = collect_watch_sources(root) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  assert_eq(sources.length(), 2)
  assert_contains_path(sources, root_source)
  assert_contains_path(sources, nested_source)
  cleanup_command_test_dir(root)
}

///|
test "write compile outputs persists generated files beside source" {
  let root = command_test_dir("write")
  let source_path = join_path(root, "Widget.mbtv")
  let source =
    #|<template>
    #|  <div class="widget">ok</div>
    #|</template>
  let output = @compiler.compile(source, filename=source_path) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  write_compile_outputs(source_path, output) catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  let generated = generated_output_paths(source_path)
  let client = @fs.read_file_to_string(generated.client, encoding="utf8") catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  let server = @fs.read_file_to_string(generated.server, encoding="utf8") catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  let css = @fs.read_file_to_string(generated.css, encoding="utf8") catch {
    _ => {
      cleanup_command_test_dir(root)
      panic()
    }
  }
  assert_eq(client, output.client_code)
  assert_eq(server, output.server_code)
  assert_eq(css, output.css_output)
  remove_generated_outputs(source_path)
  assert_false(@fs.path_exists(generated.client))
  assert_false(@fs.path_exists(generated.server))
  assert_false(@fs.path_exists(generated.css))
  cleanup_command_test_dir(root)
}

///|
test "query references renders declaration and usage locations" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|let props : Props = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <h1>{{ props.title }}</h1>
    #|</template>
  let (line, character) = line_character_at(source, "title }}</h1>")
  let output = query_references(
    source,
    "examples/references_props.mbtv",
    line.to_string(),
    character.to_string(),
    true,
  )
  assert_true(output.contains("examples/references_props.mbtv"))
  assert_true(output.contains("line: 2"))
  assert_true(output.contains("line: 9"))
}

///|
test "query format prints formatted document" {
  let source =
    #|<script setup>
    #|let count = 1
    #|</script>
    #|<template><div><span>{{ count }}</span></div></template>
  let output = query_format(source, "examples/format_basic.mbtv")
  assert_true(
    output.contains("<template>\n  <div>\n    <span>{{ count }}</span>"),
  )
  assert_true(output.has_suffix("</template>\n"))
}

///|
test "parse cli bool accepts explicit false spellings" {
  assert_false(parse_cli_bool("false"))
  assert_false(parse_cli_bool("0"))
  assert_false(parse_cli_bool("no"))
  assert_true(parse_cli_bool("true"))
  assert_true(parse_cli_bool("unexpected"))
}
