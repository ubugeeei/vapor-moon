///|
test "snapshot merged class and style attrs compile" {
  let source =
    #|<script setup>
    #|let accent = "accent"
    #|let tone = "color: blue"
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <div class="panel" :class='accent' style="display: flex" :style='tone' v-show='visible'>Hello</div>
    #|</template>
  assert_snapshot(
    compile_snapshot(source, "examples/merged_attrs.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let accent = "accent"
      #|  let tone = "color: blue"
      #|  let visible = true
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("div")
      #|      @vm_dom.apply_attr_entry(__vm_el, ("class", @vm_dom.attr_dynamic(fn() { @vm.merge_class_names(["panel", accent.to_string()]) })))
      #|      @vm_dom.apply_attr_entry(__vm_el, ("style", @vm_dom.attr_dynamic_style(fn() { @vm.show_style(visible, @vm.merge_styles(["display: flex", tone.to_string()])) })))
      #|      @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Hello"))
      #|      @vm_dom.to_node(__vm_el)
      #|    })()
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "MergedAttrs"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let accent = "accent"
      #|  let tone = "color: blue"
      #|  let visible = true
      #|  @luna_core.h("div", [("class", @luna_core.attr_dynamic(fn() { @vm.merge_class_names(["panel", accent.to_string()]) })), ("style", @luna_core.attr_dynamic(fn() { @vm.show_style(visible, @vm.merge_styles(["display: flex", tone.to_string()])) }))], [
      #|      @luna_core.text("Hello")
      #|    ])
      #|}
      #|
      #|pub fn render_html() -> String {
      #|  @vm_server.render_html(render_ssr())
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "MergedAttrs"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=MergedAttrs
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=<none>
      #|props=<none>
      #|emits_binding=<none>
      #|emits=<none>
      #|slots_binding=<none>
      #|slots=<none>
    ),
  )
}

///|
test "snapshot v-model modifiers compile" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|
    #|let name = signal(" hello ")
    #|let agreed = signal(false)
    #|</script>
    #|
    #|<template>
    #|  <form>
    #|    <input v-model.lazy.trim='name.get()' />
    #|    <input type='checkbox' v-model='agreed.get()' />
    #|  </form>
    #|</template>
  assert_snapshot(
    compile_snapshot(source, "examples/model_modifiers.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let signal = @reactivity.signal,
      #|  let name = signal(" hello ")
      #|  let agreed = signal(false)
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("form")
      #|      @vm_dom.append_child(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.element("input")
      #|                @vm_dom.apply_attr_entry(__vm_el, ("value", @vm_dom.attr_dynamic(fn() { name.get().to_string() })))
      #|                @vm_dom.apply_attr_entry(__vm_el, ("change", @vm_dom.attr_handler(fn(_event) { name.set((_event._get("target")._get("value").cast()).trim().to_string()) })))
      #|                @vm_dom.to_node(__vm_el)
      #|              })())
      #|      @vm_dom.append_child(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.element("input")
      #|                @vm_dom.apply_attr_entry(__vm_el, ("type", @vm_dom.attr_static("checkbox")))
      #|                @vm_dom.apply_attr_entry(__vm_el, ("checked", @vm_dom.attr_dynamic(fn() { if agreed.get() { "true" } else { "false" } })))
      #|                @vm_dom.apply_attr_entry(__vm_el, ("change", @vm_dom.attr_handler(fn(_event) { agreed.set(_event._get("target")._get("checked").cast()) })))
      #|                @vm_dom.to_node(__vm_el)
      #|              })())
      #|      @vm_dom.to_node(__vm_el)
      #|    })()
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "ModelModifiers"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let signal = @reactivity.signal,
      #|  let name = signal(" hello ")
      #|  let agreed = signal(false)
      #|  @luna_core.h("form", [], [
      #|      @luna_core.h("input", [("value", @luna_core.attr_dynamic(fn() { name.get().to_string() }))], []),
      #|      @luna_core.h("input", [("type", @luna_core.attr_static("checkbox")), ("checked", @luna_core.attr_dynamic(fn() { if agreed.get() { "true" } else { "false" } }))], [])
      #|    ])
      #|}
      #|
      #|pub fn render_html() -> String {
      #|  @vm_server.render_html(render_ssr())
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "ModelModifiers"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=ModelModifiers
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=<none>
      #|props=<none>
      #|emits_binding=<none>
      #|emits=<none>
      #|slots_binding=<none>
      #|slots=<none>
    ),
  )
}

///|
test "v-model rewrites spaced getter targets from AST" {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|
    #|let name = signal(" hello ")
    #|</script>
    #|
    #|<template>
    #|  <input v-model='name.get ()' />
    #|</template>
  let output = compile(source, filename="examples/model_spaced_getter.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(
    output.client_code.contains(
      ".set(_event._get(\"target\")._get(\"value\").cast())",
    ),
  )
  assert_false(output.client_code.contains("get () ="))
}
