///|
fn assert_snapshot(actual : String, expected : String) -> Unit raise {
  assert_eq(actual.trim().to_string(), expected.trim().to_string())
}

///|
fn analyze_snapshot(source : String, filename : String) -> String {
  analyze(source, filename~).to_string()
}

///|
test "snapshot macro analysis" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|}
    #|
    #|struct Emits {
    #|  save : String
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
  assert_snapshot(
    analyze_snapshot(source, "examples/macros.mbtv"),
    (
      #|{symbols: [{name: "script setup", kind: "block", span: {start: 0, end: 190}}, {name: "template", kind: "block", span: {start: 192, end: 296}}, {name: "props", kind: "macro defineProps", span: {start: 0, end: 0}}, {name: "emit", kind: "macro defineEmits", span: {start: 0, end: 0}}], expressions: ["emit.save()", "props.title"], diagnostics: [], island_components: [], extension: ".mbtv", props_binding: Some("props"), props: ["title", "count"], emits_binding: Some("emit"), emits: ["save", "cancel"]}
    ),
  )
}

///|
test "snapshot island analysis" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|
    #|let count = signal(3)
    #|</script>
    #|
    #|<template>
    #|  <section>
    #|    <CounterPanel :count='count.get()' client:visible />
    #|  </section>
    #|</template>
  assert_snapshot(
    analyze_snapshot(source, "examples/island_visible.mbtv"),
    (
      #|{symbols: [{name: "script setup", kind: "block", span: {start: 0, end: 134}}, {name: "template", kind: "block", span: {start: 136, end: 240}}], expressions: ["count.get()"], diagnostics: [], island_components: ["CounterPanel"], extension: ".mbtv", props_binding: None, props: [], emits_binding: None, emits: []}
    ),
  )
}
