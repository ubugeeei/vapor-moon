///|
test "snapshot slot contracts compile" {
  assert_snapshot(
    compile_snapshot(slots_source(), "examples/slots.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub struct SlotsDomSlots {
      #|  default : () -> Array[@luna_dom.DomNode]?
      #|  footer : (String) -> Array[@luna_dom.DomNode]?
      #|}
      #|
      #|fn __vm_default_dom_slots() -> SlotsDomSlots {
      #|  {
      #|    default: None,
      #|    footer: None,
      #|  }
      #|}
      #|
      #|pub fn render_dom(slots? : SlotsDomSlots = __vm_default_dom_slots()) -> @luna_dom.DomNode {
      #|  struct Slots {
      #|    default : Unit
      #|    footer : String
      #|  }
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("section")
      #|      @vm_dom.apply_attr_entry(__vm_el, ("class", @vm_dom.attr_static("shell")))
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
      #|  ["default", "footer"]
      #|}
      #|
      #|pub let component_name : String = "Slots"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub struct SlotsSsrSlots {
      #|  default : () -> Array[@luna_core.StaticDomNode]?
      #|  footer : (String) -> Array[@luna_core.StaticDomNode]?
      #|}
      #|
      #|fn __vm_default_ssr_slots() -> SlotsSsrSlots {
      #|  {
      #|    default: None,
      #|    footer: None,
      #|  }
      #|}
      #|
      #|pub fn render_ssr(slots? : SlotsSsrSlots = __vm_default_ssr_slots()) -> @luna_core.StaticDomNode {
      #|  struct Slots {
      #|    default : Unit
      #|    footer : String
      #|  }
      #|  @luna_core.h("section", [("class", @luna_core.attr_static("shell"))], [])
      #|}
      #|
      #|pub fn render_html(slots? : SlotsSsrSlots = __vm_default_ssr_slots()) -> String {
      #|  @vm_server.render_html(render_ssr(slots=slots))
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
      #|  ["default", "footer"]
      #|}
      #|
      #|pub let component_name : String = "Slots"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=Slots
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=<none>
      #|props=<none>
      #|emits_binding=<none>
      #|emits=<none>
      #|slots_binding=slots
      #|slots=default:Unit, footer:String
    ),
  )
}
