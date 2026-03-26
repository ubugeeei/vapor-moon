///|
fn must_analyze_script_setup(
  source : String,
  filename : String,
) -> ScriptSetupInfo {
  analyze_script_setup(source, filename) catch {
    err => {
      ignore(err)
      panic()
    }
  }
}

///|
test "plain script blocks default to setup scope" {
  let source =
    #|<script>
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  let output = compile(
    source,
    filename="examples/plain_script_defaults_to_setup.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("let count = 1"))
  assert_true(output.server_code.contains("let count = 1"))
}

///|
test "script extern is emitted at module scope" {
  let source =
    #|<script extern>
    #|let shared = 1
    #|
    #|fn read_shared() -> Int { shared }
    #|</script>
    #|<script>
    #|let count = read_shared()
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  let output = compile(source, filename="examples/script_extern.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(
    output.client_code.contains(
      "fn read_shared() -> Int { shared }\n\npub fn render_dom",
    ),
  )
  assert_true(
    output.server_code.contains(
      "fn read_shared() -> Int { shared }\n\npub fn render_ssr",
    ),
  )
}

///|
test "rejects setup-only helpers in script extern" {
  let source =
    #|<script extern>
    #|let id = useId()
    #|</script>
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/extern_use_id.mbtv"),
    "InvalidScriptExtern(\"`useId()` is only supported in <script> setup scope in invalid/extern_use_id.mbtv; move it from <script extern> to <script>\")",
  )
}

///|
test "rejects lang attributes" {
  let source =
    #|<script setup lang="mbt">
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/lang.mbtv"),
    "InvalidSfc(\"`lang` is not supported in invalid/lang.mbtv; Vapor Moon blocks are always MoonBit / plain CSS\")",
  )
}

///|
test "keeps escaped quotes in block attr values until validation" {
  let source =
    #|<script setup lang='m\'bt'>
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/lang_escaped_quote.mbtv"),
    "InvalidSfc(\"`lang` is not supported in invalid/lang_escaped_quote.mbtv; Vapor Moon blocks are always MoonBit / plain CSS\")",
  )
}

///|
test "rejects self closing template blocks" {
  let source =
    #|<template />
  assert_eq(
    compile_error(source, "invalid/self_closing_template_block.mbtv"),
    "InvalidSfc(\"self-closing <template> blocks are not supported in invalid/self_closing_template_block.mbtv\")",
  )
}

///|
test "rejects unexpected closing top level blocks" {
  let source =
    #|</template>
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/unexpected_closing_block.mbtv"),
    "InvalidSfc(\"unexpected closing </template> block at offset 0 in invalid/unexpected_closing_block.mbtv\")",
  )
}

///|
test "rejects unexpected top level text" {
  let source =
    #|hello
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/unexpected_top_level_text.mbtv"),
    "InvalidSfc(\"unexpected top-level content at offset 0 in invalid/unexpected_top_level_text.mbtv\")",
  )
}

///|
test "rejects unexpected top level tags" {
  let source =
    #|<div></div>
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/unexpected_top_level_tag.mbtv"),
    "InvalidSfc(\"unexpected top-level tag <div> in invalid/unexpected_top_level_tag.mbtv\")",
  )
}

///|
test "rejects missing block attribute values after equals" {
  let source =
    #|<script setup generic=>
    #|struct Props[T] {
    #|  title : T
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/missing_block_attr_value.mbtv"),
    "InvalidSfc(\"expected attribute value in <script> start tag of invalid/missing_block_attr_value.mbtv\")",
  )
}

///|
test "rejects unterminated block attribute values" {
  let source =
    #|<script setup generic="T>
    #|struct Props[T] {
    #|  title : T
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/unterminated_block_attr_value.mbtv"),
    "InvalidSfc(\"unterminated attribute value in <script> start tag of invalid/unterminated_block_attr_value.mbtv\")",
  )
}

///|
test "rejects unterminated HTML comments in SFC blocks" {
  let source =
    #|<template>
    #|  <!-- broken
    #|  <div />
    #|</template>
  assert_eq(
    compile_error(source, "invalid/unterminated_html_comment.mbtv"),
    "InvalidSfc(\"unterminated HTML comment in invalid/unterminated_html_comment.mbtv\")",
  )
}

///|
test "accepts script setup multiline strings with closing tags" {
  let source =
    #|<script setup>
    #|let banner =
    #|  #|</script>
    #|  #|still here
    #|</script>
    #|<template><div>{{ banner }}</div></template>
  let output = compile(
    source,
    filename="examples/script_multiline_string_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("#|</script>"))
}

///|
test "accepts script setup line comments with closing tags" {
  let source =
    #|<script setup>
    #|// </script> stays in the comment
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  let output = compile(
    source,
    filename="examples/script_line_comment_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("let count = 1"))
}

///|
test "accepts script setup block comments with closing tags" {
  let source =
    #|<script setup>
    #|/* </script> stays in the comment */
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  let output = compile(
    source,
    filename="examples/script_block_comment_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("let count = 1"))
}

///|
test "accepts style block comments with closing tags" {
  let source =
    #|<template><div class="box" /></template>
    #|<style>
    #|/* </style> stays in the comment */
    #|.box { color: red; }
    #|</style>
  let output = compile(
    source,
    filename="examples/style_block_comment_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.css_output.contains("/* </style> stays in the comment */"))
  assert_true(output.css_output.contains(".box { color: red; }"))
}

///|
test "accepts template block comments with closing tags" {
  let source =
    #|<template>
    #|  <!-- </template> <template> -->
    #|  <div />
    #|</template>
  let output = compile(
    source,
    filename="examples/template_comment_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("el(\"div\")"))
}

///|
test "accepts script setup escaped quote strings with closing tags" {
  let source =
    #|<script setup>
    #|let closing = "\"</script>\""
    #|</script>
    #|<template><div>{{ closing }}</div></template>
  let output = compile(
    source,
    filename="examples/script_escaped_quote_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("\\\"</script>\\\""))
}

///|
test "accepts style escaped quote strings with closing tags" {
  let source =
    #|<template><div class="box" /></template>
    #|<style>
    #|.box::before { content: "\"</style>\""; }
    #|.box { color: red; }
    #|</style>
  let output = compile(
    source,
    filename="examples/style_escaped_quote_close_tag.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.css_output.contains("\\\"</style>\\\""))
  assert_true(output.css_output.contains(".box { color: red; }"))
}

///|
test "accepts nested template attrs with escaped quotes in SFC scanning" {
  let source =
    #|<template>
    #|  <section>
    #|    <template data-note='say \'/\' hi'>
    #|      <span>Inner</span>
    #|    </template>
    #|  </section>
    #|</template>
  let output = compile(
    source,
    filename="examples/nested_template_attr_escaped_quote.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("data-note"))
  assert_true(output.client_code.contains("Inner"))
}

///|
test "accepts template block comments with nested template markers" {
  let source =
    #|<template>
    #|  <!-- <template data-path=a/b></template> -->
    #|  <div />
    #|</template>
  let output = compile(
    source,
    filename="examples/template_comment_nested_markers.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("el(\"div\")"))
}

///|
test "rejects duplicate generic attributes" {
  let source =
    #|<script setup generic="T" generic="U">
    #|struct Props[T] {
    #|  title : T
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_generic_attr.mbtv"),
    "InvalidSfc(\"duplicate `generic` attribute on <script setup> in invalid/duplicate_generic_attr.mbtv\")",
  )
}

///|
test "rejects unbalanced generic declarations" {
  let source =
    #|<script setup generic="T : Array[">
    #|struct Props[T] {
    #|  title : T
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/unbalanced_generic_decl.mbtv"),
    "InvalidSfc(\"invalid `generic` declaration `T : Array[` in invalid/unbalanced_generic_decl.mbtv\")",
  )
}

///|
test "rejects stray generic closing delimiters" {
  let source =
    #|<script setup generic="T)">
    #|struct Props[T] {
    #|  title : T
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/stray_generic_closer.mbtv"),
    "InvalidSfc(\"invalid `generic` declaration `T)` in invalid/stray_generic_closer.mbtv\")",
  )
}

///|
test "rejects generic without a value" {
  let source =
    #|<script setup generic>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|let props : Props = defineProps()
    #|</script>
    #|<template><div>{{ props.title }}</div></template>
  assert_eq(
    compile_error(source, "invalid/generic_missing_value.mbtv"),
    "InvalidSfc(\"`generic` requires a value on <script setup> in invalid/generic_missing_value.mbtv\")",
  )
}

///|
test "rejects missing block attribute names" {
  let source =
    #|<template ='true'></template>
  assert_eq(
    compile_error(source, "invalid/missing_block_attr_name.mbtv"),
    "InvalidSfc(\"expected attribute name in <template> start tag of invalid/missing_block_attr_name.mbtv\")",
  )
}

///|
test "rejects quoted block attribute names" {
  let source =
    #|<template 'foo'='true'><div /></template>
  assert_eq(
    compile_error(source, "invalid/quoted_block_attr_name.mbtv"),
    "InvalidSfc(\"expected attribute name in <template> start tag of invalid/quoted_block_attr_name.mbtv\")",
  )
}

///|
test "keeps slashes in top level block attr values until validation" {
  let source =
    #|<style src=styles/main.css></style>
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/style_src_slash_value.mbtv"),
    "InvalidSfc(\"`src` is not supported in invalid/style_src_slash_value.mbtv; keep the SFC self-contained\")",
  )
}

///|
test "rejects malformed block attribute name punctuation" {
  let source =
    #|<template foo,bar><div /></template>
  assert_eq(
    compile_error(source, "invalid/malformed_block_attr_punctuation.mbtv"),
    "InvalidSfc(\"expected attribute name in <template> start tag of invalid/malformed_block_attr_punctuation.mbtv\")",
  )
}

///|
test "rejects trailing tokens after script setup imports" {
  let source =
    #|<script setup>
    #|import { "mizchi/luna/js/resource" @reactivity, } let signal = @reactivity.signal
    #|</script>
    #|<template><div /></template>
  assert_eq(
    compile_error(source, "invalid/import_trailing_tokens.mbtv"),
    "InvalidScriptSetup(\"script setup imports must end after `}` in invalid/import_trailing_tokens.mbtv\")",
  )
}

///|
test "rejects stray slashes in top level block tags" {
  let source =
    #|<template / foo><div /></template>
  assert_eq(
    compile_error(source, "invalid/stray_block_slash.mbtv"),
    "InvalidSfc(\"unexpected `/` in <template> start tag of invalid/stray_block_slash.mbtv\")",
  )
}

///|
test "rejects generic on template blocks" {
  let source =
    #|<template generic="T"><div /></template>
  assert_eq(
    compile_error(source, "invalid/generic_template_block.mbtv"),
    "InvalidSfc(\"`generic` is only supported on <script> in invalid/generic_template_block.mbtv\")",
  )
}

///|
test "rejects setup on template blocks" {
  let source =
    #|<template setup><div /></template>
  assert_eq(
    compile_error(source, "invalid/setup_template_block.mbtv"),
    "InvalidSfc(\"`setup` is only supported on <script> in invalid/setup_template_block.mbtv\")",
  )
}

///|
test "rejects scoped on script blocks" {
  let source =
    #|<script scoped>
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/scoped_script_block.mbtv"),
    "InvalidSfc(\"`scoped` is only supported on <style> in invalid/scoped_script_block.mbtv\")",
  )
}

///|
test "rejects unknown template block attributes" {
  let source =
    #|<template foo><div /></template>
  assert_eq(
    compile_error(source, "invalid/unknown_template_attr.mbtv"),
    "InvalidSfc(\"unsupported attribute `foo` on <template> in invalid/unknown_template_attr.mbtv\")",
  )
}

///|
test "rejects valued setup attributes" {
  let source =
    #|<script setup="true">
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/setup_with_value.mbtv"),
    "InvalidSfc(\"`setup` does not take a value on <script setup> in invalid/setup_with_value.mbtv\")",
  )
}

///|
test "rejects valued scoped attributes" {
  let source =
    #|<template><div /></template>
    #|<style scoped="maybe">
    #|.root { color: red; }
    #|</style>
  assert_eq(
    compile_error(source, "invalid/scoped_with_value.mbtv"),
    "InvalidSfc(\"`scoped` only accepts `false` on <style> in invalid/scoped_with_value.mbtv\")",
  )
}

///|
test "style blocks are scoped by default" {
  let source =
    #|<template><div class="root" /></template>
    #|<style>
    #|.root { color: red; }
    #|</style>
  let output = compile(source, filename="examples/default_scoped_style.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(output.client_code.contains("data-vm-scope"))
  assert_true(output.css_output.contains("data-vm-scope"))
  match output.scope_id {
    Some(_) => ()
    None => panic()
  }
}

///|
test "scoped false disables style scoping" {
  let source =
    #|<template><div class="root" /></template>
    #|<style scoped="false">
    #|.root { color: red; }
    #|</style>
  let output = compile(source, filename="examples/unscoped_style_opt_out.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_false(output.client_code.contains("data-vm-scope"))
  assert_false(output.css_output.contains("data-vm-scope"))
  match output.scope_id {
    Some(_) => panic()
    None => ()
  }
}

///|
test "rejects duplicate defineProps" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|struct OtherProps {
    #|  count : Int
    #|}
    #|
    #|let props : Props = defineProps()
    #|let other : OtherProps = defineProps()
    #|</script>
    #|<template><div>{{ props.get_or("title", "") }}</div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_props.mbtv"),
    "InvalidScriptSetup(\"duplicate defineProps() in invalid/duplicate_props.mbtv\")",
  )
}

///|
test "rejects duplicate defineEmits" {
  let source =
    #|<script setup>
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|let emit : Emits = defineEmits()
    #|let other : Emits = defineEmits()
    #|</script>
  assert_eq(
    compile_error(source, "invalid/duplicate_emits.mbtv"),
    "InvalidScriptSetup(\"duplicate defineEmits() in invalid/duplicate_emits.mbtv\")",
  )
}

///|
test "rejects duplicate defineSlot" {
  let source =
    #|<script setup>
    #|struct Slots {
    #|  default : Unit
    #|}
    #|
    #|let slots : Slots = defineSlot()
    #|let other : Slots = defineSlot()
    #|</script>
  assert_eq(
    compile_error(source, "invalid/duplicate_slots.mbtv"),
    "InvalidScriptSetup(\"duplicate defineSlot() in invalid/duplicate_slots.mbtv\")",
  )
}

///|
test "parses script setup generic attribute" {
  let doc = parse_sfc(generic_source(), filename="examples/generic_list.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_eq(doc.generics.length(), 2)
  assert_eq(doc.generics[0].name, "T")
  assert_eq(doc.generics[1].declaration, "U : Show")
}

///|
test "rejects unused generic interface parameters" {
  let source =
    #|<script setup generic="T">
    #|struct Props[T] {
    #|  title : String
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div>{{ props.title }}</div></template>
  assert_eq(
    compile_error(source, "invalid/unused_generic.mbtv"),
    "InvalidSfc(\"`generic` parameter T must appear in defineProps/defineEmits/defineSlot signatures in invalid/unused_generic.mbtv\")",
  )
}

///|
test "accepts nested generic usage discovered from type AST" {
  let source =
    #|<script setup generic="T">
    #|struct Props[T] {
    #|  render : (Array[T]) -> T?
    #|}
    #|
    #|let props : Props[T] = defineProps()
    #|</script>
    #|<template><div /></template>
  let doc = parse_sfc(source, filename="examples/nested_generic_usage.mbtv") catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_eq(doc.generics[0].name, "T")
  assert_eq(doc.props[0].signature, Some("(Array[T]) -> T?"))
}

///|
test "captures macro field type metadata from AST" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String?
    #|}
    #|
    #|struct Emits {
    #|  save : (String, Int)
    #|  reset : Unit
    #|}
    #|
    #|let props : Props = defineProps()
    #|let emit : Emits = defineEmits()
    #|</script>
    #|<template><div>{{ props.title.unwrap_or(\"\") }}</div></template>
  let doc = parse_sfc(
    source,
    filename="examples/macro_field_type_metadata.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_true(doc.props[0].is_optional)
  assert_eq(doc.props[0].type_shape, SingleValue)
  assert_eq(doc.emits[0].type_shape, TupleValues(2))
  assert_eq(doc.emits[1].type_shape, UnitLike)
}

///|
test "rejects legacy emit.emit in template expressions" {
  let source =
    #|<script setup>
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|let emit : Emits = defineEmits()
    #|</script>
    #|<template><button @click='emit.emit("save", [])'></button></template>
  assert_eq(
    compile_error(source, "invalid/legacy_emit_template.mbtv"),
    "InvalidTemplate(\"legacy `emit.emit(...` is not supported in invalid/legacy_emit_template.mbtv; use typed event calls like `emit.save()`\")",
  )
}

///|
test "does not reject emit.emit inside template string literals" {
  let source =
    #|<script setup>
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|let emit : Emits = defineEmits()
    #|</script>
    #|<template><button @click='\"emit.emit(\"'></button></template>
  let output = compile(
    source,
    filename="examples/legacy_emit_template_literal_ok.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_eq(output.emits[0].name, "save")
}

///|
test "does not reject emit.emit inside script setup string literals" {
  let source =
    #|<script setup>
    #|struct Emits {
    #|  save : Unit
    #|}
    #|
    #|let emit : Emits = defineEmits()
    #|let note = "emit.emit("
    #|</script>
    #|<template><div>{{ note }}</div></template>
  let output = compile(
    source,
    filename="examples/legacy_emit_script_literal_ok.mbtv",
  ) catch {
    err => {
      ignore(err)
      panic()
    }
  }
  assert_eq(output.emits[0].name, "save")
}

///|
test "rejects runtime declaration literals for interface macros" {
  let source =
    #|<script setup>
    #|let props = defineProps([("title", "String")])
    #|</script>
  assert_eq(
    compile_error(source, "invalid/runtime_decl.mbtv"),
    "InvalidScriptSetup(\"defineProps() only accepts a defaults record like `defineProps({ count: 0 })` in invalid/runtime_decl.mbtv; defineProps() requires a typed contract like `struct Props { ... }` plus `let props : Props = defineProps()` in invalid/runtime_decl.mbtv\")",
  )
}

///|
test "rejects runtime declaration literals for defineEmits" {
  let source =
    #|<script setup>
    #|let emit = defineEmits([])
    #|</script>
  assert_eq(
    compile_error(source, "invalid/emits_runtime_decl.mbtv"),
    "InvalidScriptSetup(\"defineEmits() no longer accepts runtime declaration literals in invalid/emits_runtime_decl.mbtv; defineEmits() requires a typed contract like `struct Emits { ... }` plus `let emit : Emits = defineEmits()` in invalid/emits_runtime_decl.mbtv\")",
  )
}

///|
test "rejects runtime declaration literals for defineSlot" {
  let source =
    #|<script setup>
    #|let slots = defineSlot([])
    #|</script>
  assert_eq(
    compile_error(source, "invalid/slots_runtime_decl.mbtv"),
    "InvalidScriptSetup(\"defineSlot() no longer accepts runtime declaration literals in invalid/slots_runtime_decl.mbtv; defineSlot() requires a typed contract like `struct Slots { ... }` plus `let slots : Slots = defineSlot()` in invalid/slots_runtime_decl.mbtv\")",
  )
}

///|
test "rejects non local struct contracts for defineProps" {
  let source =
    #|<script setup>
    #|let props : Int = defineProps()
    #|</script>
  assert_eq(
    compile_error(source, "invalid/non_struct_props_contract.mbtv"),
    "InvalidScriptSetup(\"defineProps() requires a local `struct Int {{ ... }}` contract in invalid/non_struct_props_contract.mbtv\")",
  )
}

///|
test "rejects qualified type annotations for defineProps" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|let props : @model.Props = defineProps()
    #|</script>
    #|<template><div>{{ props.title }}</div></template>
  assert_eq(
    compile_error(source, "invalid/qualified_props_contract.mbtv"),
    "InvalidScriptSetup(\"defineProps() requires a local `struct Props {{ ... }}` contract in invalid/qualified_props_contract.mbtv; qualified type annotation `@model.Props` is not supported\")",
  )
}

///|
test "script setup macros use AST for multiline lets" {
  let source =
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|}
    #|struct Emits {
    #|  save : Unit
    #|}
    #|let props : Props =
    #|  defineProps()
    #|let emit : Emits =
    #|  defineEmits()
  let info = must_analyze_script_setup(source, "inline/ast_multiline.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.emits_binding, Some("emit"))
  assert_eq(info.props.length(), 2)
  assert_eq(info.props[0].name, "title")
  assert_eq(info.props[0].signature, Some("String"))
  assert_eq(info.props[1].name, "count")
  assert_eq(info.props[1].signature, Some("Int"))
  assert_false(info.transformed.contains("defineProps"))
  assert_false(info.transformed.contains("defineEmits"))
  assert_true(info.transformed.contains("struct Props"))
  assert_true(info.transformed.contains("struct Emits"))
}

///|
test "script setup macros are found through grouped expressions" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let props : Props = (defineProps())
    #|let slot_ids = (useId())
  let info = must_analyze_script_setup(source, "inline/ast_grouped.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.props.length(), 1)
  assert_eq(info.props[0].name, "title")
  assert_eq(info.props[0].signature, Some("String"))
  assert_false(info.transformed.contains("defineProps"))
  assert_true(info.transformed.contains("@hlp.use_id(component_name, 0)"))
}

///|
test "script setup macros collect prop defaults from record literal" {
  let source =
    #|struct Props {
    #|  title : String
    #|  count : Int
    #|}
    #|let props : Props = defineProps({
    #|  count: 0,
    #|})
  let info = must_analyze_script_setup(source, "inline/props_defaults.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.prop_defaults.length(), 1)
  assert_eq(info.prop_defaults[0].name, "count")
  assert_eq(info.prop_defaults[0].expr, "0")
}

///|
test "script setup imports ignore comment commas" {
  let source =
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity, // module, keep it
    #|  /* local alias, still one entry */
    #|  let signal = @reactivity.signal,
    #|}
    #|struct Props {
    #|  title : String
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/import_comment_commas.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.import_entries.length(), 1)
  assert_eq(info.import_entries[0], "\"mizchi/luna/js/resource\" @reactivity,")
  assert_true(info.transformed.contains("let signal = @reactivity.signal"))
}

///|
test "script setup imports allow comments before braces" {
  let source =
    #|import /* module table */ {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|struct Props {
    #|  title : String
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(source, "inline/import_comment_gap.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.import_entries.length(), 1)
  assert_eq(info.import_entries[0], "\"mizchi/luna/js/resource\" @reactivity,")
  assert_true(info.transformed.contains("let signal = @reactivity.signal"))
}

///|
test "script setup imports allow line comments before braces" {
  let source =
    #|import // module table
    #|{
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|struct Props {
    #|  title : String
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/import_line_comment_gap.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_eq(info.import_entries.length(), 1)
  assert_eq(info.import_entries[0], "\"mizchi/luna/js/resource\" @reactivity,")
  assert_true(info.transformed.contains("let signal = @reactivity.signal"))
}

///|
test "script setup multiline strings stay inside one statement" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let banner =
    #|  #|hello,
    #|  #|world
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/multiline_string_split.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("#|hello,"))
  assert_true(info.transformed.contains("#|world"))
}

///|
test "script setup keeps pipeline continuation lines together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let title = 10
    #|  |> Int::to_string
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/pipeline_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("let title = 10"))
  assert_true(info.transformed.contains("|> Int::to_string"))
}

///|
test "script setup keeps pipeline continuation after comments together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let title = 10
    #|// keep flowing
    #|  |> Int::to_string
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/pipeline_comment_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("|> Int::to_string"))
}

///|
test "script setup keeps cascade continuation lines together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let values = []
    #|  ..push(1)
    #|  ..push(2)
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/cascade_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("..push(1)"))
  assert_true(info.transformed.contains("..push(2)"))
}

///|
test "script setup keeps cascade continuation after comments together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let values = [] // still same cascade
    #|  ..push(1)
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/cascade_comment_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("..push(1)"))
}

///|
test "script setup keeps else continuation lines together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let picked = if true {
    #|  "a"
    #|}
    #|else {
    #|  "b"
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(source, "inline/else_continuation.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("else {"))
}

///|
test "script setup keeps else continuation after comments together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let picked = if true {
    #|  "a"
    #|}
    #|// keep the branch attached
    #|else {
    #|  "b"
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/else_comment_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("else {"))
}

///|
test "script setup keeps catch continuation lines together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let picked = try {
    #|  "a"
    #|}
    #|catch {
    #|  _ => "b"
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(source, "inline/catch_continuation.mbtv")
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("catch {"))
}

///|
test "script setup keeps catch continuation after comments together" {
  let source =
    #|struct Props {
    #|  title : String
    #|}
    #|let picked = try {
    #|  "a"
    #|} // still catching
    #|catch {
    #|  _ => "b"
    #|}
    #|let props : Props = defineProps()
  let info = must_analyze_script_setup(
    source, "inline/catch_comment_continuation.mbtv",
  )
  assert_eq(info.props_binding, Some("props"))
  assert_true(info.transformed.contains("catch {"))
}

///|
test "script setup does not silently merge unary minus lines" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|let negative = 1
    #|let offset = 42
    #|-negative
    #|let props : Props = defineProps()
    #|</script>
    #|<template><div /></template>
  let err = compile_error(source, "invalid/unary_minus_statement_boundary.mbtv")
  assert_true(err.contains("InvalidScriptSetup"))
  assert_true(err.contains("Unexpected token `-`"))
}

///|
test "rejects duplicate prop defaults" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|let props : Props = defineProps({
    #|  title: "hello",
    #|  title: "world",
    #|})
    #|</script>
  assert_eq(
    compile_error(source, "invalid/duplicate_prop_default.mbtv"),
    "InvalidScriptSetup(\"duplicate default for prop `title` in invalid/duplicate_prop_default.mbtv\")",
  )
}

///|
test "rejects unknown prop defaults" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|}
    #|
    #|let props : Props = defineProps({
    #|  count: 1,
    #|})
    #|</script>
  assert_eq(
    compile_error(source, "invalid/unknown_prop_default.mbtv"),
    "InvalidScriptSetup(\"defineProps() default `count` does not match any declared prop in invalid/unknown_prop_default.mbtv\")",
  )
}

///|
test "rejects defaults on optional prop contracts" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String?
    #|}
    #|
    #|let props : Props = defineProps({
    #|  title: "hello",
    #|})
    #|</script>
    #|<template><div>{{ props.title }}</div></template>
  assert_eq(
    compile_error(source, "invalid/optional_default_prop.mbtv"),
    "InvalidScriptSetup(\"defineProps() default `title` requires a non-optional prop type in invalid/optional_default_prop.mbtv; remove `?` from the contract field and let the default make it optional for callers\")",
  )
}

///|
test "rejects useId with arguments" {
  let source =
    #|<script setup>
    #|let instance_id = useId("hero")
    #|</script>
    #|<template><div>{{ instance_id }}</div></template>
  assert_eq(
    compile_error(source, "invalid/use_id_args.mbtv"),
    "InvalidScriptSetup(\"useId() does not take arguments in invalid/use_id_args.mbtv\")",
  )
}

///|
test "collects useTemplateRef bindings and static names" {
  let source =
    #|let root_ref = useTemplateRef("root")
    #|let ref_name = "dynamic"
    #|let dynamic_ref = useTemplateRef(ref_name)
    #|let orphan_ref = useTemplateRef("orphan")
  let info = must_analyze_script_setup(source, "inline/use_template_refs.mbtv")
  assert_eq(info.template_refs.length(), 3)
  assert_eq(info.template_refs[0].binding_name, Some("root_ref"))
  assert_eq(info.template_refs[0].ref_name, Some("root"))
  assert_eq(info.template_refs[1].binding_name, Some("dynamic_ref"))
  assert_eq(info.template_refs[1].ref_name, None)
  assert_eq(info.template_refs[2].binding_name, Some("orphan_ref"))
  assert_eq(info.template_refs[2].ref_name, Some("orphan"))
}

///|
test "rejects useTemplateRef without exactly one argument" {
  let source =
    #|<script setup>
    #|let root_ref = useTemplateRef()
    #|</script>
    #|<template><div ref='root'></div></template>
  assert_eq(
    compile_error(source, "invalid/use_template_ref_arity.mbtv"),
    "InvalidScriptSetup(\"useTemplateRef() requires exactly one argument in invalid/use_template_ref_arity.mbtv\")",
  )
}

///|
test "rejects duplicate contract fields" {
  let source =
    #|<script setup>
    #|struct Props {
    #|  title : String
    #|  title : Int
    #|}
    #|
    #|let props : Props = defineProps()
    #|</script>
    #|<template><div>{{ props.title }}</div></template>
  assert_eq(
    compile_error(source, "invalid/duplicate_contract_field.mbtv"),
    "InvalidScriptSetup(\"defineProps() contract contains duplicate field `title` in invalid/duplicate_contract_field.mbtv\")",
  )
}
