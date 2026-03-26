///|
test "snapshot composable counter compile" {
  assert_snapshot(
    compile_snapshot(
      composable_counter_source(),
      "examples/composable_counter.mbtv",
    ),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let signal = @reactivity.signal,
      #|  let computed = @reactivity.computed,
      #|  let watch = @reactivity.watch,
      #|  let effect = @reactivity.effect,
      #|  struct CounterComposable {
      #|    count : @reactivity.Signal[Int]
      #|    doubled : () -> Int
      #|    last_change : @reactivity.Signal[String]
      #|  }
      #|  fn useCounter(initial : Int) -> CounterComposable {
      #|    let count = signal(initial)
      #|    let doubled = computed(fn() { count.get() * 2 })
      #|    let last_change = signal("ready")
      #|    let doubled_effect = effect(fn() { ignore(doubled()) })
      #|    let change_watch = watch(fn() { count.get() }, fn(next, prev) {
      #|      last_change.set(prev.to_string() + " -> " + next.to_string())
      #|    })
      #|    { count, doubled, last_change }
      #|  }
      #|  let counter = useCounter(2)
      #|  (fn() {
      #|      let __vm_el = @vm_dom.el("section")
      #|      @vm_dom.setAttr(__vm_el, ("class", @vm_dom.attr("composable")))
      #|      @vm_dom.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.el("button")
      #|                @vm_dom.setAttr(__vm_el, ("click", @vm_dom.on(fn(_event) { counter.count.update(fn(n) { n + 1 }) })))
      #|                @vm_dom.append(__vm_el.as_node(), @vm_dom.text("inc"))
      #|                @vm_dom.into(__vm_el)
      #|              })())
      #|      @vm_dom.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.el("p")
      #|                @vm_dom.append(__vm_el.as_node(), @vm_dom.setText(fn() { counter.count.get().to_string() }))
      #|                @vm_dom.into(__vm_el)
      #|              })())
      #|      @vm_dom.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.el("p")
      #|                @vm_dom.append(__vm_el.as_node(), @vm_dom.setText(fn() { counter.doubled().to_string() }))
      #|                @vm_dom.into(__vm_el)
      #|              })())
      #|      @vm_dom.append(__vm_el.as_node(), (fn() {
      #|                let __vm_el = @vm_dom.el("small")
      #|                @vm_dom.append(__vm_el.as_node(), @vm_dom.setText(fn() { counter.last_change.get().to_string() }))
      #|                @vm_dom.into(__vm_el)
      #|              })())
      #|      @vm_dom.into(__vm_el)
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
      #|pub let component_name : String = "ComposableCounter"
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
      #|  let computed = @reactivity.computed,
      #|  let watch = @reactivity.watch,
      #|  let effect = @reactivity.effect,
      #|  struct CounterComposable {
      #|    count : @reactivity.Signal[Int]
      #|    doubled : () -> Int
      #|    last_change : @reactivity.Signal[String]
      #|  }
      #|  fn useCounter(initial : Int) -> CounterComposable {
      #|    let count = signal(initial)
      #|    let doubled = computed(fn() { count.get() * 2 })
      #|    let last_change = signal("ready")
      #|    let doubled_effect = effect(fn() { ignore(doubled()) })
      #|    let change_watch = watch(fn() { count.get() }, fn(next, prev) {
      #|      last_change.set(prev.to_string() + " -> " + next.to_string())
      #|    })
      #|    { count, doubled, last_change }
      #|  }
      #|  let counter = useCounter(2)
      #|  @luna_core.h("section", [("class", @luna_core.attr_static("composable"))], [
      #|      @luna_core.h("button", [], [
      #|          @luna_core.text("inc")
      #|        ]),
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { counter.count.get().to_string() })
      #|        ]),
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { counter.doubled().to_string() })
      #|        ]),
      #|      @luna_core.h("small", [], [
      #|          @luna_core.text_dyn(fn() { counter.last_change.get().to_string() })
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
      #|pub let component_name : String = "ComposableCounter"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=ComposableCounter
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
