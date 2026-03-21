///|
fn diagnostics_snapshot(source : String, filename : String) -> String {
  diagnostics(source, filename~).to_string()
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
    #|let slots : Slots = defineSlot()
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
      #|[{severity: "error", message: "unknown props member `missing`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 286, end: 293}, range: {start: {line: 20, character: 13}, end_: {line: 20, character: 20}}}}, {severity: "error", message: "unknown emit member `cancel`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 262, end: 268}, range: {start: {line: 19, character: 23}, end_: {line: 19, character: 29}}}}, {severity: "error", message: "unknown slots member `footer`", location: {filename: "examples/lsp_invalid.mbtv", span: {start: 310, end: 316}, range: {start: {line: 21, character: 13}, end_: {line: 21, character: 19}}}}]
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
      #|Some({name: "save", location: {filename: "examples/macros.mbtv", span: {start: 150, end: 154}, range: {start: {line: 12, character: 4}, end_: {line: 12, character: 8}}}})
    ),
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
      #|[{label: "v-if", kind: "directive", detail: "template directive", insert_text: "v-if"}, {label: "v-for", kind: "directive", detail: "template directive", insert_text: "v-for"}, {label: "v-show", kind: "directive", detail: "template directive", insert_text: "v-show"}, {label: "v-html", kind: "directive", detail: "template directive", insert_text: "v-html"}, {label: "v-model", kind: "directive", detail: "template directive", insert_text: "v-model"}, {label: "v-once", kind: "directive", detail: "template directive", insert_text: "v-once"}]
    ),
  )
}
