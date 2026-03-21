///|
fn assert_snapshot(actual : String, expected : String) -> Unit raise {
  assert_eq(actual.trim().to_string(), expected.trim().to_string())
}

///|
fn compile_snapshot(source : String, filename : String) -> String {
  let output = compile(source, filename~) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  output.snapshot()
}

///|
fn compile_error(source : String, filename : String) -> String {
  let _ = compile(source, filename~) catch { err => return err.to_string() }
  panic()
}

///|
fn basic_source() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|
    #|let count = signal(0)
    #|</script>
    #|
    #|<template>
    #|  <div class="counter">{{ count.get() }}</div>
    #|</template>
    #|
    #|<style scoped>
    #|.counter {
    #|  color: red;
    #|}
    #|</style>
  source
}

///|
fn macros_source() -> String {
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
  source
}

///|
fn slots_source() -> String {
  let source =
    #|<script setup>
    #|struct Slots {
    #|  default : Unit
    #|  footer : String
    #|}
    #|
    #|let slots : Slots = defineSlot()
    #|</script>
    #|
    #|<template>
    #|  <section class="shell"></section>
    #|</template>
  source
}

///|
fn generic_source() -> String {
  let source =
    #|<script setup generic="T, U : Show">
    #|struct Props[T, U] {
    #|  items : Array[T]
    #|  selected : U
    #|}
    #|
    #|struct Emits[T] {
    #|  choose : T
    #|}
    #|
    #|struct Slots[T, U] {
    #|  default : T
    #|  label : U
    #|}
    #|
    #|let props : Props[T, U] = defineProps()
    #|let emit : Emits[T] = defineEmits()
    #|let slots : Slots[T, U] = defineSlot()
    #|</script>
    #|
    #|<template>
    #|  <section>{{ props.items.length() }}</section>
    #|</template>
  source
}

///|
fn island_visible_source() -> String {
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
  source
}

///|
fn directives_source() -> String {
  let source =
    #|<script setup>
    #|let items = [1, 2, 3]
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <ul v-if='visible'>
    #|    <li v-for='(item, index) in items'>{{ item.to_string() + ":" + index.to_string() }}</li>
    #|  </ul>
    #|</template>
  source
}

///|
fn media_and_defer_source() -> String {
  let source =
    #|<template>
    #|  <main>
    #|    <HeroBanner client:media='(max-width: 768px)' />
    #|    <ArticleChunk server:defer />
    #|  </main>
    #|</template>
  source
}
