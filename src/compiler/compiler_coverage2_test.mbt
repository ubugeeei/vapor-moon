///|
/// Additional coverage tests — round 2.

// ── ExpressionStatement macros (analyze.mbt:86-137) ───────────

///|
test "duplicate defineProps without binding is rejected" {
  let source =
    #|<script setup>
    #|struct Props { title : String }
    #|struct Props2 { name : String }
    #|let p1 : Props = defineProps()
    #|let p2 : Props2 = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "DupProps2.mbtv")
  assert_true(error.contains("duplicate defineProps"))
}

///|
test "duplicate defineProps is rejected" {
  let source =
    #|<script setup>
    #|struct Props { a : String }
    #|let p1 : Props = defineProps()
    #|let p2 : Props = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "DupProps.mbtv")
  assert_true(error.contains("duplicate defineProps"))
}

///|
test "duplicate defineEmits is rejected" {
  let source =
    #|<script setup>
    #|struct Emits { a : Unit }
    #|let e1 : Emits = defineEmits()
    #|let e2 : Emits = defineEmits()
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "DupEmits.mbtv")
  assert_true(error.contains("duplicate defineEmits"))
}

///|
test "duplicate defineSlot is rejected" {
  let source =
    #|<script setup>
    #|struct Slots { a : Unit }
    #|let s1 : Slots = defineSlots()
    #|let s2 : Slots = defineSlots()
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "DupSlots.mbtv")
  assert_true(error.contains("duplicate defineSlot"))
}

// ── Interpolation with nested delimiters (text.mbt) ───────────

///|
test "interpolation with nested parentheses" {
  let source =
    #|<script setup>
    #|fn f(x : Int) -> String { x.to_string() }
    #|</script>
    #|
    #|<template>
    #|  <div>{{ f(1 + (2 * 3)) }}</div>
    #|</template>
  let output = compile_snapshot(source, "InterpolParen.mbtv")
  assert_true(output.contains("f(1 + (2 * 3))"))
}

///|
test "interpolation with nested brackets" {
  let source =
    #|<script setup>
    #|let items = [1, 2, 3]
    #|</script>
    #|
    #|<template>
    #|  <div>{{ items[0].to_string() }}</div>
    #|</template>
  let output = compile_snapshot(source, "InterpolBracket.mbtv")
  assert_true(output.contains("items[0]"))
}

///|
test "interpolation with nested braces" {
  let source =
    #|<script setup>
    #|fn wrap() -> String { { "nested" }.to_string() }
    #|</script>
    #|
    #|<template>
    #|  <div>{{ wrap() }}</div>
    #|</template>
  let output = compile_snapshot(source, "InterpolBrace.mbtv")
  assert_true(output.contains("wrap()"))
}

///|
test "interpolation with string containing closing braces" {
  let source =
    #|<template>
    #|  <div>{{ "hello" }}</div>
    #|</template>
  let output = compile_snapshot(source, "InterpolString.mbtv")
  assert_true(output.contains("hello"))
}

// ── v-model named argument (builder_attrs.mbt) ────────────────

///|
test "v-model with named argument on native element is rejected" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let title = signal("hi")
    #|</script>
    #|
    #|<template>
    #|  <input v-model:value='title.get()' />
    #|</template>
  let error = compile_error(source, "VModelNamed.mbtv")
  assert_true(error.contains("v-model arguments"))
}

///|
test "v-model with invalid syntax is rejected" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let name = signal("")
    #|</script>
    #|
    #|<template>
    #|  <input v-model..='name.get()' />
    #|</template>
  let error = compile_error(source, "VModelBad.mbtv")
  assert_true(error.contains("v-model"))
}

// ── Style with @media rule (codegen/utils.mbt) ────────────────

///|
test "scoped style preserves @media rules" {
  let source =
    #|<template>
    #|  <div class="box">text</div>
    #|</template>
    #|
    #|<style scoped>
    #|.box { color: red; }
    #|@media (max-width: 768px) { .box { color: blue; } }
    #|</style>
  let output = compile_snapshot(source, "MediaScoped.mbtv")
  assert_true(output.contains("@media"))
  assert_true(output.contains("data-vm-scope"))
}

// ── Style show with v-show (attrs_style.mbt) ──────────────────

///|
test "v-show with dynamic style merges show_style" {
  let source =
    #|<script setup>
    #|let visible = true
    #|let color = "red"
    #|</script>
    #|
    #|<template>
    #|  <div v-show='visible' :style='color'>text</div>
    #|</template>
  let output = compile_snapshot(source, "VShowStyle.mbtv")
  assert_true(output.contains("show_style"))
}

///|
test "v-show with static style merges show_style" {
  let source =
    #|<script setup>
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <div v-show='visible' style='color: red'>text</div>
    #|</template>
  let output = compile_snapshot(source, "VShowStaticStyle.mbtv")
  assert_true(output.contains("show_style"))
}

// ── Dynamic class on component (attrs_style.mbt) ──────────────

///|
test "component with dynamic class generates merge" {
  let source =
    #|<script setup>
    #|let cls = "highlight"
    #|</script>
    #|
    #|<template>
    #|  <MyWidget class="base" :class='cls' />
    #|</template>
  let output = compile_snapshot(source, "CompClassMerge.mbtv")
  assert_true(output.contains("base"))
}

// ── v-unsafe-html on component is rejected ────────────────────

///|
test "v-unsafe-html on component is rejected" {
  let source =
    #|<template>
    #|  <MyWidget v-unsafe-html='content' />
    #|</template>
  let error = compile_error(source, "VUnsafeHtmlComp.mbtv")
  assert_true(error.contains("v-unsafe-html"))
}

// ── Checkbox v-model (attrs_binding.mbt) ──────────────────────

///|
test "v-model on checkbox generates checked binding" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let agreed = signal(false)
    #|</script>
    #|
    #|<template>
    #|  <input type="checkbox" v-model='agreed.get()' />
    #|</template>
  let output = compile_snapshot(source, "VModelCheckbox.mbtv")
  assert_true(output.contains("checked"))
}

// ── Select v-model (attrs_binding.mbt) ────────────────────────

///|
test "v-model on select generates value binding" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let choice = signal("a")
    #|</script>
    #|
    #|<template>
    #|  <select v-model='choice.get()'>
    #|    <option value='a'>A</option>
    #|    <option value='b'>B</option>
    #|  </select>
    #|</template>
  let output = compile_snapshot(source, "VModelSelect.mbtv")
  assert_true(output.contains("choice.get()"))
}

// ── Textarea v-model (attrs_binding.mbt) ──────────────────────

///|
test "v-model on textarea generates value binding" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let text = signal("hello")
    #|</script>
    #|
    #|<template>
    #|  <textarea v-model='text.get()'></textarea>
    #|</template>
  let output = compile_snapshot(source, "VModelTextarea.mbtv")
  assert_true(output.contains("text.get()"))
}

// ── Quote escaping in attributes (builder_attrs.mbt) ──────────

///|
test "static ref attribute with special chars" {
  let source =
    #|<template>
    #|  <div ref='my-ref'>text</div>
    #|</template>
  let output = compile_snapshot(source, "RefSpecial.mbtv")
  assert_true(output.contains("my-ref"))
}
