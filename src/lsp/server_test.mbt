///|
fn component_source() -> String {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|struct Expose {
    #|  focus : Unit
    #|}
    #|
    #|let props : Props = defineProps()
    #|let expose : Expose = defineExpose()
    #|</script>
    #|
    #|<template>
    #|  <h1>{{ props.title }}</h1>
    #|</template>
  source
}

///|
fn invalid_props_source() -> String {
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
    #|  <h1>{{ props.missing }}</h1>
    #|</template>
  source
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
fn open_request(uri : String, text : String) -> String {
  stringify_json(
    json_object([
      ("jsonrpc", @js.any("2.0")),
      ("method", @js.any("textDocument/didOpen")),
      (
        "params",
        json_object([
          (
            "textDocument",
            json_object([("uri", @js.any(uri)), ("text", @js.any(text))]),
          ),
        ]),
      ),
    ]),
  )
}

///|
fn position_request(
  id : Int,
  method_name : String,
  line : Int,
  character : Int,
) -> String {
  stringify_json(
    json_object([
      ("jsonrpc", @js.any("2.0")),
      ("id", @js.any(id)),
      ("method", @js.any(method_name)),
      (
        "params",
        json_object([
          (
            "textDocument",
            json_object([("uri", @js.any("file:///Component.mbtv"))]),
          ),
          (
            "position",
            json_object([
              ("line", @js.any(line)),
              ("character", @js.any(character)),
            ]),
          ),
        ]),
      ),
    ]),
  )
}

///|
fn references_request(
  id : Int,
  line : Int,
  character : Int,
  include_declaration : Bool,
) -> String {
  stringify_json(
    json_object([
      ("jsonrpc", @js.any("2.0")),
      ("id", @js.any(id)),
      ("method", @js.any("textDocument/references")),
      (
        "params",
        json_object([
          (
            "textDocument",
            json_object([("uri", @js.any("file:///Component.mbtv"))]),
          ),
          (
            "position",
            json_object([
              ("line", @js.any(line)),
              ("character", @js.any(character)),
            ]),
          ),
          (
            "context",
            json_object([("includeDeclaration", @js.any(include_declaration))]),
          ),
        ]),
      ),
    ]),
  )
}

///|
fn formatting_request(id : Int) -> String {
  stringify_json(
    json_object([
      ("jsonrpc", @js.any("2.0")),
      ("id", @js.any(id)),
      ("method", @js.any("textDocument/formatting")),
      (
        "params",
        json_object([
          (
            "textDocument",
            json_object([("uri", @js.any("file:///Component.mbtv"))]),
          ),
          (
            "options",
            json_object([
              ("tabSize", @js.any(2)),
              ("insertSpaces", @js.any(true)),
            ]),
          ),
        ]),
      ),
    ]),
  )
}

///|
fn unformatted_source() -> String {
  let source =
    #|<script setup>
    #|let count = 1
    #|</script>
    #|<template><div><span>{{ count }}</span></div></template>
  source
}

///|
test "initialize advertises hover definition completion references and formatting" {
  let state = ServerState::new()
  let result = handle_message(
    state, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}",
  )

  assert_eq(result.exit_code, None)
  assert_true(result.messages[0].contains("\"hoverProvider\":true"))
  assert_true(result.messages[0].contains("\"definitionProvider\":true"))
  assert_true(result.messages[0].contains("\"referencesProvider\":true"))
  assert_true(
    result.messages[0].contains("\"documentFormattingProvider\":true"),
  )
  assert_true(result.messages[0].contains("\"completionProvider\""))
  assert_true(result.messages[0].contains("\"positionEncoding\":\"utf-16\""))
}

///|
test "didOpen publishes diagnostics for unknown props members" {
  let state = ServerState::new()
  let request = open_request("file:///Component.mbtv", invalid_props_source())
  let result = handle_message(state, request)

  assert_eq(result.exit_code, None)
  assert_true(result.messages[0].contains("publishDiagnostics"))
  assert_true(result.messages[0].contains("unknown props member"))
}

///|
test "hover definition and completion use opened documents" {
  let state = ServerState::new()
  let source = component_source()
  let did_open = open_request("file:///Component.mbtv", source)
  ignore(handle_message(state, did_open))

  let (member_line, member_character) = line_character_at(
    source, "title }}</h1>",
  )
  let hover = handle_message(
    state,
    position_request(2, "textDocument/hover", member_line, member_character),
  )
  let definition = handle_message(
    state,
    position_request(
      3, "textDocument/definition", member_line, member_character,
    ),
  )
  let (definition_line, _) = line_character_at(source, "title : String")
  let (complete_line, complete_character) = line_character_at(
    source, "props.title",
  )
  let completion = handle_message(
    state,
    position_request(
      4,
      "textDocument/completion",
      complete_line,
      complete_character + 6,
    ),
  )

  assert_true(hover.messages[0].contains("props title : String"))
  assert_true(
    definition.messages[0].contains("\"line\":" + definition_line.to_string()),
  )
  assert_true(completion.messages[0].contains("\"label\":\"title\""))
}

///|
test "server completion returns defineExpose members" {
  let state = ServerState::new()
  let source =
    #|<script setup>
    #|struct Expose {
    #|  focus : Unit
    #|}
    #|
    #|let expose : Expose = defineExpose()
    #|let x = expose.
    #|</script>
    #|
    #|<template><div /></template>
  let did_open = open_request("file:///Component.mbtv", source)
  ignore(handle_message(state, did_open))

  let (line, character) = line_character_at(source, "expose.")
  let completion = handle_message(
    state,
    position_request(5, "textDocument/completion", line, character + 7),
  )

  assert_true(completion.messages[0].contains("\"label\":\"focus\""))
}

///|
test "completion returns template event candidates" {
  let state = ServerState::new()
  let source =
    #|<template>
    #|  <button @></button>
    #|</template>
  let did_open = open_request("file:///Component.mbtv", source)
  ignore(handle_message(state, did_open))

  let (line, character) = line_character_at(source, "@></button>")
  let completion = handle_message(
    state,
    position_request(5, "textDocument/completion", line, character + 1),
  )

  assert_true(completion.messages[0].contains("\"label\":\"@click\""))
}

///|
test "server references return declaration and usage locations" {
  let state = ServerState::new()
  let source = component_source()
  ignore(handle_message(state, open_request("file:///Component.mbtv", source)))

  let (member_line, member_character) = line_character_at(
    source, "title }}</h1>",
  )
  let (definition_line, _) = line_character_at(source, "title : String")
  let references = handle_message(
    state,
    references_request(6, member_line, member_character, true),
  )

  assert_true(
    references.messages[0].contains("\"line\":" + definition_line.to_string()),
  )
  assert_true(
    references.messages[0].contains("\"line\":" + member_line.to_string()),
  )
}

///|
test "server formatting returns one full-document edit" {
  let state = ServerState::new()
  let source = unformatted_source()
  ignore(handle_message(state, open_request("file:///Component.mbtv", source)))

  let formatting = handle_message(state, formatting_request(7))

  assert_true(formatting.messages[0].contains("\"newText\":\"<script setup>"))
  assert_true(formatting.messages[0].contains("\\n\\n<template>\\n  <div>"))
  assert_true(formatting.messages[0].contains("<span>{{ count }}</span>"))
}
