///|
test "snapshot v-if v-else compile" {
  let source =
    #|<script setup>
    #|let visible = true
    #|</script>
    #|
    #|<template>
    #|  <div v-if='visible'>shown</div>
    #|  <div v-else>hidden</div>
    #|</template>
  inspect(compile_snapshot(source, "IfElse.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  let visible = true
    #|  if visible {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("div")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("shown"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    } else {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("div")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("hidden"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    }
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
    #|pub let component_name : String = "IfElse"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  let visible = true
    #|  if visible {
    #|    @luna_core.h("div", [], [
    #|        @luna_core.text("shown")
    #|      ])
    #|  } else {
    #|    @luna_core.h("div", [], [
    #|        @luna_core.text("hidden")
    #|      ])
    #|  }
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
    #|pub let component_name : String = "IfElse"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=IfElse
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
test "snapshot v-if v-else-if v-else compile" {
  let source =
    #|<script setup>
    #|let count = 0
    #|</script>
    #|
    #|<template>
    #|  <div v-if='count > 0'>positive</div>
    #|  <div v-else-if='count == 0'>zero</div>
    #|  <div v-else>negative</div>
    #|</template>
  inspect(compile_snapshot(source, "IfElseIf.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  let count = 0
    #|  if count > 0 {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("div")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("positive"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    } else if count == 0 {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("div")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("zero"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    } else {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("div")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("negative"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    }
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
    #|pub let component_name : String = "IfElseIf"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  let count = 0
    #|  if count > 0 {
    #|    @luna_core.h("div", [], [
    #|        @luna_core.text("positive")
    #|      ])
    #|  } else if count == 0 {
    #|    @luna_core.h("div", [], [
    #|        @luna_core.text("zero")
    #|      ])
    #|  } else {
    #|    @luna_core.h("div", [], [
    #|        @luna_core.text("negative")
    #|      ])
    #|  }
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
    #|pub let component_name : String = "IfElseIf"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=IfElseIf
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
test "snapshot v-if v-else-if without v-else compile" {
  let source =
    #|<script setup>
    #|let mode = "a"
    #|</script>
    #|
    #|<template>
    #|  <p v-if='mode == "a"'>alpha</p>
    #|  <p v-else-if='mode == "b"'>beta</p>
    #|</template>
  inspect(compile_snapshot(source, "IfElseIfNoElse.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  let mode = "a"
    #|  if mode == "a" {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("p")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("alpha"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    } else if mode == "b" {
    #|      (fn() {
    #|            let __vm_el = @vm_dom.element("p")
    #|            @vm_dom.append_child(__vm_el.as_node(), @vm_dom.text("beta"))
    #|            @vm_dom.to_node(__vm_el)
    #|          })()
    #|    }
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
    #|pub let component_name : String = "IfElseIfNoElse"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  let mode = "a"
    #|  if mode == "a" {
    #|    @luna_core.h("p", [], [
    #|        @luna_core.text("alpha")
    #|      ])
    #|  } else if mode == "b" {
    #|    @luna_core.h("p", [], [
    #|        @luna_core.text("beta")
    #|      ])
    #|  }
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
    #|pub let component_name : String = "IfElseIfNoElse"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=IfElseIfNoElse
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
test "snapshot v-if v-else on components compile" {
  let source =
    #|<template>
    #|  <ActivePanel v-if='active' />
    #|  <InactivePanel v-else />
    #|</template>
  inspect(compile_snapshot(source, "ConditionalComponent.mbtv"), content=(
    #|=== client ===
    #|import {
    #|  "mizchi/luna/dom" @luna_dom,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
    #|}
    #|
    #|pub fn render_dom() -> @luna_dom.DomNode {
    #|  if active {
    #|      @vm_dom.component_dom("ActivePanel", [], [])
    #|    } else {
    #|      @vm_dom.component_dom("InactivePanel", [], [])
    #|    }
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
    #|pub let component_name : String = "ConditionalComponent"
    #|=== server ===
    #|import {
    #|  "mizchi/luna/core" @luna_core,
    #|  "ubugeeei/vapor_moon/src/runtime" @vm,
    #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
    #|}
    #|
    #|pub fn render_ssr() -> @luna_core.StaticDomNode {
    #|  if active {
    #|    @vm_server.component_ssr("ActivePanel", @vm.props_to_json([]), [])
    #|  } else {
    #|    @vm_server.component_ssr("InactivePanel", @vm.props_to_json([]), [])
    #|  }
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
    #|pub let component_name : String = "ConditionalComponent"
    #|=== css ===
    #|<empty>
    #|=== meta ===
    #|component=ConditionalComponent
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
test "v-else-if without preceding v-if is rejected" {
  let source =
    #|<template>
    #|  <div v-else-if='x'>hello</div>
    #|</template>
  assert_eq(
    compile_error(source, "BadElseIf.mbtv"),
    "InvalidDirective(\"`v-else-if` requires a preceding `v-if` on <div>\")",
  )
}

///|
test "v-else after v-else is rejected" {
  let source =
    #|<template>
    #|  <div v-if='x'>a</div>
    #|  <div v-else>b</div>
    #|  <div v-else>c</div>
    #|</template>
  assert_eq(
    compile_error(source, "DoubleElse.mbtv"),
    "InvalidDirective(\"`v-else` cannot follow `v-else` on <div>\")",
  )
}

///|
test "v-else-if after v-else is rejected" {
  let source =
    #|<template>
    #|  <div v-if='x'>a</div>
    #|  <div v-else>b</div>
    #|  <div v-else-if='y'>c</div>
    #|</template>
  assert_eq(
    compile_error(source, "ElseIfAfterElse.mbtv"),
    "InvalidDirective(\"`v-else-if` cannot follow `v-else` on <div>\")",
  )
}

///|
test "v-else with value is rejected" {
  let source =
    #|<template>
    #|  <div v-if='x'>a</div>
    #|  <div v-else='y'>b</div>
    #|</template>
  assert_eq(
    compile_error(source, "ElseWithValue.mbtv"),
    "InvalidDirective(\"`v-else` does not take a value on <div>\")",
  )
}
