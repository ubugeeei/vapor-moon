///|
test "rejects v-html mixed with child nodes" {
  let source =
    #|<template>
    #|  <div v-html='content'><span>fallback</span></div>
    #|</template>
  assert_eq(
    compile_error(source, "invalid/v_html_children.mbtv"),
    "InvalidDirective(\"v-html cannot be combined with child nodes on <div>\")",
  )
}

///|
test "rejects duplicate island directives on the same component" {
  let source =
    #|<template>
    #|  <Panel client:load client:visible />
    #|</template>
  assert_eq(
    compile_error(source, "invalid/duplicate_island_mode.mbtv"),
    "InvalidDirective(\"multiple island directives are not allowed on <Panel>: `client:load` and `client:visible`\")",
  )
}

///|
test "rejects island directives on native elements even for client none" {
  let source =
    #|<template><div client:none /></template>
  assert_eq(
    compile_error(source, "invalid/client_none_native.mbtv"),
    "InvalidDirective(\"island directives can only be used on component tags: <div>\")",
  )
}

///|
test "rejects client media without a value" {
  let source =
    #|<template><Panel client:media /></template>
  assert_eq(
    compile_error(source, "invalid/client_media_missing_value.mbtv"),
    "InvalidDirective(\"`client:media` requires a value on <Panel>\")",
  )
}

///|
test "rejects v-model without an expression" {
  let source =
    #|<template><input v-model /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_missing_expr.mbtv"),
    "InvalidDirective(\"`v-model` requires an expression\")",
  )
}

///|
test "rejects v-model on unsupported native elements" {
  let source =
    #|<template><div v-model='count'></div></template>
  assert_eq(
    compile_error(source, "invalid/v_model_div.mbtv"),
    "InvalidDirective(\"v-model is only supported on form controls or component tags: <div>\")",
  )
}

///|
test "rejects component event listeners until component linking lands" {
  let source =
    #|<template><Panel @save='on_save()' /></template>
  assert_eq(
    compile_error(source, "invalid/component_event_listener.mbtv"),
    "InvalidDirective(\"component event listeners are not supported yet on <Panel>\")",
  )
}

///|
test "rejects component v-model until component linking lands" {
  let source =
    #|<template><Panel v-model='value' /></template>
  assert_eq(
    compile_error(source, "invalid/component_v_model.mbtv"),
    "InvalidDirective(\"component v-model is not supported yet on <Panel>\")",
  )
}

///|
test "rejects unsupported slot outlet syntax" {
  let source =
    #|<template><Panel #default></Panel></template>
  assert_eq(
    compile_error(source, "invalid/slot_outlet.mbtv"),
    "InvalidDirective(\"slot outlet syntax is not supported yet on <Panel>\")",
  )
}

///|
test "rejects duplicate key bindings" {
  let source =
    #|<template><div key='a' :key='id'></div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_key.mbtv"),
    "InvalidDirective(\"duplicate `:key` on <div>\")",
  )
}
