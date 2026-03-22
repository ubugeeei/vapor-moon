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

///|
test "rejects event directives without an expression" {
  let source =
    #|<template><button @click></button></template>
  assert_eq(
    compile_error(source, "invalid/event_missing_expr.mbtv"),
    "InvalidDirective(\"`@click` requires an expression\")",
  )
}

///|
test "rejects event directives without an event name" {
  let source =
    #|<template><button @='save()'></button></template>
  assert_eq(
    compile_error(source, "invalid/event_missing_name.mbtv"),
    "InvalidDirective(\"event directive requires an event name on <button>\")",
  )
}

///|
test "rejects binding directives without an attribute name" {
  let source =
    #|<template><div :='value'></div></template>
  assert_eq(
    compile_error(source, "invalid/bind_missing_name.mbtv"),
    "InvalidDirective(\"binding directive requires an attribute name on <div>\")",
  )
}

///|
test "rejects v-for bindings with more than value and index" {
  let source =
    #|<template><li v-for='(item, index, extra) in items'></li></template>
  assert_eq(
    compile_error(source, "invalid/v_for_extra_bindings.mbtv"),
    "InvalidDirective(\"invalid v-for binding: (item, index, extra) in items\")",
  )
}

///|
test "rejects trailing comma in v-for bindings" {
  let source =
    #|<template><li v-for='(item,) in items'></li></template>
  assert_eq(
    compile_error(source, "invalid/v_for_trailing_comma.mbtv"),
    "InvalidDirective(\"invalid v-for binding: (item,) in items\")",
  )
}

///|
test "rejects unparenthesized multi bindings in v-for" {
  let source =
    #|<template><li v-for='item, index in items'></li></template>
  assert_eq(
    compile_error(source, "invalid/v_for_unparenthesized_tuple.mbtv"),
    "InvalidDirective(\"invalid v-for binding: item, index in items\")",
  )
}

///|
test "rejects native v-model arguments" {
  let source =
    #|<template><input v-model:value='name' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_argument_native.mbtv"),
    "InvalidDirective(\"native v-model arguments are not supported on <input>: `value`\")",
  )
}

///|
test "rejects unsupported v-model modifiers" {
  let source =
    #|<template><input v-model.number='count' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_number_modifier.mbtv"),
    "InvalidDirective(\"unsupported v-model modifier `.number` on <input>\")",
  )
}

///|
test "rejects dynamic input type with v-model" {
  let source =
    #|<template><input :type='kind' v-model='value' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_dynamic_input_type.mbtv"),
    "InvalidDirective(\"dynamic input `type` is not supported with v-model on <input>\")",
  )
}

///|
test "rejects unsupported radio v-model" {
  let source =
    #|<template><input type='radio' v-model='picked' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_radio.mbtv"),
    "InvalidDirective(\"v-model on <input type=\\\"radio\\\"> is not supported yet\")",
  )
}

///|
test "rejects unsupported file v-model" {
  let source =
    #|<template><input type='file' v-model='file' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_file.mbtv"),
    "InvalidDirective(\"v-model on <input type=\\\"file\\\"> is not supported yet\")",
  )
}

///|
test "rejects unsupported select multiple v-model" {
  let source =
    #|<template><select multiple v-model='selected'></select></template>
  assert_eq(
    compile_error(source, "invalid/v_model_select_multiple.mbtv"),
    "InvalidDirective(\"v-model on <select multiple> is not supported yet\")",
  )
}
