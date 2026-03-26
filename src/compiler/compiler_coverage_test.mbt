///|
/// Tests targeting uncovered branches to improve code coverage.

// ── Component attributes (attrs_component.mbt) ────────────────

///|
test "component with static and boolean attrs compiles" {
  let source =
    #|<template>
    #|  <MyWidget title="hello" disabled />
    #|</template>
  let output = compile_snapshot(source, "CompAttrs.mbtv")
  assert_true(output.contains("hello"))
  assert_true(output.contains("disabled"))
}

///|
test "component with dynamic attr compiles" {
  let source =
    #|<script setup>
    #|let val = "dynamic"
    #|</script>
    #|
    #|<template>
    #|  <MyWidget :data='val' />
    #|</template>
  let output = compile_snapshot(source, "CompDynAttr.mbtv")
  assert_true(output.contains("val"))
}

// ── Template comments in interpolation (text.mbt) ─────────────

///|
test "template with multiline text content compiles" {
  let source =
    #|<template>
    #|  <div>
    #|    hello
    #|    world
    #|  </div>
    #|</template>
  let output = compile_snapshot(source, "MultilineText.mbtv")
  assert_true(output.contains("hello"))
}

// ── Generic validation (generics.mbt) ─────────────────────────

///|
test "empty generic attribute is rejected" {
  let source =
    #|<script setup generic="">
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "EmptyGeneric.mbtv")
  assert_true(error.contains("requires a value"))
}

///|
test "duplicate generic parameter is rejected" {
  let source =
    #|<script setup generic="T, T">
    #|struct Props[T] { items : Array[T] }
    #|let props : Props[T] = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <div></div>
    #|</template>
  let error = compile_error(source, "DupGeneric.mbtv")
  assert_true(error.contains("duplicate"))
}

///|
test "generic with bound constraint compiles" {
  let source =
    #|<script setup generic="T : Show + Eq">
    #|struct Props[T] { item : T }
    #|let props : Props[T] = defineProps()
    #|</script>
    #|
    #|<template>
    #|  <div>{{ props.item.to_string() }}</div>
    #|</template>
  let output = compile_snapshot(source, "GenericBound.mbtv")
  assert_true(output.contains("T : Show + Eq"))
}

// ── Legacy emit validation (compiler.mbt) ─────────────────────

///|
test "legacy emit.emit() in script setup is rejected" {
  let source =
    #|<script setup>
    #|struct Emits { save : String }
    #|let emit : Emits = defineEmits()
    #|let result = emit.emit("test")
    #|</script>
    #|
    #|<template>
    #|  <div>test</div>
    #|</template>
  let error = compile_error(source, "LegacyEmitScript.mbtv")
  assert_true(error.contains("legacy"))
}

///|
test "legacy emit.emit() in template expression is rejected" {
  let source =
    #|<script setup>
    #|struct Emits { save : String }
    #|let emit : Emits = defineEmits()
    #|</script>
    #|
    #|<template>
    #|  <button @click='emit.emit("test")'>click</button>
    #|</template>
  let error = compile_error(source, "LegacyEmitTemplate.mbtv")
  assert_true(error.contains("legacy"))
}

// ── v-unsafe-html validation ──────────────────────────────────

///|
test "v-unsafe-html on element with children compiles" {
  let source =
    #|<script setup>
    #|let html = "<b>bold</b>"
    #|</script>
    #|
    #|<template>
    #|  <div v-unsafe-html='html'></div>
    #|</template>
  let output = compile_snapshot(source, "VUnsafeHtml.mbtv")
  assert_true(output.contains("raw_html"))
}

// ── Script setup render with imports (render.mbt) ─────────────

///|
test "script setup with imports renders import block" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|  let computed = @reactivity.computed,
    #|}
    #|
    #|let count = signal(0)
    #|let doubled = computed(fn() { count.get() * 2 })
    #|</script>
    #|
    #|<template>
    #|  <div>{{ doubled().to_string() }}</div>
    #|</template>
  let output = compile_snapshot(source, "ImportRender.mbtv")
  assert_true(output.contains("@reactivity"))
  assert_true(output.contains("doubled"))
}

// ── v-model with trim modifier (attrs_binding.mbt) ────────────

///|
test "v-model.trim generates trim call" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|let name = signal("hello")
    #|</script>
    #|
    #|<template>
    #|  <input v-model.trim='name.get()' />
    #|</template>
  let output = compile_snapshot(source, "VModelTrim.mbtv")
  assert_true(output.contains("trim"))
}

// ── Multiple style blocks ─────────────────────────────────────

///|
test "multiple style blocks both included in output" {
  let source =
    #|<template>
    #|  <div class="a">text</div>
    #|</template>
    #|
    #|<style>
    #|.a { color: red; }
    #|</style>
    #|
    #|<style>
    #|.a { font-size: 16px; }
    #|</style>
  let output = compile_snapshot(source, "MultiStyle.mbtv")
  assert_true(output.contains("color: red"))
  assert_true(output.contains("font-size: 16px"))
}

// ── Conditional on components ─────────────────────────────────

///|
test "v-if on component generates show wrapper" {
  let source =
    #|<script setup>
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <MyPanel v-if='visible' />
    #|</template>
  let output = compile_snapshot(source, "CondComponent.mbtv")
  assert_true(output.contains("show"))
  assert_true(output.contains("visible"))
}

// ── v-for with index ──────────────────────────────────────────

///|
test "v-for with index generates for_each with index param" {
  let source =
    #|<script setup>
    #|let items = [1, 2, 3]
    #|</script>
    #|
    #|<template>
    #|  <ul>
    #|    <li v-for='(item, idx) in items'>{{ idx.to_string() }}</li>
    #|  </ul>
    #|</template>
  let output = compile_snapshot(source, "VForIndex.mbtv")
  assert_true(output.contains("for_each"))
  assert_true(output.contains("idx"))
}

// ── Nested elements ───────────────────────────────────────────

// ── v-for error cases (parser.mbt) ─────────────────────────────

///|
test "v-for with empty source is rejected" {
  let source =
    #|<template>
    #|  <div v-for='item in '></div>
    #|</template>
  let error = compile_error(source, "VForEmpty.mbtv")
  assert_true(error.contains("invalid v-for"))
}

///|
test "v-for with too many bindings is rejected" {
  let source =
    #|<template>
    #|  <div v-for='(a, b, c) in items'></div>
    #|</template>
  let error = compile_error(source, "VForTooMany.mbtv")
  assert_true(error.contains("invalid v-for"))
}

///|
test "v-for with empty binding is rejected" {
  let source =
    #|<template>
    #|  <div v-for='(, idx) in items'></div>
    #|</template>
  let error = compile_error(source, "VForEmptyBinding.mbtv")
  assert_true(error.contains("invalid v-for"))
}

///|
test "v-for without in keyword is rejected" {
  let source =
    #|<template>
    #|  <div v-for='item of items'></div>
    #|</template>
  let error = compile_error(source, "VForNoIn.mbtv")
  assert_true(error.contains("expected"))
}

///|
test "v-for with single binding compiles" {
  let source =
    #|<script setup>
    #|let items = [1, 2, 3]
    #|</script>
    #|
    #|<template>
    #|  <div v-for='item in items'>{{ item.to_string() }}</div>
    #|</template>
  let output = compile_snapshot(source, "VForSingle.mbtv")
  assert_true(output.contains("for_each"))
  assert_true(output.contains("_index"))
}

// ── v-show on component is rejected ───────────────────────────

///|
test "v-show on component is rejected" {
  let source =
    #|<script setup>
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <MyComponent v-show='visible' />
    #|</template>
  let error = compile_error(source, "VShowComp.mbtv")
  assert_true(error.contains("v-show"))
}

// ── v-unsafe-html on void element is rejected ─────────────────

///|
test "v-unsafe-html on void element is rejected" {
  let source =
    #|<template>
    #|  <br v-unsafe-html='content' />
    #|</template>
  let error = compile_error(source, "VUnsafeHtmlVoid.mbtv")
  assert_true(error.contains("v-unsafe-html"))
}

// ── Duplicate directive is rejected ───────────────────────────

///|
test "duplicate v-if is rejected" {
  let source =
    #|<template>
    #|  <div v-if='a' v-if='b'></div>
    #|</template>
  let error = compile_error(source, "DupVIf.mbtv")
  assert_true(error.contains("duplicate"))
}

///|
test "duplicate v-for is rejected" {
  let source =
    #|<template>
    #|  <div v-for='a in items' v-for='b in items'></div>
    #|</template>
  let error = compile_error(source, "DupVFor.mbtv")
  assert_true(error.contains("duplicate"))
}

// ── Self-closing void elements ────────────────────────────────

///|
test "void elements must be self-closing" {
  let source =
    #|<template>
    #|  <img src="test.png" />
    #|</template>
  let output = compile_snapshot(source, "VoidElem.mbtv")
  assert_true(output.contains("img"))
}

// ── Event handlers ────────────────────────────────────────────

///|
test "event handler generates attr_handler" {
  let source =
    #|<script setup>
    #|fn handle() { () }
    #|</script>
    #|
    #|<template>
    #|  <button @click='handle()'>click</button>
    #|</template>
  let output = compile_snapshot(source, "EventHandler.mbtv")
  assert_true(output.contains("attr_handler"))
  assert_true(output.contains("handle()"))
}

///|
test "event modifiers generate attr_handler_with_modifiers" {
  let source =
    #|<script setup>
    #|fn save() { () }
    #|</script>
    #|
    #|<template>
    #|  <button @click.stop.prevent.self='save()'>save</button>
    #|  <button @click.capture.once.passive='save()'>options</button>
    #|</template>
  let output = compile_snapshot(source, "EventModifiers.mbtv")
  assert_true(output.contains("attr_handler_with_modifiers"))
  assert_true(output.contains("[\"stop\", \"prevent\", \"self\"]"))
  assert_true(output.contains("[\"capture\", \"once\", \"passive\"]"))
  assert_true(output.contains("save()"))
}

///|
test "deeply nested elements compile correctly" {
  let source =
    #|<template>
    #|  <div>
    #|    <section>
    #|      <article>
    #|        <p>deep</p>
    #|      </article>
    #|    </section>
    #|  </div>
    #|</template>
  let output = compile_snapshot(source, "DeepNest.mbtv")
  assert_true(output.contains("section"))
  assert_true(output.contains("article"))
  assert_true(output.contains("deep"))
}
