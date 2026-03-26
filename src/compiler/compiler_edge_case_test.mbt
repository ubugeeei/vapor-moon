///|
test "rejects v-unsafe-html mixed with child nodes" {
  let source =
    #|<template>
    #|  <div v-unsafe-html='content'><span>fallback</span></div>
    #|</template>
  assert_eq(
    compile_error(source, "invalid/v_unsafe_html_children.mbtv"),
    "InvalidDirective(\"v-unsafe-html cannot be combined with child nodes on <div>\")",
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
test "rejects values on flag island directives" {
  let source =
    #|<template><Panel client:load='eager' /></template>
  assert_eq(
    compile_error(source, "invalid/client_load_with_value.mbtv"),
    "InvalidDirective(\"`client:load` does not take a value on <Panel>\")",
  )
}

///|
test "rejects unexpected closing tags in templates" {
  let source =
    #|<template></div></template>
  assert_eq(
    compile_error(source, "invalid/unexpected_closing_tag.mbtv"),
    "InvalidTemplate(\"unexpected closing tag </div>\")",
  )
}

///|
test "rejects mismatched closing tags in templates" {
  let source =
    #|<template><div></span></template>
  assert_eq(
    compile_error(source, "invalid/mismatched_closing_tag.mbtv"),
    "InvalidTemplate(\"expected </div>, got </span>\")",
  )
}

///|
test "rejects missing closing tags in templates" {
  let source =
    #|<template><div></template>
  assert_eq(
    compile_error(source, "invalid/missing_closing_tag.mbtv"),
    "InvalidTemplate(\"missing closing tag </div>\")",
  )
}

///|
test "rejects unterminated attribute values" {
  let source =
    #|<template><div title='oops></div></template>
  assert_eq(
    compile_error(source, "invalid/unterminated_attr_value.mbtv"),
    "InvalidTemplate(\"unterminated attribute value\")",
  )
}

///|
test "rejects empty interpolations" {
  let source =
    #|<template><div>{{ }}</div></template>
  assert_eq(
    compile_error(source, "invalid/empty_interpolation.mbtv"),
    "InvalidTemplate(\"empty interpolation\")",
  )
}

///|
test "rejects unterminated interpolations" {
  let source =
    #|<template><div>{{ value </div></template>
  assert_eq(
    compile_error(source, "invalid/unterminated_interpolation.mbtv"),
    "InvalidTemplate(\"unterminated interpolation in template text\")",
  )
}

///|
test "rejects missing attribute values after equals" {
  let source =
    #|<template><div title=></div></template>
  assert_eq(
    compile_error(source, "invalid/missing_attr_value_after_equals.mbtv"),
    "InvalidTemplate(\"expected attribute value\")",
  )
}

///|
test "rejects missing attribute names in templates" {
  let source =
    #|<template><div ='title'></div></template>
  assert_eq(
    compile_error(source, "invalid/missing_attr_name.mbtv"),
    "InvalidTemplate(\"expected attribute name in start tag <div>\")",
  )
}

///|
test "rejects quoted attribute names in templates" {
  let source =
    #|<template><div 'title'='card'></div></template>
  assert_eq(
    compile_error(source, "invalid/quoted_attr_name.mbtv"),
    "InvalidTemplate(\"expected attribute name in start tag <div>\")",
  )
}

///|
test "rejects malformed self closing syntax in templates" {
  let source =
    #|<template><div / class='card'></div></template>
  assert_eq(
    compile_error(source, "invalid/malformed_self_closing_syntax.mbtv"),
    "InvalidTemplate(\"unexpected `/` in start tag <div> near offset 5\")",
  )
}

///|
test "rejects malformed tag name punctuation in templates" {
  let source =
    #|<template><div,card /></template>
  assert_eq(
    compile_error(source, "invalid/malformed_tag_name_punctuation.mbtv"),
    "InvalidTemplate(\"expected attribute name in start tag <div>\")",
  )
}

///|
test "rejects invalid template expressions with parser diagnostics" {
  let source =
    #|<template><input v-model='name . get()' /></template>
  assert_eq(
    compile_error(source, "invalid/template_expr_diagnostic.mbtv"),
    "InvalidTemplate(\"invalid template expression `name . get()` in invalid/template_expr_diagnostic.mbtv: Unexpected token here.\")",
  )
}

///|
test "accepts interpolations with close delimiters inside string literals" {
  let source =
    #|<template><div>{{ "}}" }}</div></template>
  let output = compile(
    source,
    filename="examples/interpolation_string_close_delimiter.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("\"}}\""))
}

///|
test "accepts interpolations with close delimiters inside multiline string literals" {
  let source =
    #|<template><div>{{ 
    #|#|}}
    #|#|moon
    #|}}</div></template>
  let output = compile(
    source,
    filename="examples/interpolation_multiline_string_close_delimiter.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("#|}}"))
}

///|
test "accepts directive expressions with escaped quote delimiters" {
  let source =
    #|<template><button @click='track(\'x\')'></button></template>
  let output = compile(
    source,
    filename="examples/escaped_quote_attr_value.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("track(\\'x\\')"))
}

///|
test "accepts directive expressions with multiline string quote delimiters" {
  let source =
    #|<template><button @click='notify(
    #|  #|it's fine
    #|)'></button></template>
  let output = compile(
    source,
    filename="examples/multiline_string_attr_quote_delimiter.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("#|it's fine"))
}

///|
test "accepts static attribute values containing hash pipe text" {
  let source =
    #|<template><div title='hash #| pipe'></div></template>
  let output = compile(source, filename="examples/hash_pipe_static_attr.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("hash #| pipe"))
}

///|
test "accepts directive expressions with hash pipe in string literals" {
  let source =
    #|<template><button @click='notify("hash #| pipe")'></button></template>
  let output = compile(
    source,
    filename="examples/hash_pipe_directive_string.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("hash #| pipe"))
}

///|
test "accepts template comments with tag and interpolation markers inside" {
  let source =
    #|<template><div>before<!-- <span>{{ nope }}</span> --><span>after</span></div></template>
  let output = compile(
    source,
    filename="examples/template_comment_embedded_markup.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("before"))
  assert_true(output.client_code.contains("after"))
}

///|
test "accepts template comments between sibling elements" {
  let source =
    #|<template><section><span>one</span><!-- <div /> --> <span>two</span></section></template>
  let output = compile(
    source,
    filename="examples/template_comment_between_siblings.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("one"))
  assert_true(output.client_code.contains("two"))
}

///|
test "accepts raw less-than characters in text nodes" {
  let source =
    #|<template><div>1 < 2</div></template>
  let output = compile(source, filename="examples/raw_less_than_text.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("1 < 2"))
}

///|
test "accepts nested template attrs with slashes in SFC scanning" {
  let source =
    #|<template>
    #|  <section>
    #|    <template data-path=a/b>
    #|      <span>Inner</span>
    #|    </template>
    #|  </section>
    #|</template>
  let output = compile(
    source,
    filename="examples/nested_template_attr_slash.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("data-path"))
  assert_true(output.client_code.contains("Inner"))
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
test "rejects non assignable v-model expressions" {
  let source =
    #|<template><input v-model='name.trim()' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_non_assignable.mbtv"),
    "InvalidDirective(\"v-model requires an assignable target or signal getter on <input>: `name.trim()`\")",
  )
}

///|
test "rejects call result member targets for v-model" {
  let source =
    #|<template><input v-model='lookup().name' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_call_result_target.mbtv"),
    "InvalidDirective(\"v-model requires an assignable target or signal getter on <input>: `lookup().name`\")",
  )
}

///|
test "accepts member assignment targets for v-model" {
  let source =
    #|<template><input v-model='profile.name' /></template>
  let output = compile(source, filename="examples/v_model_member_target.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(
    output.client_code.contains(
      "profile.name = _event._get(\"target\")._get(\"value\").cast()",
    ),
  )
}

///|
test "accepts array element targets for v-model" {
  let source =
    #|<template><input v-model='items[0]' /></template>
  let output = compile(source, filename="examples/v_model_array_target.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(
    output.client_code.contains(
      "items[0] = _event._get(\"target\")._get(\"value\").cast()",
    ),
  )
}

///|
test "accepts member signal getter targets for v-model" {
  let source =
    #|<template><input v-model='profile.name.get()' /></template>
  let output = compile(
    source,
    filename="examples/v_model_member_signal_target.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(
    output.client_code.contains(
      "profile.name.set(_event._get(\"target\")._get(\"value\").cast())",
    ),
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
test "rejects v-show on component tags" {
  let source =
    #|<template><Panel v-show='visible' /></template>
  assert_eq(
    compile_error(source, "invalid/component_v_show.mbtv"),
    "InvalidDirective(\"v-show is not supported on component tags: <Panel>\")",
  )
}

///|
test "rejects v-unsafe-html on component tags" {
  let source =
    #|<template><Panel v-unsafe-html='content' /></template>
  assert_eq(
    compile_error(source, "invalid/component_v_unsafe_html.mbtv"),
    "InvalidDirective(\"v-unsafe-html is not supported on component tags: <Panel>\")",
  )
}

///|
test "rejects v-unsafe-html on void elements" {
  let source =
    #|<template><img v-unsafe-html='content' /></template>
  assert_eq(
    compile_error(source, "invalid/v_unsafe_html_void_element.mbtv"),
    "InvalidDirective(\"v-unsafe-html is not supported on void elements: <img>\")",
  )
}

///|
test "rejects void elements with child nodes" {
  let source =
    #|<template><img><span /></img></template>
  assert_eq(
    compile_error(source, "invalid/void_element_children.mbtv"),
    "InvalidTemplate(\"void element <img> must be self closing\")",
  )
}

///|
test "rejects void elements without self closing syntax" {
  let source =
    #|<template><input></input></template>
  assert_eq(
    compile_error(source, "invalid/void_element_not_self_closing.mbtv"),
    "InvalidTemplate(\"void element <input> must be self closing\")",
  )
}

///|
test "rejects plain void elements without self closing syntax" {
  let source =
    #|<template><input></template>
  assert_eq(
    compile_error(source, "invalid/void_element_open_only.mbtv"),
    "InvalidTemplate(\"void element <input> must be self closing\")",
  )
}

///|
test "rejects v-else without preceding v-if" {
  let source =
    #|<template><div v-else></div></template>
  assert_eq(
    compile_error(source, "invalid/unsupported_v_else.mbtv"),
    "InvalidDirective(\"`v-else` requires a preceding `v-if` on <div>\")",
  )
}

///|
test "rejects unsupported object v-bind syntax" {
  let source =
    #|<template><div v-bind='props'></div></template>
  assert_eq(
    compile_error(source, "invalid/unsupported_v_bind_object.mbtv"),
    "InvalidDirective(\"unsupported directive on <div>: `v-bind`\")",
  )
}

///|
test "rejects unsupported object v-on syntax" {
  let source =
    #|<template><button v-on='handlers'></button></template>
  assert_eq(
    compile_error(source, "invalid/unsupported_v_on_object.mbtv"),
    "InvalidDirective(\"unsupported directive on <button>: `v-on`\")",
  )
}

///|
test "rejects unsupported island directives" {
  let source =
    #|<template><Panel client:hover /></template>
  assert_eq(
    compile_error(source, "invalid/unsupported_client_directive.mbtv"),
    "InvalidDirective(\"unsupported island directive on <Panel>: `client:hover`\")",
  )
}

///|
test "slot outlet syntax is accepted on components" {
  let source =
    #|<template><Panel #default><p>content</p></Panel></template>
  let output = compile_snapshot(source, "slot_outlet.mbtv")
  assert_true(output.contains("Panel"))
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
test "rejects duplicate v-once directives" {
  let source =
    #|<template><div v-once v-once></div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_v_once.mbtv"),
    "InvalidDirective(\"duplicate `v-once` on <div>\")",
  )
}

///|
test "rejects values on v-once" {
  let source =
    #|<template><div v-once='true'></div></template>
  assert_eq(
    compile_error(source, "invalid/v_once_with_value.mbtv"),
    "InvalidDirective(\"`v-once` does not take a value on <div>\")",
  )
}

///|
test "rejects duplicate event listeners" {
  let source =
    #|<template><button @click='save()' v-on:click='cancel()'></button></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_event_listener.mbtv"),
    "InvalidDirective(\"duplicate event listener `click` on <button>\")",
  )
}

///|
test "rejects duplicate non mergeable attributes" {
  let source =
    #|<template><div id='first' :id='second'></div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_attribute_id.mbtv"),
    "InvalidDirective(\"duplicate attribute `id` on <div>\")",
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
test "rejects non identifier value bindings in v-for" {
  let source =
    #|<template><li v-for='(item.value, index) in items'></li></template>
  assert_eq(
    compile_error(source, "invalid/v_for_member_value_binding.mbtv"),
    "InvalidDirective(\"invalid v-for binding: (item.value, index) in items\")",
  )
}

///|
test "rejects non identifier index bindings in v-for" {
  let source =
    #|<template><li v-for='(item, index.value) in items'></li></template>
  assert_eq(
    compile_error(source, "invalid/v_for_member_index_binding.mbtv"),
    "InvalidDirective(\"invalid v-for binding: (item, index.value) in items\")",
  )
}

///|
test "accepts v-for comments around tuple separators" {
  let source =
    #|<template><li v-for='(item, /* comma, not a separator */ index) /* still not `in` */ in items'></li></template>
  let output = compile(source, filename="examples/v_for_comment_binding.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("fn(item, index)"))
}

///|
test "accepts v-for separators split across newlines" {
  let source =
    #|<template><li v-for='(item, index)
    #|in
    #|items'></li></template>
  let output = compile(source, filename="examples/v_for_newline_separator.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("fn(item, index)"))
}

///|
test "accepts v-for comments after the `in` keyword" {
  let source =
    #|<template><li v-for='item in /* source stays here */ items'></li></template>
  let output = compile(source, filename="examples/v_for_comment_after_in.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("fn(item, _index)"))
}

///|
test "accepts v-for sources with multiline string separators" {
  let source =
    #|<template><li v-for='item in format(
    #|  #|in, still text
    #|  #|comma, still text
    #|)'></li></template>
  let output = compile(
    source,
    filename="examples/v_for_multiline_string_source.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("fn(item, _index)"))
  assert_true(output.client_code.contains("#|in, still text"))
}

///|
test "rejects unsupported event modifiers" {
  let source =
    #|<template><button @click.middle='save()'></button></template>
  assert_eq(
    compile_error(source, "invalid/event_modifier.mbtv"),
    "InvalidDirective(\"unsupported event modifier `.middle` on <button>\")",
  )
}

///|
test "rejects passive prevent event modifier combination" {
  let source =
    #|<template><button @click.passive.prevent='save()'></button></template>
  assert_eq(
    compile_error(source, "invalid/event_modifier_passive_prevent.mbtv"),
    "InvalidDirective(\"event modifiers `.passive` and `.prevent` cannot be combined on <button>\")",
  )
}

///|
test "rejects dynamic event arguments" {
  let source =
    #|<template><button @[event]='save()'></button></template>
  assert_eq(
    compile_error(source, "invalid/event_dynamic_arg.mbtv"),
    "InvalidDirective(\"dynamic event arguments are not supported on <button>: `@[event]`\")",
  )
}

///|
test "rejects binding modifiers" {
  let source =
    #|<template><div :title.prop='label'></div></template>
  assert_eq(
    compile_error(source, "invalid/bind_modifier.mbtv"),
    "InvalidDirective(\"binding modifiers are not supported on <div>: `:title.prop`\")",
  )
}

///|
test "rejects dynamic binding arguments" {
  let source =
    #|<template><div :[name]='value'></div></template>
  assert_eq(
    compile_error(source, "invalid/bind_dynamic_arg.mbtv"),
    "InvalidDirective(\"dynamic binding arguments are not supported on <div>: `:[name]`\")",
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
test "rejects invalid v-model empty argument syntax" {
  let source =
    #|<template><input v-model:='name' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_empty_argument.mbtv"),
    "InvalidDirective(\"invalid v-model syntax: `v-model:`\")",
  )
}

///|
test "rejects invalid v-model empty modifier syntax" {
  let source =
    #|<template><input v-model..trim='name' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_empty_modifier.mbtv"),
    "InvalidDirective(\"invalid v-model syntax: `v-model..trim`\")",
  )
}

///|
test "rejects invalid v-model suffix syntax" {
  let source =
    #|<template><input v-modelfoo='name' /></template>
  assert_eq(
    compile_error(source, "invalid/v_model_invalid_suffix.mbtv"),
    "InvalidDirective(\"invalid v-model syntax: `v-modelfoo`\")",
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
