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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @dom.component("MyLayout", [], {
    #|        header: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @dom.el("h1")
    #|                        @dom.append(__vm_el.as_node(), @dom.text("Title"))
    #|                        @dom.into(__vm_el)
    #|                      })()
    #|          ] }),
    #|        footer: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @dom.el("p")
    #|                        @dom.append(__vm_el.as_node(), @dom.text("Footer"))
    #|                        @dom.into(__vm_el)
    #|                      })()
    #|          ] }),
    #|        default: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @dom.el("p")
    #|                        @dom.append(__vm_el.as_node(), @dom.text("Default content"))
    #|                        @dom.into(__vm_el)
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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyLayout", @hlp.props_to_json([]), {
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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @dom.component("MyCard", [], [
    #|        (fn() {
    #|                let __vm_el = @dom.el("p")
    #|                @dom.append(__vm_el.as_node(), @dom.text("Just default"))
    #|                @dom.into(__vm_el)
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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyCard", @hlp.props_to_json([]), [
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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  @dom.component("MyDialog", [], {
    #|        body: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @dom.el("p")
    #|                        @dom.append(__vm_el.as_node(), @dom.text("Body content"))
    #|                        @dom.into(__vm_el)
    #|                      })()
    #|          ] }),
    #|        actions: Some(fn() { [
    #|            (fn() {
    #|                        let __vm_el = @dom.el("button")
    #|                        @dom.append(__vm_el.as_node(), @dom.text("OK"))
    #|                        @dom.into(__vm_el)
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
    #|  "ubugeeei/vapor_moon/src/runtime" @hlp,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  @vm_server.component_ssr("MyDialog", @hlp.props_to_json([]), {
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
