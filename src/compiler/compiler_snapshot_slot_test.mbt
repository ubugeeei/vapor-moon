///|
test "snapshot named slots with #shorthand" {
  let source =
    #|<template>
    #|  <MyLayout>
    #|    <template #header>
    #|      <h1>Title</h1>
    #|    </template>
    #|    <template #footer>
    #|      <p>Footer</p>
    #|    </template>
    #|    <p>Default content</p>
    #|  </MyLayout>
    #|</template>
  inspect(compile_snapshot(source, "NamedSlots.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @vm_dom.component_dom("MyLayout", [], {
    #|        header: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @vm_dom.element("h1")
    #|                        @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Title"))
    #|                        @vm_dom.to_node(__vm_el)
    #|                      })()
    #|          ] }),
    #|        footer: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @vm_dom.element("p")
    #|                        @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Footer"))
    #|                        @vm_dom.to_node(__vm_el)
    #|                      })()
    #|          ] }),
    #|        default: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @vm_dom.element("p")
    #|                        @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Default content"))
    #|                        @vm_dom.to_node(__vm_el)
    #|                      })()
    #|          ] })
    #|      })
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
    #|pub let component_name : String = "NamedSlots"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyLayout", @vm.props_to_json([]), {
    #|      header: Some(fn() { [
    #|          @luna_core.h("h1", [], [
    #|              @luna_core.text("Title")
    #|            ])
    #|        ] }),
    #|      footer: Some(fn() { [
    #|          @luna_core.h("p", [], [
    #|              @luna_core.text("Footer")
    #|            ])
    #|        ] }),
    #|      default: Some(fn() { [
    #|          @luna_core.h("p", [], [
    #|              @luna_core.text("Default content")
    #|            ])
    #|        ] })
    #|    })
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
    #|pub let component_name : String = "NamedSlots"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=NamedSlots
    #|extension=.mbtv
    #|scope=<none>
    #|islands=<none>
    #|props_binding=<none>
    #|props=<none>
    #|emits_binding=<none>
    #|emits=<none>
    #|slots_binding=<none>
    #|slots=<none>
  ))
}

///|
test "snapshot default slot only (no named slots)" {
  let source =
    #|<template>
    #|  <MyCard>
    #|    <p>Just default</p>
    #|  </MyCard>
    #|</template>
  inspect(compile_snapshot(source, "DefaultSlotOnly.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @vm_dom.component_dom("MyCard", [], [
    #|        (fn() {
    #|                let __vm_el = @vm_dom.element("p")
    #|                @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Just default"))
    #|                @vm_dom.to_node(__vm_el)
    #|              })()
    #|      ])
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
    #|pub let component_name : String = "DefaultSlotOnly"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyCard", @vm.props_to_json([]), [
    #|      @luna_core.h("p", [], [
    #|          @luna_core.text("Just default")
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
    #|pub let component_name : String = "DefaultSlotOnly"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=DefaultSlotOnly
    #|extension=.mbtv
    #|scope=<none>
    #|islands=<none>
    #|props_binding=<none>
    #|props=<none>
    #|emits_binding=<none>
    #|emits=<none>
    #|slots_binding=<none>
    #|slots=<none>
  ))
}

///|
test "snapshot v-slot:name full syntax" {
  let source =
    #|<template>
    #|  <MyDialog>
    #|    <template v-slot:body>
    #|      <p>Body content</p>
    #|    </template>
    #|    <template v-slot:actions>
    #|      <button>OK</button>
    #|    </template>
    #|  </MyDialog>
    #|</template>
  inspect(compile_snapshot(source, "VSlotSyntax.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @vm_dom.component_dom("MyDialog", [], {
    #|        body: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @vm_dom.element("p")
    #|                        @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("Body content"))
    #|                        @vm_dom.to_node(__vm_el)
    #|                      })()
    #|          ] }),
    #|        actions: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @vm_dom.element("button")
    #|                        @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("OK"))
    #|                        @vm_dom.to_node(__vm_el)
    #|                      })()
    #|          ] })
    #|      })
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
    #|pub let component_name : String = "VSlotSyntax"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyDialog", @vm.props_to_json([]), {
    #|      body: Some(fn() { [
    #|          @luna_core.h("p", [], [
    #|              @luna_core.text("Body content")
    #|            ])
    #|        ] }),
    #|      actions: Some(fn() { [
    #|          @luna_core.h("button", [], [
    #|              @luna_core.text("OK")
    #|            ])
    #|        ] })
    #|    })
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
    #|pub let component_name : String = "VSlotSyntax"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=VSlotSyntax
    #|extension=.mbtv
    #|scope=<none>
    #|islands=<none>
    #|props_binding=<none>
    #|props=<none>
    #|emits_binding=<none>
    #|emits=<none>
    #|slots_binding=<none>
    #|slots=<none>
  ))
}
