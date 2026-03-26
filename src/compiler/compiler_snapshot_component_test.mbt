///|
test "snapshot component key ref compile" {
  let source =
    #|<script setup>
    #|let panel_ref = useTemplateRef("panel")
    #|let panel_id = 42
    #|</script>
    #|<template><Panel ref='panel' :key='panel_id' /></template>
  assert_snapshot(
    compile_snapshot(source, "examples/component_ref_key.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @v,
      #|  "mizchi/js/browser/dom" @js_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let panel_ref : @vm.TemplateRef[@js_dom.HTMLElement] = @vm.use_template_ref("panel")
      #|  let panel_id = 42
      #|  @v.componentMeta("Panel", [], [], [("data-vm-key", @v.dynAttr(fn() { panel_id.to_string() })), ("__ref", @v.on(fn(target) { @v.bindRef(panel_ref, target) }))])
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
      #|pub let component_name : String = "ComponentRefKey"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|  "mizchi/js/browser/dom" @js_dom,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let panel_ref : @vm.TemplateRef[@js_dom.HTMLElement] = @vm.use_template_ref("panel")
      #|  let panel_id = 42
      #|  @vm_server.component_ssr_meta("Panel", @vm.props_to_json([]), [], [("data-vm-key", @luna_core.attr_dynamic(fn() { panel_id.to_string() })), ("data-vm-ref", @luna_core.attr_dynamic(fn() { "panel".to_string() }))])
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
      #|pub let component_name : String = "ComponentRefKey"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=ComponentRefKey
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
