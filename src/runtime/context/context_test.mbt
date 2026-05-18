///|
test "provide stores and returns the value unchanged" {
  reset_for_tests()
  let returned = provide("theme", "dark")
  assert_eq(returned, "dark")
}

///|
test "inject returns Some for a previously provided key" {
  reset_for_tests()
  ignore(provide("locale", "ja"))
  let value : String? = inject("locale")
  assert_eq(value, Some("ja"))
}

///|
test "inject returns None for an unknown key" {
  reset_for_tests()
  let value : String? = inject("nonexistent")
  assert_eq(value, None)
}

///|
test "inject_or falls back to the default when nothing was provided" {
  reset_for_tests()
  let value = inject_or("missing", "fallback")
  assert_eq(value, "fallback")
}

///|
test "provide overwrites a previous value for the same key (Phase 1 flat scope)" {
  reset_for_tests()
  ignore(provide("counter", 1))
  ignore(provide("counter", 2))
  let value : Int? = inject("counter")
  assert_eq(value, Some(2))
}

///|
test "different keys do not collide" {
  reset_for_tests()
  ignore(provide("a", 1))
  ignore(provide("b", 2))
  let a : Int? = inject("a")
  let b : Int? = inject("b")
  assert_eq(a, Some(1))
  assert_eq(b, Some(2))
}
