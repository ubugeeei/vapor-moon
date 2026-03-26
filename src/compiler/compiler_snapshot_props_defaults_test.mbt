///|
test "snapshot props defaults compile" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|  tone : String
    #|}
    #|
    #|let props : Props = defineProps({
    #|  count: 0,
    #|  tone: "primary",
    #|})
    #|</script>
    #|
    #|<template>
    #|  <div>{{ props.title + ":" + props.count.to_string() + ":" + props.tone }}</div>
    #|</template>
  assert_snapshot(
    compile_snapshot(source, "examples/props_defaults.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub struct PropsDefaultsProps {
      #|  title : String
      #|  count : Int?
      #|  tone : String?
      #|} derive(Eq, Show)
      #|
      #|pub fn render_dom(__vm_props_input : PropsDefaultsProps) -> @luna_dom.DomNode {
      #|  struct Props {
      #|    title : String
      #|    count : Int
      #|    tone : String
      #|  }
      #|  let props : Props = {
      #|    title: __vm_props_input.title,
      #|    count: __vm_props_input.count.unwrap_or(0),
      #|    tone: __vm_props_input.tone.unwrap_or("primary"),
      #|  }
      #|  (fn() {
      #|      let __vm_el = @vm_dom.el("div")
      #|      @vm_dom.append(__vm_el.as_node(), @vm_dom.setText(fn() { props.title + ":" + props.count.to_string() + ":" + props.tone.to_string() }))
      #|      @vm_dom.into(__vm_el)
      #|    })()
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["title", "count", "tone"]
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
      #|pub let component_name : String = "PropsDefaults"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub struct PropsDefaultsProps {
      #|  title : String
      #|  count : Int?
      #|  tone : String?
      #|} derive(Eq, Show)
      #|
      #|pub fn render_ssr(__vm_props_input : PropsDefaultsProps) -> @luna_core.StaticDomNode {
      #|  struct Props {
      #|    title : String
      #|    count : Int
      #|    tone : String
      #|  }
      #|  let props : Props = {
      #|    title: __vm_props_input.title,
      #|    count: __vm_props_input.count.unwrap_or(0),
      #|    tone: __vm_props_input.tone.unwrap_or("primary"),
      #|  }
      #|  @luna_core.h("div", [], [
      #|      @luna_core.text_dyn(fn() { props.title + ":" + props.count.to_string() + ":" + props.tone.to_string() })
      #|    ])
      #|}
      #|
      #|pub fn render_html(__vm_props_input : PropsDefaultsProps) -> String {
      #|  @vm_server.render_html(render_ssr(__vm_props_input))
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["title", "count", "tone"]
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
      #|pub let component_name : String = "PropsDefaults"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=PropsDefaults
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=props
      #|props=title:String, count:Int, tone:String
      #|emits_binding=<none>
      #|emits=<none>
      #|slots_binding=<none>
      #|slots=<none>
    ),
  )
}
