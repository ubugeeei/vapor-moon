# Vapor Moon examples

Each `.mbtv` file in this directory is a complete Single File Component
that exercises one slice of the toolchain. They double as compiler
fixtures: most appear in coverage / snapshot tests so a regression in
codegen surfaces as a diff here first.

Pass any of them to the CLI to inspect the generated client / server /
CSS / metadata:

```bash
moon run src/cmd/vapor_moon -- compile examples/basic.mbtv
```

| File | What it shows |
|---|---|
| `basic.mbtv` | Smallest possible SFC — a single reactive counter rendered as text. |
| `composable_counter.mbtv` | Authoring custom composables outside `<script>` and reusing them. |
| `directives.mbtv` | `v-if`, `v-for`, `v-show`, `v-once`, `v-bind`, `v-on`, `v-model`. |
| `ExposedPanel.mbtv` | `defineExpose()` on a child component with a `useTemplateRef` parent. |
| `generic_list.mbtv` | `<script generic="T">` and `defineProps[T]()`. |
| `island_visible.mbtv` | Island delivery with `client:visible`. |
| `lifecycle_refs.mbtv` | `onMounted` + `useTemplateRef` pattern. |
| `macros.mbtv` | `defineProps()`, `defineEmits()`, `defineSlots()` together. |
| `media_and_defer.mbtv` | `client:media="(max-width: 800px)"` and `server-defer`. |
| `props_defaults.mbtv` | `defineProps({ ... })` with record-literal defaults. |
| `provide_inject.mbtv` | Phase 1 `provide` / `inject` registry from `runtime/context` ([#14](https://github.com/ubugeeei/vapor-moon/issues/14)). |
| `todo_list.mbtv` | End-to-end demo: input + checkbox + filter buttons + remove, all backed by a single signal store. Good entry point for a tour of the full feature set. |

## Adding an example

1. Keep the example self-contained: no cross-file component imports
   (see [#13](https://github.com/ubugeeei/vapor-moon/issues/13)
   for the linker design discussion).
2. Wire the example into a coverage test under `src/compiler/coverage/`
   so a codegen regression surfaces here automatically.
3. Add a row to the table above with a one-liner description.
