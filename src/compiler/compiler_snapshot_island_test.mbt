///|
test "snapshot island visible compile" {
  assert_snapshot(
    compile_snapshot(island_visible_source(), "examples/island_visible.mbtv"),
    (
      #|=== client ===
      #|import {
      #|  "mizchi/luna/dom" @luna_dom,
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let signal = @reactivity.signal,
      #|  let count = signal(3)
      #|  (fn() {
      #|      let __vm_el = @d.el("section")
      #|      @d.append(__vm_el.as_node(), @d.island("CounterPanel", @r.HydrationMode::Visible, [("count", fn() { count.get().to_string() })], []))
      #|      @d.into(__vm_el)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|  "mizchi/luna/js/resource" @reactivity,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  let signal = @reactivity.signal,
      #|  let count = signal(3)
      #|  @luna_core.h("section", [], [
      #|      @vm_server.island_ssr("CounterPanel", @r.props_to_json([("count", count.get().to_string())]), [], @r.HydrationMode::Visible)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  let items = [1, 2, 3]
      #|  let visible = true
      #|  @d.show(fn() { visible }, fn() { (fn() {
      #|      let __vm_el = @d.el("ul")
      #|      @d.append(__vm_el.as_node(), @d.each(fn() { items }, fn(item, index) { (fn() {
      #|                let __vm_el = @d.el("li")
      #|                @d.append(__vm_el.as_node(), @d.setText(fn() { item.to_string() + ":" + index.to_string().to_string() }))
      #|                @d.into(__vm_el)
      #|              })() }))
      #|      @d.into(__vm_el)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/dom" @d,
      #|}
      #|
      #|pub fn render_dom() -> @luna_dom.DomNode {
      #|  (fn() {
      #|      let __vm_el = @d.el("main")
      #|      @d.append(__vm_el.as_node(), @d.island("HeroBanner", @r.HydrationMode::Media("(max-width: 768px)"), [], []))
      #|      @d.append(__vm_el.as_node(), @d.island("ArticleChunk", @r.HydrationMode::ServerDefer, [], []))
      #|      @d.into(__vm_el)
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
      #|  "ubugeeei/vapor_moon/src/runtime" @r,
      #|  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
      #|}
      #|
      #|pub fn render_ssr() -> @luna_core.StaticDomNode {
      #|  @luna_core.h("main", [], [
      #|      @vm_server.island_ssr("HeroBanner", @r.props_to_json([]), [], @r.HydrationMode::Media("(max-width: 768px)")),
      #|      @vm_server.island_ssr("ArticleChunk", @r.props_to_json([]), [], @r.HydrationMode::ServerDefer)
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
