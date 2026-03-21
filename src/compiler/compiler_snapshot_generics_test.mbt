///|
test "snapshot generic component compile" {
  let output = compile(generic_source(), filename="examples/generic_list.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_eq(output.generics.length(), 2)
  assert_eq(output.generics[0].name, "T")
  assert_eq(output.generics[1].declaration, "U : Show")
  assert_snapshot(
    output.snapshot(),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub struct GenericListProps[T, U : Show] {
      #|  items : Array[T]
      #|  selected : U
      #|} derive(Eq, Show)
      #|
      #|pub struct GenericListEmits[T, U : Show] {
      #|  choose : (T) -> Unit
      #|}
      #|
      #|fn[T, U : Show] __vm_default_emits() -> GenericListEmits[T, U] {
      #|  {
      #|    choose: fn(_payload) { () },
      #|  }
      #|}
      #|
      #|pub struct GenericListDomSlots[T, U : Show] {
      #|  default : (T) -> Array[@luna_dom.DomNode]?
      #|  label : (U) -> Array[@luna_dom.DomNode]?
      #|}
      #|
      #|fn[T, U : Show] __vm_default_dom_slots() -> GenericListDomSlots[T, U] {
      #|  {
      #|    default: None,
      #|    label: None,
      #|  }
      #|}
      #|
      #|pub fn[T, U : Show] render_dom(props : GenericListProps[T, U], emit? : GenericListEmits[T, U] = __vm_default_emits(), slots? : GenericListDomSlots[T, U] = __vm_default_dom_slots()) -> @luna_dom.DomNode {
      #|  struct Props[T, U] {
      #|    items : Array[T]
      #|    selected : U
      #|  }
      #|  struct Emits[T] {
      #|    choose : T
      #|  }
      #|  struct Slots[T, U] {
      #|    default : T
      #|    label : U
      #|  }
      #|  (fn() {
      #|      let __vm_el = @vm_dom.element("section")
      #|      @vm_dom.append_children(__vm_el, [
      #|              @vm_dom.text_expr(fn() { props.items.length().to_string() })
      #|            ])
      #|      @vm_dom.to_node(__vm_el)
      #|    })()
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["items", "selected"]
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  ["choose"]
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  ["default", "label"]
      #|}
      #|
      #|pub let component_name : String = "GenericList"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub struct GenericListProps[T, U : Show] {
      #|  items : Array[T]
      #|  selected : U
      #|} derive(Eq, Show)
      #|
      #|pub struct GenericListEmits[T, U : Show] {
      #|  choose : (T) -> Unit
      #|}
      #|
      #|fn[T, U : Show] __vm_default_emits() -> GenericListEmits[T, U] {
      #|  {
      #|    choose: fn(_payload) { () },
      #|  }
      #|}
      #|
      #|pub struct GenericListSsrSlots[T, U : Show] {
      #|  default : (T) -> Array[@luna_core.StaticDomNode]?
      #|  label : (U) -> Array[@luna_core.StaticDomNode]?
      #|}
      #|
      #|fn[T, U : Show] __vm_default_ssr_slots() -> GenericListSsrSlots[T, U] {
      #|  {
      #|    default: None,
      #|    label: None,
      #|  }
      #|}
      #|
      #|pub fn[T, U : Show] render_ssr(props : GenericListProps[T, U], emit? : GenericListEmits[T, U] = __vm_default_emits(), slots? : GenericListSsrSlots[T, U] = __vm_default_ssr_slots()) -> @luna_core.StaticDomNode {
      #|  struct Props[T, U] {
      #|    items : Array[T]
      #|    selected : U
      #|  }
      #|  struct Emits[T] {
      #|    choose : T
      #|  }
      #|  struct Slots[T, U] {
      #|    default : T
      #|    label : U
      #|  }
      #|  @luna_core.h("section", [], [
      #|      @luna_core.text_dyn(fn() { props.items.length().to_string() })
      #|    ])
      #|}
      #|
      #|pub fn[T, U : Show] render_html(props : GenericListProps[T, U], emit? : GenericListEmits[T, U] = __vm_default_emits(), slots? : GenericListSsrSlots[T, U] = __vm_default_ssr_slots()) -> String {
      #|  @vm_server.render_html(render_ssr(props, emit=emit, slots=slots))
      #|}
      #|
      #|pub fn declared_props() -> Array[String] {
      #|  ["items", "selected"]
      #|}
      #|
      #|pub fn declared_emits() -> Array[String] {
      #|  ["choose"]
      #|}
      #|
      #|pub fn declared_slots() -> Array[String] {
      #|  ["default", "label"]
      #|}
      #|
      #|pub let component_name : String = "GenericList"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=GenericList
      #|extension=.mbtv
      #|scope=<none>
      #|islands=<none>
      #|props_binding=props
      #|props=items:Array[T], selected:U
      #|emits_binding=emit
      #|emits=choose:T
      #|slots_binding=slots
      #|slots=default:T, label:U
    ),
  )
}
