///|
test "snapshot island visible compile" {
  assert_snapshot(
    compile_snapshot(island_visible_source(), "examples/island_visible.mbtv"),
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
      #|  let count = signal(3)
      #|  (fn() {
      #|      let __vm_el = @vm_dom.el("section")
      #|      @vm_dom.append(__vm_el.as_node(), @vm_dom.island("CounterPanel", @vm.HydrationMode::Visible, [("count", fn() { count.get().to_string() })], []))
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
      #|pub let component_name : String = "IslandVisible"
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
      #|  let count = signal(3)
      #|  @luna_core.h("section", [], [
      #|      @vm_server.island_ssr("CounterPanel", @vm.props_to_json([("count", count.get().to_string())]), [], @vm.HydrationMode::Visible)
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
      #|pub let component_name : String = "IslandVisible"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=IslandVisible
      #|extension=.mbtv
      #|scope=<none>
      #|islands=CounterPanel
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
test "snapshot directives compile" {
  assert_snapshot(
    compile_snapshot(directives_source(), "examples/directives.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let items = [1, 2, 3]
      #|  let visible = true
      #|  @vm_dom.show(fn() { visible }, fn() { (fn() {
      #|      let __vm_el = @vm_dom.el("ul")
      #|      @vm_dom.append(__vm_el.as_node(), @vm_dom.each(fn() { items }, fn(item, index) { (fn() {
      #|                let __vm_el = @vm_dom.el("li")
      #|                @vm_dom.append(__vm_el.as_node(), @vm_dom.setText(fn() { item.to_string() + ":" + index.to_string().to_string() }))
      #|                @vm_dom.into(__vm_el)
      #|              })() }))
      #|      @vm_dom.into(__vm_el)
      #|    })() })
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
      #|pub let component_name : String = "Directives"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let items = [1, 2, 3]
      #|  let visible = true
      #|  @luna_core.show(fn() { visible }, fn() { @luna_core.h("ul", [], [
      #|      @luna_core.for_each(fn() { items.map(fn(item, index) { @luna_core.h("li", [], [
      #|          @luna_core.text_dyn(fn() { item.to_string() + ":" + index.to_string().to_string() })
      #|        ]) }) })
      #|    ]) })
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
      #|pub let component_name : String = "Directives"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=Directives
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
test "snapshot media and defer compile" {
  assert_snapshot(
    compile_snapshot(media_and_defer_source(), "examples/media_and_defer.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @vm_dom,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  (fn() {
      #|      let __vm_el = @vm_dom.el("main")
      #|      @vm_dom.append(__vm_el.as_node(), @vm_dom.island("HeroBanner", @vm.HydrationMode::Media("(max-width: 768px)"), [], []))
      #|      @vm_dom.append(__vm_el.as_node(), @vm_dom.island("ArticleChunk", @vm.HydrationMode::ServerDefer, [], []))
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
      #|pub let component_name : String = "MediaAndDefer"
      #|=== server ===
      #|import {
      #|  "mizchi/luna/core" @luna_core,
      #|  "ubugeeei/vapor_moon/src/runtime" @vm,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  @luna_core.h("main", [], [
      #|      @vm_server.island_ssr("HeroBanner", @vm.props_to_json([]), [], @vm.HydrationMode::Media("(max-width: 768px)")),
      #|      @vm_server.island_ssr("ArticleChunk", @vm.props_to_json([]), [], @vm.HydrationMode::ServerDefer)
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
      #|pub let component_name : String = "MediaAndDefer"
      #|=== css ===
      #|<empty>
      #|=== meta ===
      #|component=MediaAndDefer
      #|extension=.mbtv
      #|scope=<none>
      #|islands=HeroBanner, ArticleChunk
      #|props_binding=<none>
      #|props=<none>
      #|emits_binding=<none>
      #|emits=<none>
      #|slots_binding=<none>
      #|slots=<none>
    ),
  )
}
