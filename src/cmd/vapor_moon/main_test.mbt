///|
fn command_test_dir(name : String) -> String {
  let cwd = @env.current_dir().unwrap_or(".")
  let root =
    join_path(
      cwd,
      ".vapor_moon_cmd_test_" + name + "_" + @env.now().to_string(),
    )
  @fs.create_dir(root) catch { _ => panic() }
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
  @fs.write_string_to_file(root_source, "<template><div /></template>", encoding="utf8") catch {
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
