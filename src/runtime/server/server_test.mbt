///|
test "component ssr meta renders wrapper attrs and children" {
  let html = render_html(
    component_ssr_meta(
      "Panel",
      @vm.props_to_json([("count", "1")]),
      [@luna_core.text("body")],
      [("data-extra", @luna_core.attr_static("yes"))],
    ),
  )

  assert_true(html.contains("<vm-component"))
  assert_true(html.contains("data-vm-component=\"Panel\""))
  assert_true(html.contains("data-vm-props=\"{&quot;count&quot;:1}\""))
  assert_true(html.contains("data-extra=\"yes\""))
  assert_true(html.contains(">body</vm-component>"))
}

///|
test "hydrated islands expose luna trigger metadata and preload urls" {
  let result = @render.render_to_string(
    island_ssr(
      "Counter Panel",
      @vm.props_to_json([("count", "3")]),
      [@luna_core.text("count")],
      @vm.HydrationMode::Media("(max-width: 768px)"),
    ),
    preload=true,
  )

  assert_true(
    result.html.contains("luna:client-trigger=\"media:(max-width: 768px)\""),
  )
  assert_true(
    result.html.contains(
      "luna:url=\"" + @vm.client_module_path("Counter Panel"),
    ),
  )
  assert_true(result.html.contains("count"))
  assert_eq(result.preload_urls, [@vm.client_module_path("Counter Panel")])
}

///|
test "only and defer island modes use vapor moon shells" {
  let only_html = render_html(
    island_ssr(
      "SearchBox",
      @vm.props_to_json([("query", "hello")]),
      [@luna_core.text("fallback")],
      @vm.HydrationMode::Only,
    ),
  )
  assert_true(only_html.contains("<vm-island"))
  assert_true(only_html.contains("data-vm-island=\"SearchBox\""))
  assert_true(only_html.contains("data-vm-client=\"only\""))
  assert_true(
    only_html.contains(
      "data-vm-props=\"{&quot;query&quot;:&quot;hello&quot;}\"",
    ),
  )
  assert_false(only_html.contains("fallback"))

  let defer_html = render_html(
    island_ssr_meta(
      "ArticleChunk",
      "{}",
      [@luna_core.text("ssr")],
      @vm.HydrationMode::ServerDefer,
      [("data-extra", @luna_core.attr_static("y"))],
    ),
  )
  assert_true(defer_html.contains("<vm-server-defer"))
  assert_true(defer_html.contains("data-vm-component=\"ArticleChunk\""))
  assert_true(defer_html.contains("data-vm-props=\"{}\""))
  assert_true(defer_html.contains("data-extra=\"y\""))
  assert_true(defer_html.contains(">ssr</vm-server-defer>"))
}
