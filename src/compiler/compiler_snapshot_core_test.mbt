///|
test "snapshot basic compile" {
  assert_snapshot(
    compile_snapshot(basic_source(), "examples/basic.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @v,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let signal = @reactivity.signal,
      #|  let count = signal(0)
      #|  (fn() {
      #|      let __vm_el = @v.el("div")
      #|      @v.setAttr(__vm_el, ("class", @v.attr("counter")))
      #|      @v.setAttr(__vm_el, ("data-vm-scope", @v.attr("vm-4048536636")))
      #|      @v.append(__vm_el.as_node(), @v.setText(fn() { count.get().to_string() }))
      #|      @v.into(__vm_el)
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
      #|pub let component_name : String = "Basic"
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
      #|  let count = signal(0)
      #|  @luna_core.h("div", [("class", @luna_core.attr_static("counter")), ("data-vm-scope", @luna_core.attr_static("vm-4048536636"))], [
      #|      @luna_core.text_dyn(fn() { count.get().to_string() })
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
      #|pub let component_name : String = "Basic"
      #|=== css ===
      #|[data-vm-scope="vm-4048536636"] .counter { color: red; }
      #|=== meta ===
      #|component=Basic
      #|extension=.mbtv
      #|scope=vm-4048536636
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
test "snapshot macros compile" {
  assert_snapshot(
    compile_snapshot(macros_source(), "examples/macros.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @v,
      #|}
      #|
      #|pub struct MacrosProps {
      #|  title : String
      #|  count : Int
      #|} derive(Eq, Show)
      #|
      #|pub struct MacrosEmits {
      #|  save : (String) -> Unit
      #|  cancel : () -> Unit
      #|}
      #|
      #|fn __vm_default_emits() -> MacrosEmits {
      #|  {
      #|    save: fn(_payload) { () },
      #|    cancel: fn() { () },
      #|  }
      #|}
      #|
      #|pub fn render_dom(props : MacrosProps, emit? : MacrosEmits = __vm_default_emits()) -> @luna_dom.DomNode {
      #|  struct Props {
      #|    title : String
      #|    count : Int
      #|  }
      #|  struct Emits {
      #|    save : String
      #|    cancel : Unit
      #|  }
      #|  (fn() {
      #|      let __vm_el = @v.el("button")
      #|      @v.setAttr(__vm_el, ("click", @v.on(fn(_event) { emit.save() })))
      #|      @v.setAttr(__vm_el, ("class", @v.attr("primary")))
      #|      @v.append(__vm_el.as_node(), @v.setText(fn() { props.title.to_string() }))
      #|      @v.into(__vm_el)
      #|    })()
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["title", "count"]
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  ["save", "cancel"]
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "Macros"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub struct MacrosProps {
      #|  title : String
      #|  count : Int
      #|} derive(Eq, Show)
      #|
      #|pub struct MacrosEmits {
      #|  save : (String) -> Unit
      #|  cancel : () -> Unit
      #|}
      #|
      #|fn __vm_default_emits() -> MacrosEmits {
      #|  {
      #|    save: fn(_payload) { () },
      #|    cancel: fn() { () },
      #|  }
      #|}
      #|
      #|pub fn render_ssr(props : MacrosProps, emit? : MacrosEmits = __vm_default_emits()) -> @luna_core.StaticDomNode {
      #|  struct Props {
      #|    title : String
      #|    count : Int
      #|  }
      #|  struct Emits {
      #|    save : String
      #|    cancel : Unit
      #|  }
      #|  @luna_core.h("button", [("class", @luna_core.attr_static("primary"))], [
      #|      @luna_core.text_dyn(fn() { props.title.to_string() })
      #|    ])
      #|}
      #|
      #|pub fn render_html(props : MacrosProps, emit? : MacrosEmits = __vm_default_emits()) -> String {
      #|  @vm_server.render_html(render_ssr(props, emit=emit))
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["title", "count"]
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  ["save", "cancel"]
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  []
      #|}
      #|
      #|pub let component_name : String = "Macros"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=Macros
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=props
      #|props=title:String, count:Int
      #|emits_binding=emit
      #|emits=save:String, cancel:Unit
      #|slots_binding=<none>
      #|slots=<none>
    ),
  )
}
