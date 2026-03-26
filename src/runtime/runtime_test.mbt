///|
fn assert_trimmed_eq(actual : String, expected : String) -> Unit raise {
  assert_eq(actual.trim().to_string(), expected.trim().to_string())
}

///|
test "client helpers sanitize names consistently" {
  let path = client_module_path("Hero Banner!")
  let scope_id = make_scope_id("Hero Banner!")
  let id = use_id("Hero Banner!", 3)
  let ref_ : TemplateRef[Int] = use_template_ref("root")

  assert_true(path.has_prefix("/_vapor_moon/Hero_Banner_"))
  assert_true(path.has_suffix(".js"))
  assert_false(path.contains(" "))
  assert_false(path.contains("!"))
  assert_true(scope_id.has_prefix("vm-"))
  assert_true(id.has_prefix("Hero_Banner_"))
  assert_true(id.has_suffix("-id-3"))
  assert_eq(ref_.name(), "root")
}

///|
test "props_to_json escapes strings and preserves literals" {
  assert_eq(props_to_json([]), "{}")
  assert_eq(
    props_to_json([
      ("title", "hello"),
      ("count", "42"),
      ("enabled", "true"),
      ("missing", "null"),
      ("ratio", "3.5"),
      ("note", "line\n\"quote\"\t\\slash"),
    ]),
    "{\"title\":\"hello\",\"count\":42,\"enabled\":true,\"missing\":null,\"ratio\":3.5,\"note\":\"line\\n\\\"quote\\\"\\t\\\\slash\"}",
  )
}

///|
test "scope_css scopes nested media rules and preserves keyframes" {
  let source =
    #|.box, .card { color: red; }
    #|@media (max-width: 768px) {
    #|  .box, .card { color: blue; }
    #|}
    #|@keyframes fade {
    #|  from { opacity: 0; }
    #|  to { opacity: 1; }
    #|}

  assert_trimmed_eq(
    scope_css(source, "vm-123"),
    (
      #|[data-vm-scope="vm-123"] .box, [data-vm-scope="vm-123"] .card { color: red; }
      #|@media (max-width: 768px) { [data-vm-scope="vm-123"] .box, [data-vm-scope="vm-123"] .card { color: blue; } }
      #|@keyframes fade { from { opacity: 0; }
      #|  to { opacity: 1; } }
    ),
  )
}

///|
test "show_style merges hidden state into base styles" {
  assert_eq(show_style(false, ""), "display: none;")
  assert_eq(show_style(false, "color: red"), "color: red; display: none;")
  assert_eq(show_style(false, "color: red;"), "color: red; display: none;")
  assert_eq(show_style(true, "  color: red  "), "color: red")
}

///|
test "merge helpers ignore blank segments" {
  assert_eq(merge_class_names(["panel", " ", "accent  ", ""]), "panel accent")
  assert_eq(
    merge_styles(["display: flex", " ", "color: red;", "\nbackground: blue\n"]),
    "display: flex; color: red; background: blue;",
  )
}
