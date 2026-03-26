///|
test "snapshot v-match string matching" {
  let source =
    #|<script setup>
    #|let status = "loading"
    #|</script>
    #|
    #|<template>
    #|  <div v-match='status'>
    #|    <p v-case='"loading"'>Loading...</p>
    #|    <p v-case='"error"'>Error!</p>
    #|    <p v-default>Unknown</p>
    #|  </div>
    #|</template>
  inspect(
    compile_snapshot(source, "MatchString.mbtv"),
    content=(
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let status = "loading"
      #|  match status {
      #|      "loading" =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.text("Loading..."))
      #|                @d.into(__vm_el)
      #|              })()
      #|      "error" =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.text("Error!"))
      #|                @d.into(__vm_el)
      #|              })()
      #|      _ =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.text("Unknown"))
      #|                @d.into(__vm_el)
      #|              })()
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
      #|pub let component_name : String = "MatchString"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let status = "loading"
      #|  match status {
      #|    "loading" =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text("Loading...")
      #|        ])
      #|    "error" =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text("Error!")
      #|        ])
      #|    _ =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text("Unknown")
      #|        ])
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
      #|pub let component_name : String = "MatchString"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=MatchString
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
test "snapshot v-match enum pattern" {
  let source =
    #|<script setup>
    #|let result = Ok("data")
    #|</script>
    #|
    #|<template>
    #|  <div v-match='result'>
    #|    <p v-case='Ok(data)'>{{ data }}</p>
    #|    <p v-case='Err(msg)'>{{ msg }}</p>
    #|  </div>
    #|</template>
  inspect(
    compile_snapshot(source, "MatchEnum.mbtv"),
    content=(
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let result = Ok("data")
      #|  match result {
      #|      Ok(data) =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.setText(fn() { data.to_string() }))
      #|                @d.into(__vm_el)
      #|              })()
      #|      Err(msg) =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.setText(fn() { msg.to_string() }))
      #|                @d.into(__vm_el)
      #|              })()
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
      #|pub let component_name : String = "MatchEnum"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let result = Ok("data")
      #|  match result {
      #|    Ok(data) =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { data.to_string() })
      #|        ])
      #|    Err(msg) =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { msg.to_string() })
      #|        ])
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
      #|pub let component_name : String = "MatchEnum"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=MatchEnum
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
test "snapshot v-match with wildcard default" {
  let source =
    #|<script setup>
    #|let mode = "dark"
    #|</script>
    #|
    #|<template>
    #|  <div v-match='mode'>
    #|    <p v-case='"dark"'>Dark</p>
    #|    <p v-case='_'>Default</p>
    #|  </div>
    #|</template>
  inspect(
    compile_snapshot(source, "MatchWildcard.mbtv"),
    content=(
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let mode = "dark"
      #|  match mode {
      #|      "dark" =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.text("Dark"))
      #|                @d.into(__vm_el)
      #|              })()
      #|      _ =>
      #|        (fn() {
      #|                let __vm_el = @d.el("p")
      #|                @d.append(__vm_el.as_node(), @d.text("Default"))
      #|                @d.into(__vm_el)
      #|              })()
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
      #|pub let component_name : String = "MatchWildcard"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let mode = "dark"
      #|  match mode {
      #|    "dark" =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text("Dark")
      #|        ])
      #|    _ =>
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text("Default")
      #|        ])
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
      #|pub let component_name : String = "MatchWildcard"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=MatchWildcard
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
test "v-case outside v-match is rejected" {
  let source =
    #|<template>
    #|  <div v-case='"x"'>text</div>
    #|</template>
  let error = compile_error(source, "CaseNoMatch.mbtv")
  assert_true(error.contains("v-case"))
}

///|
test "v-match with no v-case children is rejected" {
  let source =
    #|<template>
    #|  <div v-match='x'>
    #|    <p>no case here</p>
    #|  </div>
    #|</template>
  let error = compile_error(source, "MatchNoCases.mbtv")
  assert_true(error.contains("v-case"))
}

///|
test "duplicate v-default is rejected" {
  let source =
    #|<template>
    #|  <div v-match='x'>
    #|    <p v-case='"a"'>A</p>
    #|    <p v-default>B</p>
    #|    <p v-default>C</p>
    #|  </div>
    #|</template>
  let error = compile_error(source, "DupDefault.mbtv")
  assert_true(error.contains("duplicate"))
}

///|
test "non-v-case element inside v-match is rejected" {
  let source =
    #|<template>
    #|  <div v-match='x'>
    #|    <p v-case='"a"'>A</p>
    #|    <p>no case</p>
    #|  </div>
    #|</template>
  let error = compile_error(source, "MatchBadChild.mbtv")
  assert_true(error.contains("v-case"))
}

///|
test "v-case without value is rejected" {
  let source =
    #|<template>
    #|  <div v-match='x'>
    #|    <p v-case>text</p>
    #|  </div>
    #|</template>
  let error = compile_error(source, "CaseNoValue.mbtv")
  assert_true(error.contains("v-case"))
}
