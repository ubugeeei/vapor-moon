# Implementation Backlog

このファイルは、ローカル実装バックログの棚卸しメモです。production readiness の作業は GitHub Issues を正とし、このファイルでは shipped / partial / open の現在地だけを短く残します。

## Shipped Locally

- **Component `v-model` baseline**: shipped. Component tags accept `v-model` and lower the value into `modelValue` props; `v-model:prop` uses the named prop. Covered by `src/compiler/snapshot/attrs_test.mbt` and `src/compiler/coverage/edge_case_test.mbt`.
- **`<input type="radio" v-model>`**: shipped. Radio inputs generate `checked` state and write the selected `value` on `change`. Covered by `src/compiler/snapshot/attrs_test.mbt` and `src/compiler/coverage/edge_case_test.mbt`; regression bug [#52](https://github.com/ubugeeei/vapor-moon/issues/52) is closed.
- **`<select multiple v-model>`**: shipped. Multiple selects mark options from an `Array[String]` model and write selected option values back on `change`.
- **`<input type="file" v-model>`**: settled invalid. Browsers intentionally keep file selection user-controlled, so templates should use `@change` and read `target.files`.

## Partial / Open Implementation

| Area | Current behavior | Tracking |
| --- | --- | --- |
| Component `v-model` modifiers | Explicitly rejected by the compiler. | Create a GitHub issue before implementation work. |
| LSP directive completions | `v-model` completion mentions select-multiple arrays and file-input `@change`; element-aware details remain open. | [#66](https://github.com/ubugeeei/vapor-moon/issues/66) |

## Production Readiness Issues

Open production-readiness work should live in GitHub Issues instead of growing this local draft file.

| Issue | Scope |
| --- | --- |
| [#57](https://github.com/ubugeeei/vapor-moon/issues/57) | Move CLI command tests out of the main package. |
| [#59](https://github.com/ubugeeei/vapor-moon/issues/59) | Add browser-oriented coverage for component `v-model` lowering. |
| [#60](https://github.com/ubugeeei/vapor-moon/issues/60) | Resolve the packaged VS Code LSP launcher. |
| [#61](https://github.com/ubugeeei/vapor-moon/issues/61) | Fail JS MoonBit checks on non-deprecation warnings. |
| [#62](https://github.com/ubugeeei/vapor-moon/issues/62) | Define the `v-unsafe-html` trust boundary. |
| [#63](https://github.com/ubugeeei/vapor-moon/issues/63) | Pin the MoonBit CLI used by CI and release verification. |
| [#66](https://github.com/ubugeeei/vapor-moon/issues/66) | Expose partial directive support in completion details. |
