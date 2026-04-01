# Vapor Moon

Vapor Moon is a MoonBit-first Single File Component toolchain for building `luna.mbt`-powered UIs with Vue-like authoring, direct DOM-oriented client output, and SSR/island delivery.

It is currently an unpublished hobby project developed by [`ubugeeei`](https://github.com/ubugeeei) and [`mizchi`](https://github.com/mizchi).

## Why The Name

- `Vapor Moon` is a pun on `Paper Moon`.
- `Moon` reflects that the authoring model, generated code, and tooling are MoonBit-first.
- `Vapor` comes from `Vue Vapor` and reflects the direction of the compiler: emit direct DOM/SSR-oriented code instead of leaning on a Virtual DOM layer.
- `.mbtv` stays short, unique, and obviously tied to MoonBit plus Vapor Moon without borrowing Vue's `.vue`.

## Concept

Vapor Moon is built around four ideas:

- author each component in one `.mbtv` file
- keep `<script>` blocks and template expressions in plain MoonBit
- compile to raw DOM / `luna` SSR nodes instead of centering the runtime around a Virtual DOM
- expose island and server-component-style delivery as template syntax, not as an afterthought

## Status

This repository already includes:

- `.mbtv` as the default SFC extension
- parsing for `<template>`, `<script>`, `<script extern>`, and `<style>`
- client code generation for raw DOM-oriented output
- server code generation for `luna` SSR output
- typed `defineProps()`, `defineEmits()`, and `defineSlots()` contracts
- scoped styles by default
- diagnostics, hover, definition, and completion queries for editor tooling
- a stdio JSON-RPC LSP server plus VS Code, Zed, and Neovim integrations
- ripple-backed incremental compilation infrastructure
- snapshot-heavy compiler and tooling tests

Current scope intentionally excludes or leaves unfinished:

- `lang="mbt"` and other per-block language switches
- CSS preprocessors
- a finalized cross-component import and linking story
- component event listeners such as `@save` on component tags
- component-side `v-model`

## Authoring Model

The default SFC shape is intentionally small:

```html
<script>
import {
  "mizchi/luna/js/resource" @reactivity,
  let signal = @reactivity.signal,
}

let count = signal(0)
</script>

<template>
  <div class="counter">{{ count.get() }}</div>
</template>

<style>
.counter {
  color: red;
}
</style>
```

- `<script>` is the canonical setup-scope block.
- `<script extern>` is for module-scope helpers that should stay outside render/setup.
- The older `<script setup>` spelling still works as an alias, but plain `<script>` is the canonical form.
- `<style>` blocks are scoped by default. Use `<style scoped="false">` when you explicitly want global CSS.
- Reactivity is expected to come from explicit MoonBit imports such as `@reactivity.signal`, `@reactivity.computed`, and `@reactivity.watch`.

## Compile Output

Running the compiler:

```bash
moon run src/cmd/vapor_moon -- compile examples/basic.mbtv
```

The CLI prints one combined snapshot with `=== client ===`, `=== server ===`, and so on. In the README, the same pieces are shown as separate blocks for readability.

Client output:

```moonbit
import {
  "mizchi/luna/dom" @luna_dom,
  "ubugeeei/vapor_moon/src/runtime" @hlp,
  "ubugeeei/vapor_moon/src/runtime/dom" @dom,
  "mizchi/luna/js/resource" @reactivity,
}

pub fn render_dom() -> @luna_dom.DomNode {
  let signal = @reactivity.signal,
  let count = signal(0)
  (fn() {
      let n0 = @dom.el("div")
      @dom.setAttr(n0, ("class", @dom.attr("counter")))
      @dom.setAttr(n0, ("data-vm-scope", @dom.attr("vm-4048536636")))
      @dom.append(n0.as_node(), (fn() {
            let n1 = @dom.text("")
            @dom.setText(n1, fn() { count.get().to_string() })
            n1
          })())
      @dom.into(n0)
    })()
}
```

Server output:

```moonbit
import {
  "mizchi/luna/core" @luna_core,
  "ubugeeei/vapor_moon/src/runtime" @hlp,
  "ubugeeei/vapor_moon/src/runtime/server" @vm_server,
  "mizchi/luna/js/resource" @reactivity,
}

pub fn render_ssr() -> @luna_core.StaticDomNode {
  let signal = @reactivity.signal,
  let count = signal(0)
  @luna_core.h("div", [("class", @luna_core.attr_static("counter")), ("data-vm-scope", @luna_core.attr_static("vm-4048536636"))], [
      @luna_core.text_dyn(fn() { count.get().to_string() })
    ])
}
```

Scoped CSS output:

```css
[data-vm-scope="vm-4048536636"] .counter { color: red; }
```

Metadata output:

```text
component=Basic
extension=.mbtv
scope=vm-4048536636
islands=<none>
props_binding=<none>
props=<none>
emits_binding=<none>
emits=<none>
slots_binding=<none>
slots=<none>
```

Client lowering is intentionally raw-DOM-oriented: native elements become `el -> setAttr -> append -> into`, while server output stays HTML/SSR-oriented through `luna_core.StaticDomNode`.

## Script Macros And Setup Helpers

Typed component contracts live in plain MoonBit:

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
let slots : Slots = defineSlots()
```

For prop defaults, pass only a record literal:

```moonbit
let props : Props = defineProps({
  count: 0,
  tone: "primary",
})
```

- these macros are compiler-only markers and disappear from lowered setup code
- caller-facing generated props become optional when a prop has a default
- generated `render_dom` and `render_ssr` functions take typed contracts as plain arguments
- runtime declaration literals are intentionally unsupported
- `useId()` and `useTemplateRef("name")` are supported inside setup scope

## Generic Components

Vue-style generic declarations are supported on `<script>`:

```html
<script generic="T, U : Show">
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
let slots : Slots[T, U] = defineSlots()
</script>
```

- `generic="..."` is only valid on `<script>`
- generic parameters must appear in the local contract types referenced by `defineProps()` / `defineEmits()` / `defineSlots()` / `defineExpose()`
- the compiler threads those parameters through generated contract and render signatures
- generics stay type-level only; no runtime validation or runtime type registry is emitted

## Supported Template Features
```html
<script>
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

<style>
.counter {
  display: grid;
  gap: 12px;
}
</style>
```

`<script>` is the default setup-scope block. Use `<script extern>` for module-scope helpers that should live outside render/setup.
The older `<script setup>` spelling still works as an alias, but plain `<script>` is now the canonical form.

`<style>` blocks are scoped by default. Use `<style scoped="false">` when you explicitly want global CSS.

The recommended reactivity surface is an explicit import with a meaningful alias like `@reactivity`. Vapor Moon examples avoid leaking the older luna-internal alias into authoring code.

## Compile output

Running `moon run src/cmd/vapor_moon -- compile examples/basic.mbtv` prints a client module, an SSR module, scoped CSS, and metadata. An excerpt of the current output looks like this:

```text
=== client ===
pub fn render_dom() -> @luna_dom.DomNode {
  let signal = @reactivity.signal,
  let count = signal(0)
  (fn() {
      let __vm_el = @dom.el("div")
      @dom.setAttr(__vm_el, ("class", @dom.attr("counter")))
      @dom.setAttr(__vm_el, ("data-vm-scope", @dom.attr("vm-4048536636")))
      @dom.append(__vm_el.as_node(), @dom.setText(fn() { count.get().to_string() }))
      @dom.into(__vm_el)
    })()
}
=== server ===
pub fn render_ssr() -> @luna_core.StaticDomNode {
  let signal = @reactivity.signal,
  let count = signal(0)
  @luna_core.h("div", [("class", @luna_core.attr_static("counter")), ("data-vm-scope", @luna_core.attr_static("vm-4048536636"))], [
      @luna_core.text_dyn(fn() { count.get().to_string() })
    ])
}
=== css ===
[data-vm-scope="vm-4048536636"] .counter { color: red; }
=== meta ===
component=Basic
extension=.mbtv
scope=vm-4048536636
```
Client-side lowering is intentionally raw-DOM-oriented: native elements become `el -> setAttr -> append -> into`, while SSR still emits static HTML-oriented nodes.
When a component declares `props`, `emits`, or `slots`, the generated module also includes typed contract surfaces and declaration metadata alongside these render functions.

## Compiler macros

Vapor Moon currently supports MoonBit-flavored macro calls inside `<script>`:

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
struct Expose {
  focus : Unit
}
let props : Props = defineProps()
let emit : Emits = defineEmits()
let slots : Slots = defineSlots()
let expose : Expose = defineExpose()
```
For props defaults, pass only a record literal of default values:

```moonbit
let props : Props = defineProps({
  count: 0,
  tone: "primary",
})
```

- these declarations are compiler-only and disappear from lowered setup-scope script
- the compiler generates typed component surfaces such as `ExampleProps`, `ExampleEmits`, `ExampleDomSlots`, and `ExampleSsrSlots`
- a prop with a default stays required inside the component but becomes optional in the generated caller-facing props type
- generated `render_dom` / `render_ssr` functions take those contracts as plain arguments, so the runtime does not own props, emits, or slot bags
- `defineProps()` / `defineEmits()` / `defineSlots()` / `defineExpose()` are zero-argument markers that bind to the annotated local `struct`
- `defineProps({ ... })` is reserved for defaults only, not runtime declarations
- `defineExpose()` is type-first metadata for the component's exposed surface; it participates in generic validation and tooling even though it is erased from lowered setup code
- runtime-declaration literals are intentionally unsupported, so component interfaces stay type-first and MoonBit-native

## Supported template features
Today the template layer supports:

- text nodes and `{{ expression }}`
- static attributes
- dynamic attributes with `:prop="expr"` and `v-bind:prop="expr"`
- event handlers with `@event="expr"` and `v-on:event="expr"`
- Vue-style event modifiers: `.stop`, `.prevent`, `.self`, `.capture`, `.once`, `.passive`
- `v-if`, `v-else-if`, and `v-else`
- `v-for="item in items"` and `v-for="(item, index) in items"`
- `v-show`
- `v-unsafe-html`
- `v-model` on native form controls such as `input`, `textarea`, and `select`
- `v-once`
- `v-match`, `v-case`, and `v-default`
- `ref` and `:ref`
- named slots with `v-slot`, `v-slot:name`, and `#name`
- component-looking tags via uppercase names
- scoped styles

Island and delivery directives are part of the template surface:

- `client:load`
- `client:idle`
- `client:visible`
- `client:media="(max-width: 768px)"`
- `client:only`
- `server:defer`

## CLI

- `moon run src/cmd/vapor_moon -- compile path/to/Component.mbtv` prints a compile snapshot to stdout
- `moon run src/cmd/vapor_moon -- watch path/to/components` recursively watches `.mbtv` files and writes sibling `.client.mbt`, `.server.mbt`, and `.css` outputs on add/change/remove

## Examples

Small examples live in [`examples/`](./examples) and are intended to cover the current surface area without too much ceremony:

- [`examples/basic.mbtv`](./examples/basic.mbtv): the smallest end-to-end SFC with setup, template, and scoped style
- [`examples/directives.mbtv`](./examples/directives.mbtv): `v-if` and `v-for`
- [`examples/macros.mbtv`](./examples/macros.mbtv): typed `defineProps()` and `defineEmits()`
- [`examples/props_defaults.mbtv`](./examples/props_defaults.mbtv): prop defaults and caller-facing optional props
- [`examples/slots.mbtv`](./examples/slots.mbtv): typed `defineSlots()`
- [`examples/reactivity_basics.mbtv`](./examples/reactivity_basics.mbtv): `signal`, `computed`, `watch`, and `effect`
- [`examples/lifecycle_refs.mbtv`](./examples/lifecycle_refs.mbtv): `useId()`, `useTemplateRef()`, `on_mount`, and `on_cleanup`
- [`examples/composable_counter.mbtv`](./examples/composable_counter.mbtv): a small composable built from `luna` primitives
- [`examples/generic_list.mbtv`](./examples/generic_list.mbtv): generic component contracts on `<script generic="...">`
- [`examples/island_visible.mbtv`](./examples/island_visible.mbtv): `client:visible`
- [`examples/media_and_defer.mbtv`](./examples/media_and_defer.mbtv): `client:media(...)` and `server:defer`

## CLI And Tooling

Useful commands:

```bash
moon run src/cmd/vapor_moon -- compile examples/basic.mbtv
moon run src/cmd/vapor_moon -- analyze examples/basic.mbtv
moon run src/cmd/vapor_moon -- diagnostics examples/macros.mbtv
moon run src/cmd/vapor_moon -- hover examples/macros.mbtv 17 13
moon run src/cmd/vapor_moon -- definition examples/macros.mbtv 16 39
moon run src/cmd/vapor_moon -- complete examples/macros.mbtv 17 18
moon run --target js src/cmd/vapor_moon_lsp
```

The CLI currently exposes:

- `compile <file.mbtv>`
- `analyze <file.mbtv>`
- `diagnostics <file.mbtv>`
- `hover <file.mbtv> <line> <character>`
- `definition <file.mbtv> <line> <character>`
- `complete <file.mbtv> <line> <character>`

## Editor Integrations

- VS Code extension source lives in [`editors/vscode/`](./editors/vscode)
- Zed extension source lives in [`editors/zed/`](./editors/zed)
- Neovim runtime files live in [`editors/neovim/`](./editors/neovim)
- quick install notes live in [`editors/README.md`](./editors/README.md)
- the repo-local launcher is [`bin/vapor-moon-lsp`](./bin/vapor-moon-lsp)

The launcher currently shells out to:

```bash
moon run --target js src/cmd/vapor_moon_lsp
```

So editor integrations expect:

- `moon` on `PATH`
- a JS runtime such as `node`, `bun`, or `deno` on `PATH`

## Development

Requirements:

- MoonBit toolchain on `PATH`
- a JS runtime on `PATH` for the editor-facing LSP server

Useful commands:

```bash
bash scripts/patch_mooncakes.sh
moon fmt
moon check
moon test src/compiler
moon test src/tooling
moon build --target js src/lsp
moon test --target js src/lsp
moon build --target js src/cmd/vapor_moon_lsp
```

`bash scripts/patch_mooncakes.sh` reapplies a small local patch for a known `moonbitlang/yacc` dependency warning, and the repo-local pre-commit hook runs it automatically before the test suite.

## Publishing

Recommended release flow:

```bash
moon register   # first time only
moon login
moon test
moon package --list
moon publish
```

Before publishing:

- bump `version` in `moon.mod.json` using semver
- confirm `name`, `repository`, `license`, `description`, and `keywords` are up to date
- review the packaged files with `moon package --list`; this repository uses `exclude` in `moon.mod.json` to keep editor fixtures, examples, scripts, and test files out of the published archive

On newer MoonBit toolchains, `moon publish --dry-run` is also useful before the real publish.

## Git Setup

The repository includes:

- `.gitignore` for MoonBit build outputs and mooncakes cache
- `.gitattributes` for LF normalization
- `.githooks/pre-commit` to run formatting, checks, and compiler/tooling tests

After cloning, enable the repo-local hook path once:

```bash
git config core.hooksPath .githooks
```
