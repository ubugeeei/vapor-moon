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
fn line_character_after(source : String, needle : String) -> (Int, Int) {
  let (line, character) = line_character_at(source, needle)
  (line, character + needle.length())
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
test "lsp supports defineExpose members in script setup" {
  let source =
    #|<script setup>
    #|struct Expose {
    #|  focus : Unit
    #|  count : Int
    #|}
    #|
    #|let expose : Expose = defineExpose()
    #|let current = expose.focus()
    #|</script>
    #|
    #|<template>
    #|  <div>{{ current }}</div>
    #|</template>
  inspect(
    hover_at(
      source,
      7,
      21,
      filename="examples/expose_hover.mbtv",
    ).to_string(),
    content=(
      #|Some({contents: "expose focus : Unit", location: {filename: "examples/expose_hover.mbtv", span: {start: 121, end: 126}, range: {start: {line: 7, character: 21}, end_: {line: 7, character: 26}}}})
    ),
  )
  inspect(
    definition_at(
      source,
      7,
      21,
      filename="examples/expose_hover.mbtv",
    ).to_string(),
    content=(
      #|Some({name: "focus", location: {filename: "examples/expose_hover.mbtv", span: {start: 33, end: 38}, range: {start: {line: 2, character: 2}, end_: {line: 2, character: 7}}}})
    ),
  )
  inspect(
    complete_at(
      source,
      7,
      21,
      filename="examples/expose_hover.mbtv",
    ).to_string(),
    content=(
      #|[{label: "focus", kind: "expose", detail: "expose focus : Unit", insert_text: "focus"}, {label: "count", kind: "expose", detail: "expose count : Int", insert_text: "count"}]
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
test "macro completion includes defineExpose" {
  let source =
    #|<script setup>
    #|  defineEx
    #|</script>
    #|
    #|<template><div /></template>
  let (line, character) = line_character_at(source, "defineEx")
  inspect(
    complete_at(
      source,
      line,
      character + 8,
      filename="examples/complete_define_expose.mbtv",
    ).to_string(),
    content=(
      #|[{label: "defineExpose", kind: "macro", detail: "declare typed exposed members", insert_text: "defineExpose"}]
    ),
  )
}

///|
test "resolved template refs inherit defineExpose members for hover and completion" {
  let source =
    #|<script setup>
    #|import {
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|let panel_ref = useTemplateRef("panel")
    #|let focus = @vm_dom.resolve_template_ref(panel_ref).focus
    #|let next = @vm_dom.resolve_template_ref(panel_ref).
    #|</script>
    #|
    #|<template>
    #|  <ExposedPanel ref='panel' />
    #|</template>
  let (binding_line, binding_character) = line_character_at(
    source,
    "panel_ref).focus",
  )
  let binding_hover = hover_at(
    source,
    binding_line,
    binding_character,
    filename="examples/template_ref_expose_parent.mbtv",
  )
  match binding_hover {
    Some(result) => {
      assert_true(result.contents.contains("template ref `panel_ref`"))
      assert_true(result.contents.contains("ExposedPanel expose"))
      assert_true(result.contents.contains("template ref focus : Unit"))
    }
    None => panic()
  }

  let (member_line, member_character) = line_character_after(
    source,
    "resolve_template_ref(panel_ref).",
  )
  let member_hover = hover_at(
    source,
    member_line,
    member_character,
    filename="examples/template_ref_expose_parent.mbtv",
  )
  match member_hover {
    Some(result) => assert_eq(result.contents, "template ref focus : Unit")
    None => panic()
  }

  let (complete_line, complete_character) = line_character_after(
    source,
    "let next = @vm_dom.resolve_template_ref(panel_ref).",
  )
  let completions = complete_at(
    source,
    complete_line,
    complete_character,
    filename="examples/template_ref_expose_parent.mbtv",
  )
  assert_eq(completions.length(), 2)
  assert_eq(completions[0].label, "focus")
  assert_eq(completions[1].label, "count")
}

///|
test "resolved template refs report unknown exposed members" {
  let source =
    #|<script setup>
    #|import {
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|let panel_ref = useTemplateRef("panel")
    #|let missing = @vm_dom.resolve_template_ref(panel_ref).missing
    #|</script>
    #|
    #|<template>
    #|  <ExposedPanel ref='panel' />
    #|</template>
  let items = diagnostics(
    source,
    filename="examples/template_ref_expose_invalid.mbtv",
  )
  assert_eq(items.length(), 1)
  assert_true(items[0].message.contains("unknown template ref member `missing`"))
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
