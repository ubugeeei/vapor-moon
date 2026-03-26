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
    #|let slots : Slots = defineSlots()
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
    #|let slots : Slots[T, U] = defineSlots()
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

///|
fn reactivity_basics_source() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|  let computed = @reactivity.computed,
    #|  let watch = @reactivity.watch,
    #|  let effect = @reactivity.effect,
    #|}
    #|
    #|let count = signal(1)
    #|let doubled = computed(fn() { count.get() * 2 })
    #|let summary = computed(fn() {
    #|  "count=" + count.get().to_string() + ", doubled=" + doubled().to_string()
    #|})
    #|let history = signal("1 -> 1")
    #|let summary_effect = effect(fn() { ignore(summary()) })
    #|let count_watch = watch(fn() { count.get() }, fn(next, prev) {
    #|  history.set(prev.to_string() + " -> " + next.to_string())
    #|})
    #|</script>
    #|
    #|<template>
    #|  <section class="reactivity">
    #|    <button @click='count.update(fn(n) { n + 1 })'>+</button>
    #|    <p>{{ summary() }}</p>
    #|    <small>{{ history.get() }}</small>
    #|  </section>
    #|</template>
  source
}

///|
fn lifecycle_refs_source() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|  let on_mount = @reactivity.on_mount,
    #|  let on_cleanup = @reactivity.on_cleanup,
    #|}
    #|
    #|let root_ref = useTemplateRef("root")
    #|let instance_id = useId()
    #|let phase = signal("booting")
    #|let mount_registration = on_mount(fn() {
    #|  phase.set("mounted:" + instance_id)
    #|  on_cleanup(fn() {
    #|    ignore(root_ref)
    #|  })
    #|})
    #|</script>
    #|
    #|<template>
    #|  <section ref='root' :data-id='instance_id'>
    #|    <p>{{ phase.get() }}</p>
    #|    <p>{{ instance_id }}</p>
    #|  </section>
    #|</template>
  source
}

///|
fn composable_counter_source() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|  let computed = @reactivity.computed,
    #|  let watch = @reactivity.watch,
    #|  let effect = @reactivity.effect,
    #|}
    #|
    #|struct CounterComposable {
    #|  count : @reactivity.Signal[Int]
    #|  doubled : () -> Int
    #|  last_change : @reactivity.Signal[String]
    #|}
    #|
    #|fn useCounter(initial : Int) -> CounterComposable {
    #|  let count = signal(initial)
    #|  let doubled = computed(fn() { count.get() * 2 })
    #|  let last_change = signal("ready")
    #|  let doubled_effect = effect(fn() { ignore(doubled()) })
    #|  let change_watch = watch(fn() { count.get() }, fn(next, prev) {
    #|    last_change.set(prev.to_string() + " -> " + next.to_string())
    #|  })
    #|  { count, doubled, last_change }
    #|}
    #|
    #|let counter = useCounter(2)
    #|</script>
    #|
    #|<template>
    #|  <section class="composable">
    #|    <button @click='counter.count.update(fn(n) { n + 1 })'>inc</button>
    #|    <p>{{ counter.count.get() }}</p>
    #|    <p>{{ counter.doubled() }}</p>
    #|    <small>{{ counter.last_change.get() }}</small>
    #|  </section>
    #|</template>
  source
}
