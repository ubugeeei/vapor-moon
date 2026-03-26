///|
test "snapshot script setup close tag literal compile" {
  let source =
    #|<script setup>
    #|let closing = "</script>"
    #|</script>
    #|<template>
    #|  <div>{{ closing }}</div>
    #|</template>
  assert_snapshot(
    compile_snapshot(source, "examples/edge_script_literal.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let closing = "</script>"
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("div")
      #|      @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text_expr(fn() { closing.to_string() }))
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
      #|pub let component_name : String = "EdgeScriptLiteral"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let closing = "</script>"
      #|  @luna_core.h("div", [], [
      #|      @luna_core.text_dyn(fn() { closing.to_string() })
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
      #|pub let component_name : String = "EdgeScriptLiteral"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=EdgeScriptLiteral
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
test "snapshot style close tag literal compile" {
  let source =
    #|<template><div class="box" /></template>
    #|<style>
    #|.box::before { content: "</style>"; }
    #|.box { color: red; }
    #|</style>
  assert_snapshot(
    compile_snapshot(source, "examples/edge_style_literal.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("div")
      #|      @vm_dom.apply_attr_entry(__vm_el, ("class", @vm_dom.attr_static("box")))
      #|      @vm_dom.apply_attr_entry(__vm_el, ("data-vm-scope", @vm_dom.attr_static("vm-2407032203")))
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
      #|pub let component_name : String = "EdgeStyleLiteral"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  @luna_core.h("div", [("class", @luna_core.attr_static("box")), ("data-vm-scope", @luna_core.attr_static("vm-2407032203"))], [])
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
      #|pub let component_name : String = "EdgeStyleLiteral"
      #|=== css ===
      #|[data-vm-scope="vm-2407032203"] .box::before { content: "</style>"; }
      #|[data-vm-scope="vm-2407032203"] .box { color: red; }
      #|=== meta ===
      #|component=EdgeStyleLiteral
      #|extension=.mbtv
      #|scope=vm-2407032203
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
test "snapshot nested template element compile" {
  let source =
    #|<template>
    #|  <section>
    #|    <template>
    #|      <span>Inner</span>
    #|    </template>
    #|  </section>
    #|</template>
  assert_snapshot(
    compile_snapshot(source, "examples/edge_nested_template.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("section")
      #|      @vm_dom.append_child(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.element("template")
      #|                @vm_dom.append_child(__vm_el.as_node(), (fn() {
      #|                                let __vm_el = @vm_dom.element("span")
      #|                                @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Inner"))
      #|                                @vm_dom.to_node(__vm_el)
      #|                              })())
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
      #|pub let component_name : String = "EdgeNestedTemplate"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  @luna_core.h("section", [], [
      #|      @luna_core.h("template", [], [
      #|          @luna_core.h("span", [], [
      #|              @luna_core.text("Inner")
      #|            ])
      #|        ])
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
      #|pub let component_name : String = "EdgeNestedTemplate"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=EdgeNestedTemplate
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
