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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let accent = "accent"
      #|  let tone = "color: blue"
      #|  let visible = true
      #|  (fn() {
      #|      let __vm_el = @d.el("div")
      #|      @d.setAttr(__vm_el, ("class", @d.dynAttr(fn() { @r.merge_class_names(["panel", accent.to_string()]) })))
      #|      @d.setAttr(__vm_el, ("style", @d.dynStyle(fn() { @r.show_style(visible, @r.merge_styles(["display: flex", tone.to_string()])) })))
      #|      @d.append(__vm_el.as_node(), @d.text("Hello"))
      #|      @d.into(__vm_el)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let accent = "accent"
      #|  let tone = "color: blue"
      #|  let visible = true
      #|  @luna_core.h("div", [("class", @luna_core.attr_dynamic(fn() { @r.merge_class_names(["panel", accent.to_string()]) })), ("style", @luna_core.attr_dynamic(fn() { @r.show_style(visible, @r.merge_styles(["display: flex", tone.to_string()])) }))], [
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let signal = @reactivity.signal,
      #|  let name = signal(" hello ")
      #|  let agreed = signal(false)
      #|  (fn() {
      #|      let __vm_el = @d.el("form")
      #|      @d.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @d.el("input")
      #|                @d.setAttr(__vm_el, ("value", @d.dynAttr(fn() { name.get().to_string() })))
      #|                @d.setAttr(__vm_el, ("change", @d.on(fn(_event) { name.set((_event._get("target")._get("value").cast()).trim().to_string()) })))
      #|                @d.into(__vm_el)
      #|              })())
      #|      @d.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @d.el("input")
      #|                @d.setAttr(__vm_el, ("type", @d.attr("checkbox")))
      #|                @d.setAttr(__vm_el, ("checked", @d.dynAttr(fn() { if agreed.get() { "true" } else { "false" } })))
      #|                @d.setAttr(__vm_el, ("change", @d.on(fn(_event) { agreed.set(_event._get("target")._get("checked").cast()) })))
      #|                @d.into(__vm_el)
      #|              })())
      #|      @d.into(__vm_el)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
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
