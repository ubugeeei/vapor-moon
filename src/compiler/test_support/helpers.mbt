///|
pub fn assert_snapshot(actual : String, expected : String) -> Unit raise {
  assert_eq(
    normalize_snapshot(actual.trim().to_string()),
    normalize_snapshot(expected.trim().to_string()),
  )
}

///|
pub fn compile(
  source : String,
  filename? : String = "Component.mbtv",
) -> @compiler.CompileOutput raise @compiler.CompilerError {
  @compiler.compile(source, filename~)
}

///|
pub fn parse_sfc(
  source : String,
  filename? : String = "Component.mbtv",
) -> @compiler.SfcDocument raise @compiler.CompilerError {
  @compiler.parse_sfc(source, filename~)
}

///|
pub fn parse_template(
  source : String,
) -> Array[@compiler.TemplateNode] raise @compiler.CompilerError {
  @compiler.parse_template(source)
}

///|
pub fn analyze_script_setup(
  source : String,
  filename : String,
) -> @compiler.ScriptSetupInfo raise @compiler.CompilerError {
  @compiler.analyze_script_setup(source, filename)
}

///|
pub fn compile_snapshot(source : String, filename : String) -> String {
  let output = compile(source, filename~) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  output.snapshot()
}

///|
fn normalize_snapshot(source : String) -> String {
  normalize_dynamic_text_lowering(normalize_client_temp_names(source))
}

///|
fn normalize_client_temp_names(source : String) -> String {
  let mut current = source
  for name in collect_client_temp_names(source) {
    current = current.replace_all(
      old="let " + name + " = @dom.el(",
      new="let __vm_el = @dom.el(",
    )
    current = current.replace_all(
      old="@dom.setAttr(" + name + ", ",
      new="@dom.setAttr(__vm_el, ",
    )
    current = current.replace_all(
      old="@dom.append(" + name + ".as_node(), ",
      new="@dom.append(__vm_el.as_node(), ",
    )
    current = current.replace_all(
      old="@dom.into(" + name + ")",
      new="@dom.into(__vm_el)",
    )
  }
  current
}

///|
fn normalize_dynamic_text_lowering(source : String) -> String {
  let lines = source.split("\n").map(fn(line) { line.to_string() }).collect()
  let normalized : Array[String] = []
  let mut index = 0
  while index < lines.length() {
    if index + 4 < lines.length() &&
      lines[index].contains("@dom.append(__vm_el.as_node(), (fn() {") &&
      lines[index + 1].trim().has_prefix("let ") &&
      lines[index + 1].trim().has_suffix(" = @dom.text(\"\")") &&
      lines[index + 4].trim() == "})())" {
      let text_node_line = lines[index + 1].trim().to_string()
      let node_name = String::unsafe_substring(
        text_node_line,
        start=4,
        end=text_node_line.length() - " = @dom.text(\"\")".length(),
      ).to_string()
      let set_text_line = lines[index + 2].trim().to_string()
      if set_text_line.has_prefix("@dom.setText(" + node_name + ", ") &&
        lines[index + 3].trim() == node_name {
        let line = lines[index].replace_all(
          old="@dom.append(__vm_el.as_node(), (fn() {",
          new="@dom.append(__vm_el.as_node(), @dom.setText(" +
            String::unsafe_substring(
              set_text_line,
              start=("@dom.setText(" + node_name + ", ").length(),
              end=set_text_line.length(),
            ).to_string() +
            ")",
        )
        normalized.push(line)
        index += 5
        continue
      }
    }
    normalized.push(lines[index])
    index += 1
  }
  normalized.join("\n")
}

///|
fn collect_client_temp_names(source : String) -> Array[String] {
  let names : Array[String] = []
  let lines = source.split("\n").map(fn(line) { line.to_string() }).collect()
  for line in lines {
    let trimmed = line.trim().to_string()
    if not(trimmed.has_prefix("let ")) {
      continue
    }
    match trimmed.find(" = @dom.el(") {
      Some(index) => {
        let name = String::unsafe_substring(trimmed, start=4, end=index)
        if not(temp_name_list_contains(names, name)) {
          names.push(name)
        }
      }
      None => ()
    }
  }
  names
}

///|
fn temp_name_list_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
pub fn compile_error(source : String, filename : String) -> String {
  let _ = compile(source, filename~) catch { err => return err.to_string() }
  panic()
}

///|
pub fn basic_source() -> String {
  let source =
    #|<script>
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
pub fn macros_source() -> String {
  let source =
    #|<script>
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
pub fn slots_source() -> String {
  let source =
    #|<script>
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
pub fn generic_source() -> String {
  let source =
    #|<script generic="T, U : Show">
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
pub fn island_visible_source() -> String {
  let source =
    #|<script>
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
pub fn directives_source() -> String {
  let source =
    #|<script>
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
pub fn media_and_defer_source() -> String {
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
pub fn reactivity_basics_source() -> String {
  let source =
    #|<script>
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
pub fn lifecycle_refs_source() -> String {
  let source =
    #|<script>
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
pub fn composable_counter_source() -> String {
  let source =
    #|<script>
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
