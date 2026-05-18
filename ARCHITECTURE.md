# Vapor Moon Architecture

This document is a tour for contributors who want to make non-trivial
changes. For an introduction to the language surface, read the top-level
README. For day-to-day commands, read CONTRIBUTING.md.

## Repository layout

```
.
├── examples/                   # End-to-end .mbtv components used as compiler fixtures and tour.
├── editors/                    # VS Code, Zed, and Neovim integrations.
├── e2e/                        # Playwright-based browser regression suite.
├── scripts/                    # Smoke tests + mooncake patcher.
├── docs/                       # Long-form design notes (ISSUES.md is the live triage table).
└── src/
    ├── cmd/
    │   ├── vapor_moon/         # Old entry point; trampoline to vapor_moon_cli.
    │   ├── vapor_moon_cli/     # CLI surface (compile, watch, --help, --version).
    │   └── vapor_moon_lsp/     # JS-target LSP launcher; spawns the lsp package.
    ├── compiler/               # The .mbtv → MoonBit pipeline. See "Compiler pipeline" below.
    ├── lsp/                    # LSP server (JSON-RPC framing + request handlers).
    ├── tooling/                # Pure analyzers reused by both LSP and the CLI.
    ├── runtime/                # Generated client/server code calls into these helpers.
    │   ├── runtime.mbt         # Shared helpers (sanitization, scope ids).
    │   ├── context/            # provide / inject (Phase 1).
    │   ├── dom/                # Browser-target DOM apply.
    │   └── server/             # Luna-backed SSR adapter.
    └── compiler/coverage/      # Snapshot tests pinning compiler output across feature combinations.
```

## Compiler pipeline (`src/compiler/`)

The compiler runs as a flat pipeline. Each stage is a separate
sub-package so its tests can be moved without disturbing the others.

```
.mbtv source bytes
  ↓ sfc/        parse <script> / <template> / <style> blocks
  ↓ script_setup/ analyze defineProps/Emits/Slots/Expose macros, extract setup imports
  ↓ template/   tokenize → build TemplateNode tree → run structural validators
  ↓ scoped_css/ rewrite selectors, mint a data-vm-scope id
  ↓ codegen/    lower each TemplateNode into client + server MoonBit source
  ↓ contracts/  emit Props/Emits/Slots/Expose typed records
  ↓ CompileOutput { client_code, server_code, css_output, metadata }
```

Tests live in three layers:

- **Per-stage unit tests** (`src/compiler/<stage>/*_test.mbt`). Small,
  fast, focused.
- **Coverage tests** (`src/compiler/coverage/*_test.mbt`). End-to-end
  compiles that assert on substrings of the generated client/server
  output. Catches cross-stage regressions.
- **Snapshot tests** (`src/compiler/snapshot/*_test.mbt`). Pinned exact
  outputs for representative .mbtv inputs. The first thing to break
  when codegen changes.

## LSP and tooling

`src/lsp/` is the JSON-RPC transport (framing, message routing,
serverInfo). `src/tooling/` is where the actual analysis lives —
hover, definition, references, completion, formatting, diagnostics. The
split exists so the CLI (and tests) can call into `tooling` without
spinning up the LSP transport.

`src/cmd/vapor_moon_lsp/` is the JS-only launcher binary that wires
stdio to `lsp/server.handle_message`.

## Runtime split

Generated code never refers to the compiler. It calls into:

- `@hlp` — shared helpers (template-ref typing, scope-id helpers).
- `@dom` — browser primitives (`el`, `setAttr`, `append`, `into`,
  `text`, `setText`, `island`, `component`, …).
- `@vm_server` — SSR adapters that lower to `luna_core` static nodes.
- `@context` — provide / inject Phase 1 registry.
- `@reactivity` — `mizchi/luna/js/resource` re-export for `signal`,
  `computed`, `watch`, `effect`.

Anything new that the compiler emits should be a function in one of
these packages, not a fresh import in generated code.

## CI gates

Every PR runs:

1. `check-native (ubuntu-latest)` and `check-native (macos-latest)` —
   `moon check --deny-warn`, `moon test --target native`, CLI smoke
   script, `moon package --list`.
2. `check-native` — umbrella job needed for the legacy required-check
   name in the repo ruleset.
3. `check-js` — JS-target `moon check`, JS-target tests for `src/lsp`,
   `src/runtime`, `src/runtime/dom`, `src/runtime/server`,
   `src/runtime/context`, LSP launcher smoke script.
4. `editor-integrations` — npm install, VS Code extension manifest
   validation + `vsce package`, Zed `cargo check --locked`.
5. `e2e` — Playwright suite under `e2e/`.

Branch protection requires `check-native` and `check-js` to pass before
merge.

## Adding a new feature

1. **Decide which stage owns it.** Most user-visible changes touch
   `template/` (parse + validate) and `codegen/` (lower).
2. **Add a coverage test** under `src/compiler/coverage/` that
   demonstrates the expected output.
3. **Wire the feature through.** Validator → builder → codegen.
4. **Update the LSP** if the feature is part of the user surface
   (completions, hover, diagnostics).
5. **Add an example** under `examples/` and link it from
   `examples/README.md`.
6. **Document the limitation** if the feature ships partial — README
   and CHANGELOG.

## Files not to grow casually

- `docs/ISSUES.md` — the issue tracker is canonical. Update this only
  for in-flight triage notes.
- `README.md` — keep the "Status" list short. Limitations belong in
  the linked issue, not the README.
- `CHANGELOG.md` — every entry is user-facing. Refactors do not appear.
