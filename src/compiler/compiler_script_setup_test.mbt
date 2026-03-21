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
test "rejects plain script blocks" {
  let source =
    #|<script>
    #|let count = 1
    #|</script>
    #|<template><div>{{ count.to_string() }}</div></template>
  assert_eq(
    compile_error(source, "invalid/plain_script.mbtv"),
    "InvalidSfc(\"plain <script> is not supported in invalid/plain_script.mbtv; use <script setup> only\")",
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
  assert_true(info.transformed.contains("@vm.use_id(component_name, 0)"))
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
