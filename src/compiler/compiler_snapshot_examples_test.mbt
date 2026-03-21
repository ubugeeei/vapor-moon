///|
test "snapshot reactivity basics compile" {
  assert_snapshot(
    compile_snapshot(
      reactivity_basics_source(),
      "examples/reactivity_basics.mbtv",
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
      #|  let count = signal(1)
      #|  let doubled = computed(fn() { count.get() * 2 })
      #|  let summary = computed(fn() {
      #|    "count=" + count.get().to_string() + ", doubled=" + doubled().to_string()
      #|  })
      #|  let history = signal("1 -> 1")
      #|  let summary_effect = effect(fn() { ignore(summary()) })
      #|  let count_watch = watch(fn() { count.get() }, fn(next, prev) {
      #|    history.set(prev.to_string() + " -> " + next.to_string())
      #|  })
      #|  @luna_dom.create_element("section", [("class", @luna_dom.attr_static("reactivity"))], [
      #|      @luna_dom.create_element("button", [("click", @luna_dom.attr_handler(fn(_event) { count.update(fn(n) { n + 1 }) }))], [
      #|          @luna_dom.text("+")
      #|        ]),
      #|      @luna_dom.create_element("p", [], [
      #|          @luna_dom.text_dyn(fn() { summary().to_string() })
      #|        ]),
      #|      @luna_dom.create_element("small", [], [
      #|          @luna_dom.text_dyn(fn() { history.get().to_string() })
      #|        ])
      #|    ])
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
      #|pub let component_name : String = "ReactivityBasics"
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
      #|  let count = signal(1)
      #|  let doubled = computed(fn() { count.get() * 2 })
      #|  let summary = computed(fn() {
      #|    "count=" + count.get().to_string() + ", doubled=" + doubled().to_string()
      #|  })
      #|  let history = signal("1 -> 1")
      #|  let summary_effect = effect(fn() { ignore(summary()) })
      #|  let count_watch = watch(fn() { count.get() }, fn(next, prev) {
      #|    history.set(prev.to_string() + " -> " + next.to_string())
      #|  })
      #|  @luna_core.h("section", [("class", @luna_core.attr_static("reactivity"))], [
      #|      @luna_core.h("button", [], [
      #|          @luna_core.text("+")
      #|        ]),
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { summary().to_string() })
      #|        ]),
      #|      @luna_core.h("small", [], [
      #|          @luna_core.text_dyn(fn() { history.get().to_string() })
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
      #|pub let component_name : String = "ReactivityBasics"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=ReactivityBasics
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
test "snapshot lifecycle refs compile" {
  assert_snapshot(
    compile_snapshot(lifecycle_refs_source(), "examples/lifecycle_refs.mbtv"),
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
      #|  let on_mount = @reactivity.on_mount,
      #|  let on_cleanup = @reactivity.on_cleanup,
      #|  let root_ref = @vm.use_template_ref("root")
      #|  let instance_id = @vm.use_id(component_name, 0)
      #|  let phase = signal("booting")
      #|  let mount_registration = on_mount(fn() {
      #|    phase.set("mounted:" + instance_id)
      #|    on_cleanup(fn() {
      #|      ignore(root_ref)
      #|    })
      #|  })
      #|  @luna_dom.create_element("section", [("data-id", @luna_dom.attr_dynamic(fn() { instance_id.to_string() })), ("__ref", @luna_dom.attr_handler(fn(target) { @vm_dom.bind_template_ref("root", target) }))], [
      #|      @luna_dom.create_element("p", [], [
      #|          @luna_dom.text_dyn(fn() { phase.get().to_string() })
      #|        ]),
      #|      @luna_dom.create_element("p", [], [
      #|          @luna_dom.text_dyn(fn() { instance_id.to_string() })
      #|        ])
      #|    ])
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
      #|pub let component_name : String = "LifecycleRefs"
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
      #|  let on_mount = @reactivity.on_mount,
      #|  let on_cleanup = @reactivity.on_cleanup,
      #|  let root_ref = @vm.use_template_ref("root")
      #|  let instance_id = @vm.use_id(component_name, 0)
      #|  let phase = signal("booting")
      #|  let mount_registration = on_mount(fn() {
      #|    phase.set("mounted:" + instance_id)
      #|    on_cleanup(fn() {
      #|      ignore(root_ref)
      #|    })
      #|  })
      #|  @luna_core.h("section", [("data-id", @luna_core.attr_dynamic(fn() { instance_id.to_string() })), ("data-vm-ref", @luna_core.attr_dynamic(fn() { "root".to_string() }))], [
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { phase.get().to_string() })
      #|        ]),
      #|      @luna_core.h("p", [], [
      #|          @luna_core.text_dyn(fn() { instance_id.to_string() })
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
      #|pub let component_name : String = "LifecycleRefs"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=LifecycleRefs
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
