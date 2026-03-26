///|
fn diagnostics_snapshot(source : String, filename : String) -> String {
  diagnostics(source, filename~).to_string()
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
test "snapshot lsp diagnostics" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|struct Slots {
    #|  default : Unit
    #|}
    #|
    #|let props : Props = defineProps()
    #|let emit : Emits = defineEmits()
    #|let slots : Slots = defineSlots()
    #|</script>
    #|
    #|<template>
    #|  <button @click='emit.cancel()'>
    #|    {{ props.missing }}
    #|    {{ slots.footer }}
    #|  </button>
    #|</template>
  inspect(
    diagnostics_snapshot(source, "examples/lsp_invalid.mbtv"),
    content=(
      #|[{severity: "error", message: "unknown props member `missing`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 287, end: 294}, range: {start: {line: 20, character: 13}, end_: {line: 20, character: 20}}}}, {severity: "error", message: "unknown emit member `cancel`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 263, end: 269}, range: {start: {line: 19, character: 23}, end_: {line: 19, character: 29}}}}, {severity: "error", message: "unknown slots member `footer`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 311, end: 317}, range: {start: {line: 21, character: 13}, end_: {line: 21, character: 19}}}}]
    ),
  )
}

///|
test "legacy emit.emit gets a dedicated diagnostic" {
  let source =
    #|<script setup>
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|let emit : Emits = defineEmits()
    #|</script>
    #|
    #|<template>
    #|  <button @click='emit.emit("save", [])'></button>
    #|</template>
  inspect(
    diagnostics_snapshot(source, "examples/legacy_emit.mbtv"),
    content=(
      #|[{severity: "error", message: "legacy `emit.emit(...)` is not supported; use typed event calls like `emit.save()`", location: {filename: "examples/legacy_emit.mbtv", span: {start: 125, end: 129}, range: {start: {line: 9, character: 23}, end_: {line: 9, character: 27}}}}]
    ),
  )
}

///|
test "snapshot lsp hover and definition" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|}
    #|
    #|struct Emits {
    #|  save : Unit
    #|  cancel : Unit
    #|}
    #|
    #|let props : Props = defineProps()
    #|let emit : Emits = defineEmits()
    #|</script>
    #|
    #|<template>
    #|  <button class="primary" @click='emit.save()'>
    #|    {{ props.title }}
    #|  </button>
    #|</template>
  inspect(
    hover_at(source, 17, 13, filename="examples/macros.mbtv").to_string(),
    content=(
      #|Some({contents: "props title : String", location: {filename: "examples/macros.mbtv", span: {start: 262, end: 267}, range: {start: {line: 17, character: 13}, end_: {line: 17, character: 18}}}})
    ),
  )
  inspect(
    definition_at(source, 16, 39, filename="examples/macros.mbtv").to_string(),
    content=(
      #|Some({name: "save", location: {filename: "examples/macros.mbtv", span: {start: 81, end: 85}, range: {start: {line: 7, character: 2}, end_: {line: 7, character: 6}}}})
    ),
  )
}

///|
test "hover does not bleed past the end of a symbol" {
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
    #|  <button>
    #|    {{ props.title }}
    #|  </button>
    #|</template>
  let (line, character) = line_character_at(source, "title }}")
  assert_eq(
    hover_at(
      source,
      line,
      character + 5,
      filename="examples/macros_cursor_boundary.mbtv",
    ),
    None,
  )
}

///|
test "snapshot lsp completion" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|}
    #|
    #|let props : Props = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <button :title='props.' v-></button>
    #|</template>
  inspect(
    complete_at(source, 10, 24, filename="examples/complete.mbtv").to_string(),
    content=(
      #|[{label: "title", kind: "props", detail: "props title : String", insert_text: "title"}, {label: "count", kind: "props", detail: "props count : Int", insert_text: "count"}]
    ),
  )
  inspect(
    complete_at(source, 10, 28, filename="examples/complete.mbtv").to_string(),
    content=(
      #|[{label: "v-if", kind: "directive", detail: "conditional rendering", insert_text: "v-if"}, {label: "v-else-if", kind: "directive", detail: "conditional branch (requires preceding v-if)", insert_text: "v-else-if"}, {label: "v-else", kind: "directive", detail: "fallback branch (requires preceding v-if or v-else-if)", insert_text: "v-else"}, {label: "v-for", kind: "directive", detail: "list rendering", insert_text: "v-for"}, {label: "v-show", kind: "directive", detail: "toggle visibility via CSS display", insert_text: "v-show"}, {label: "v-unsafe-html", kind: "directive", detail: "render unsafe raw HTML content", insert_text: "v-unsafe-html"}, {label: "v-model", kind: "directive", detail: "two-way binding on form elements", insert_text: "v-model"}, {label: "v-once", kind: "directive", detail: "render once (skip reactivity)", insert_text: "v-once"}, {label: "v-match", kind: "directive", detail: "pattern matching on an expression", insert_text: "v-match"}, {label: "v-case", kind: "directive", detail: "match branch pattern (inside v-match)", insert_text: "v-case"}, {label: "v-default", kind: "directive", detail: "default match branch (inside v-match)", insert_text: "v-default"}]
    ),
  )
}

///|
test "snapshot lsp event and binding completion" {
  let source =
    #|<template>
    #|  <button @></button>
    #|  <button v-on:></button>
    #|  <input : />
    #|  <input v-bind: />
    #|</template>
  let (event_line, event_character) = line_character_at(source, "@></button>")
  let (long_event_line, long_event_character) = line_character_at(
    source, "v-on:></button>",
  )
  let (bind_line, bind_character) = line_character_at(source, ": />")
  let (long_bind_line, long_bind_character) = line_character_at(
    source, "v-bind: />",
  )
  inspect(
    complete_at(
      source,
      event_line,
      event_character + 1,
      filename="examples/complete_attrs.mbtv",
    ).to_string(),
    content=(
      #|[{label: "@click", kind: "event", detail: "event handler", insert_text: "@click"}, {label: "@input", kind: "event", detail: "event handler", insert_text: "@input"}, {label: "@change", kind: "event", detail: "event handler", insert_text: "@change"}, {label: "@submit", kind: "event", detail: "event handler", insert_text: "@submit"}, {label: "@keydown", kind: "event", detail: "event handler", insert_text: "@keydown"}, {label: "@keyup", kind: "event", detail: "event handler", insert_text: "@keyup"}, {label: "@focus", kind: "event", detail: "event handler", insert_text: "@focus"}, {label: "@blur", kind: "event", detail: "event handler", insert_text: "@blur"}]
    ),
  )
  inspect(
    complete_at(
      source,
      long_event_line,
      long_event_character + 5,
      filename="examples/complete_attrs.mbtv",
    ).to_string(),
    content=(
      #|[{label: "v-on:click", kind: "event", detail: "event handler", insert_text: "v-on:click"}, {label: "v-on:input", kind: "event", detail: "event handler", insert_text: "v-on:input"}, {label: "v-on:change", kind: "event", detail: "event handler", insert_text: "v-on:change"}, {label: "v-on:submit", kind: "event", detail: "event handler", insert_text: "v-on:submit"}, {label: "v-on:keydown", kind: "event", detail: "event handler", insert_text: "v-on:keydown"}, {label: "v-on:keyup", kind: "event", detail: "event handler", insert_text: "v-on:keyup"}, {label: "v-on:focus", kind: "event", detail: "event handler", insert_text: "v-on:focus"}, {label: "v-on:blur", kind: "event", detail: "event handler", insert_text: "v-on:blur"}]
    ),
  )
  inspect(
    complete_at(
      source,
      bind_line,
      bind_character + 1,
      filename="examples/complete_attrs.mbtv",
    ).to_string(),
    content=(
      #|[{label: ":class", kind: "binding", detail: "dynamic attribute", insert_text: ":class"}, {label: ":style", kind: "binding", detail: "dynamic attribute", insert_text: ":style"}, {label: ":key", kind: "binding", detail: "dynamic attribute", insert_text: ":key"}, {label: ":ref", kind: "binding", detail: "dynamic attribute", insert_text: ":ref"}, {label: ":value", kind: "binding", detail: "dynamic attribute", insert_text: ":value"}, {label: ":checked", kind: "binding", detail: "dynamic attribute", insert_text: ":checked"}, {label: ":disabled", kind: "binding", detail: "dynamic attribute", insert_text: ":disabled"}]
    ),
  )
  inspect(
    complete_at(
      source,
      long_bind_line,
      long_bind_character + 7,
      filename="examples/complete_attrs.mbtv",
    ).to_string(),
    content=(
      #|[{label: "v-bind:class", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:class"}, {label: "v-bind:style", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:style"}, {label: "v-bind:key", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:key"}, {label: "v-bind:ref", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:ref"}, {label: "v-bind:value", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:value"}, {label: "v-bind:checked", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:checked"}, {label: "v-bind:disabled", kind: "binding", detail: "dynamic attribute", insert_text: "v-bind:disabled"}]
    ),
  )
}
