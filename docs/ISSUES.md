# Implementation Backlog

このファイルは、ローカル実装バックログの棚卸しメモです。production readiness の作業は GitHub Issues を正とし、このファイルでは shipped / partial / open の現在地だけを短く残します。

## Shipped Locally

- **Component `v-model`**: shipped. Component tags accept `v-model` and lower the value into `modelValue` props plus an `update:modelValue` listener; `v-model:prop` uses the named prop and `update:prop`. Covered by `src/compiler/snapshot/attrs_test.mbt` and `src/compiler/coverage/edge_case_test.mbt`.
- **Component event listeners**: shipped. Component tags accept `@event` / `v-on:event` listeners and carry them through component placeholder metadata in client and server output. Covered by `src/compiler/coverage/edge_case_test.mbt`.
- **`<input type="radio" v-model>`**: shipped. Radio inputs generate `checked` state and write the selected `value` on `change`. Covered by `src/compiler/snapshot/attrs_test.mbt` and `src/compiler/coverage/edge_case_test.mbt`; regression bug [#52](https://github.com/ubugeeei/vapor-moon/issues/52) is closed.

## Partial / Open Implementation

| Area | Current behavior | Tracking |
| --- | --- | --- |
| Component `v-model` modifiers | Explicitly rejected by the compiler. | Create a GitHub issue before implementation work. |
| `v-model` on `<input type="file">` | Explicitly rejected; decide whether to keep it invalid or design `files` sync. | [#65](https://github.com/ubugeeei/vapor-moon/issues/65) |
| `v-model` on `<select multiple>` | Explicitly rejected; array sync and initial multiple selection are not implemented. | [#64](https://github.com/ubugeeei/vapor-moon/issues/64) |
| LSP directive completions | `v-model` is listed generically, without partial-support details. | [#66](https://github.com/ubugeeei/vapor-moon/issues/66) |

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
| [#64](https://github.com/ubugeeei/vapor-moon/issues/64) | Support `v-model` on `<select multiple>`. |
| [#65](https://github.com/ubugeeei/vapor-moon/issues/65) | Settle file input `v-model` behavior. |
| [#66](https://github.com/ubugeeei/vapor-moon/issues/66) | Expose partial directive support in completion details. |
