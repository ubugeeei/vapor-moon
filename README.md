# Vapor Moon

Vapor Moon is a MoonBit-first Single File Component toolchain for building luna.mbt-powered UIs with Vue-like authoring ergonomics.

The goal is simple:

- keep authoring in one file
- keep `script setup` and template expressions in plain MoonBit
- keep runtime updates fine-grained and Virtual DOM-less by leaning on `mizchi/luna`
- add Island / Server Component style delivery that Vue proper does not have

## Status

This repository already includes:

- `.mbtv` as the default SFC extension
- a compiler that parses `<template>`, `<script setup>`, and `<style>`
- code generation for luna DOM output and SSR output
- language-tool analysis plus LSP-oriented diagnostics / hover / definition / completion
- a small runtime bridge on top of luna for DOM placeholders and SSR island wrappers
- snapshot-heavy compiler and tooling tests

Current scope intentionally excludes:

- plain `<script>` blocks
- `lang="mbt"` and other per-block language switches
- CSS preprocessors
- a finalized component import / linking story across generated files

## Why `.mbtv`

`Vapor Moon` is already a pun on `Paper Moon`, so `.mbtv` keeps the name short, unique, and obviously tied to the project without borrowing Vue’s `.vue`.

## Generic components

Vapor Moon supports Vue-style generic component declarations on `<script setup>`:

```html
<script setup generic="T, U : Show">
struct Props[T, U] {
  items : Array[T]
  selected : U
}

struct Emits[T] {
  choose : T
}

struct Slots[T, U] {
  default : T
  label : U
}

let props : Props[T, U] = defineProps()
let emit : Emits[T] = defineEmits()
let slots : Slots[T, U] = defineSlot()
</script>
```

- `generic="..."` is only valid on `<script setup>`
- generic parameters must appear in the local contract types referenced by `defineProps()` / `defineEmits()` / `defineSlot()`
- the compiler threads those parameters through generated `Props`, `Emits`, `DomSlots`, `SsrSlots`, and `render_*` signatures
- generics stay type-level only; no runtime validation or runtime type registry is emitted

## SFC shape

```html
<script setup>
import {
  "mizchi/luna/js/resource" @reactivity,
  let signal = @reactivity.signal,
}

let count = signal(0)
</script>

<template>
  <section class="counter">
    <button @click='count.update(fn(n) { n + 1 })'>+</button>
    <p>{{ "Count: " + count.get().to_string() }}</p>
    <CounterPanel :count="count.get()" client:visible />
  </section>
</template>

<style scoped>
.counter {
  display: grid;
  gap: 12px;
}
</style>
```

`<script setup>` is the only supported script block. Vapor Moon intentionally rejects plain `<script>`.

The recommended reactivity surface is an explicit import with a meaningful alias like `@reactivity`. Vapor Moon examples avoid leaking the older luna-internal alias into authoring code.

## Compiler macros

Vapor Moon currently supports MoonBit-flavored macro calls inside `<script setup>`:

```moonbit
struct Props {
  title : String
  count : Int
}

struct Emits {
  save : String
  cancel : Unit
}

struct Slots {
  default : Unit
  footer : String
}

let props : Props = defineProps()
let emit : Emits = defineEmits()
let slots : Slots = defineSlot()
```

- these declarations are compiler-only and disappear from lowered `script setup`
- the compiler generates typed component surfaces such as `ExampleProps`, `ExampleEmits`, `ExampleDomSlots`, and `ExampleSsrSlots`
- generated `render_dom` / `render_ssr` functions take those contracts as plain arguments, so the runtime does not own props, emits, or slot bags
- `defineProps()` / `defineEmits()` / `defineSlot()` are zero-argument markers that bind to the annotated local `struct`
- runtime-declaration literals are intentionally unsupported, so component interfaces stay type-first and MoonBit-native

## Supported template features

- text nodes and `{{ expression }}`
- static attributes
- dynamic attributes with `:prop="expr"` and `v-bind:prop="expr"`
- event handlers with `@event="expr"` and `v-on:event="expr"`
- `v-if`
- `v-for="item in items"` and `v-for="(item, index) in items"`
- component-looking tags via uppercase names
- scoped styles

## Island and Server Component directives

Vapor Moon adds delivery directives directly at the template layer.

- `client:load`
- `client:idle`
- `client:visible`
- `client:media="(max-width: 768px)"`
- `client:only`
- `server:defer`

The compiler currently treats these as component-only directives and emits luna-aligned client / SSR wrappers.

## Architecture

### `src/compiler/`

- keeps the public compiler facade and snapshot tests
- splits implementation into small MoonBit subpackages so each file stays focused and under the line budget
- `src/compiler/common/` holds shared AST and error types
- `src/compiler/sfc/` parses top-level SFC blocks
- `src/compiler/template/` tokenizes template input and builds AST through start-tag / end-tag / text visitor-style events
- `src/compiler/script_setup/` walks MoonBit AST for `script setup` macros and lowering
- `src/compiler/codegen/` emits client / server MoonBit modules and scoped CSS

### `src/runtime/`

- keeps shared hydration metadata helpers plus `useId` / `useTemplateRef`
- leaves component contracts to generated typed arguments instead of runtime bags
- wraps luna DOM for client placeholders
- wraps luna SSR islands for server output

### `src/tooling/`

- exposes block symbols and expression regions
- provides structured diagnostics for unknown props / emits / slots usage
- provides source-position based hover, definition, and completion queries for component contracts and template directives

### `src/cmd/vapor_moon/`

- `compile <file.mbtv>`
- `analyze <file.mbtv>`
- `diagnostics <file.mbtv>`
- `hover <file.mbtv> <line> <character>`
- `definition <file.mbtv> <line> <character>`
- `complete <file.mbtv> <line> <character>`

## Development

Requirements:

- MoonBit toolchain on `PATH`

Useful commands:

```bash
moon check
moon test src/compiler
moon test src/tooling
moon run src/cmd/vapor_moon -- compile examples/basic.mbtv
moon run src/cmd/vapor_moon -- analyze examples/basic.mbtv
moon run src/cmd/vapor_moon -- diagnostics examples/macros.mbtv
moon run src/cmd/vapor_moon -- hover examples/macros.mbtv 17 13
moon run src/cmd/vapor_moon -- definition examples/macros.mbtv 16 39
moon run src/cmd/vapor_moon -- complete examples/macros.mbtv 17 18
```

Example components live in [`examples/`](./examples).

## Git setup

The repository includes:

- `.gitignore` for MoonBit build outputs and mooncakes cache
- `.gitattributes` for LF normalization
- `.githooks/pre-commit` to run formatting and compiler/tooling tests

After cloning, enable the repo-local hook path once:

```bash
git config core.hooksPath .githooks
```

## Near-term roadmap

- stabilize cross-component linking and generated import strategy
- deepen cross-file component indexing for jump / completion across imports
- compile SSR output to a stricter island manifest
- deepen type-first component invocation and generic component ergonomics
