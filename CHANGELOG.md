# Changelog

All notable changes to **Vapor Moon** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until `1.0.0`, expect breaking changes in any minor release; patch releases stay
backwards compatible.

## [Unreleased]

_Nothing yet — the next change starts here._

## [0.2.0] — 2026-05-19

### Added
- `vapor-moon --help` / `-h` / `help` and `vapor-moon --version` / `-V` flags
  (#80). The version string is sourced from a single `VERSION` constant shared
  with the LSP `serverInfo` payload (#85).
- LSP `textDocument/prepareRename`, `textDocument/rename`, and
  `textDocument/codeAction` handlers — Phase 1 stubs that declare the
  capability and return safe empty responses so editors stop reporting
  "method not found" (#86).
- LSP directive completion details now spell out `v-model` partial-support
  boundaries (supported targets, unsupported targets, modifier matrix) and
  introduce a separate `v-model:prop` entry (#66).
- `v-model` on `<select multiple>` — bound to an `Array[String]` and
  round-tripped through a runtime helper that walks `<option>` children on
  every render and collects `event.target.selectedOptions` on change
  (#64).
- VS Code extension marketplace metadata (`repository`, `bugs`, `homepage`,
  `keywords`, `author`) and `package` / `publish` scripts (#84).
- VS Code extension ships a `LICENSE` and a `.vscodeignore`, silencing
  the `vsce package` warnings.
- Zed extension manifest, `Cargo.toml`, and `Cargo.lock` track the
  `0.1.1` release.
- CI cross-platform matrix: `check-native` now runs on both
  `ubuntu-latest` and `macos-latest` (#83).
- Release workflow now packages the VS Code extension on every tag, uploads
  the `.vsix` as an artifact, and (when `VSCE_PAT` is configured) publishes
  to the Marketplace (#87).
- Repository community-health files: `CONTRIBUTING.md`, `SECURITY.md`,
  GitHub issue / pull-request templates, and a README "Security model"
  section (#81, #82, #88).
- Compiler / runtime docstrings document the `v-unsafe-html` escape-hatch
  contract next to every lowering and validation site (#62).
- `provide` / `inject` Phase 1 — a flat per-JS-realm registry exposed as
  `src/runtime/context`, plus a Phase 2 design comment on #14. Same call-site
  API as the upcoming scoped variant.
- CI: cache the MoonBit toolchain across runs, skip reinstall on cache hit.
- CI: `setup-moonbit` surfaces archive / core SHA-256 as workflow notices
  so new platforms can be pinned without a local Mac.
- CI: umbrella `check-native` job (kept for the legacy required-check name).
- CI: stale issue / PR bot, path-based PR auto-labeler, dependabot grouping
  tightened (PR limit, semver-major ignores, per-ecosystem labels).
- Release: Release Drafter auto-drafts the next GitHub Release on every
  push to main, with PRs bucketed by label and semantic version resolved
  from labels.
- Repo hygiene: `.editorconfig`, expanded `.gitattributes`, `.nvmrc`,
  `.node-version`, `.prettierrc.json`, `.prettierignore`,
  `.github/CODEOWNERS`, `.github/FUNDING.yml`.
- `.devcontainer/` for one-click Codespaces / Remote-Containers hacking.
- VS Code / Zed editor manifests bumped to `0.1.1` in lock-step with
  `moon.mod.json` and the `VERSION` constant.
- Issue templates converted to YAML forms with client-side validation.
- Docs: `ARCHITECTURE.md`, `CITATION.cff`, `examples/README.md`,
  `examples/todo_list.mbtv`, `examples/provide_inject.mbtv`, README
  Quickstart, README status badges.
- Tests: coverage for the provide / inject and select-multiple v-model
  lowering paths.

### Changed
- 116 `not(expr)` prelude calls replaced with the `!expr` operator across
  `src/` (part 1 of the MoonBit 0.9 deprecation cleanup, #53).
- VS Code extension version bumped to `0.1.1` and is now CI-asserted to
  track `moon.mod.json` (#84).
- `<input type="file">` v-model rejection is now a final compile-time
  error with a message pointing at the recommended `@change` +
  `event.target.files` pattern (#65).
- README "Status" section refreshed: every shipped feature listed,
  intentional limitations enumerated with issue links.

### Fixed
- LSP `initialize` response now reports the real package version instead of
  a stale hard-coded `0.1.0` (#85).
- `vsce package` warnings (LICENSE, .vscodeignore) silenced.
- `check-js` LSP test failed on JS target due to untypeable empty array;
  annotation added.

## [0.1.1] — 2026-05-19

### Added
- Component event listeners (`@event` / `v-on:event`) and component-side
  `v-model` lowering (#78, plus regression coverage in #71, #72).
- Builtin component shells for `<Teleport>`, `<Transition>`, and
  `<TransitionGroup>` carried into client/server output.
- `vapor-moon analyze` / `diagnostics` / `hover` / `definition` /
  `references` / `complete` / `format` / `watch` CLI subcommands.
- `defineExpose()` macro and template-ref binding helpers.
- `v-match` / `v-case` / `v-else` / `v-else-if` directive support, dynamic
  components (`<component :is>`), v-bind full syntax.
- Incremental compilation infrastructure backed by `mizchi/ripple` and a
  watch-mode runner that writes generated outputs beside the source file.
- VS Code, Zed, and Neovim editor integrations, plus a stdio JSON-RPC LSP
  server.

### Changed
- `<style>` blocks are scoped by default. Use `<style scoped="false">` for
  global CSS.
- `v-html` renamed to `v-unsafe-html` to make the security boundary
  explicit (#27, with documentation update in #67).
- CLI now returns nonzero exit codes for usage, file-read, and compile
  failures (#43).
- CI workflows hardened: workflow setup consolidated, MoonBit toolchain
  pinned by version and SHA-256, JS LSP smoke test added, deny-warn on JS
  builds, editor-integration manifest validation (#41, #42, #44, #46, #61,
  #68, #73, #74, #75).

### Fixed
- LSP rejects negative `textDocument` positions (#51).
- Radio `v-model` change handlers now write the selected `value` instead of
  `checked` (#40, #52).
- Packaged VS Code LSP launcher resolves correctly after extension
  bundling (#60, #69).
- Template indentation preserved in formatter fallbacks.

## [0.1.0] — 2025-12

- Initial public preview: `.mbtv` Single File Component parser, client and
  server (luna SSR) code generation, scoped style hashing, basic editor
  tooling.

[Unreleased]: https://github.com/ubugeeei/vapor-moon/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ubugeeei/vapor-moon/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/ubugeeei/vapor-moon/releases/tag/v0.1.1
[0.1.0]: https://github.com/ubugeeei/vapor-moon/releases/tag/v0.1.0
