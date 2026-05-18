# Contributing to Vapor Moon

Thanks for your interest in Vapor Moon! This document collects the
day-to-day commands and conventions a contributor needs to land a change.

The project is an unpublished hobby tool, but it tries to hold itself to
production-readiness standards: deterministic CI, snapshot-tested compiler
output, and a working LSP across VS Code, Zed, and Neovim. Please help us
keep that bar.

## Prerequisites

| Tool | Version | Used for |
| --- | --- | --- |
| [MoonBit CLI](https://www.moonbitlang.com/) | `0.1.20260512` (CI pin) | Compiler, tooling, and tests. The `.github/actions/setup-moonbit` action also pins SHA-256 of the toolchain archive. |
| [Node.js](https://nodejs.org/) | `24.x` | LSP smoke test, VS Code extension, Playwright E2E suite. |
| [pnpm](https://pnpm.io/) | `10.x` | `e2e/` workspace. |
| [Rust toolchain](https://rustup.rs/) | stable | Building the Zed extension (`editors/zed`). |

The repo ships `.githooks/pre-commit` — enable it locally with:

```bash
git config core.hooksPath .githooks
```

It runs `moon fmt`, `moon check`, the compiler/tooling tests, and (when
`node` is on `PATH`) the JS LSP tests.

## Local commands

```bash
# Type-check & lint
moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target native
moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target js

# Native tests (compiler, runtime, CLI, tooling)
moon test --target native

# JS-only tests (LSP, runtime/dom, runtime/server)
moon test --target js src/lsp
moon test --target js src/runtime
moon test --target js src/runtime/dom
moon test --target js src/runtime/server

# CLI surface
bash scripts/smoke_cli.sh

# LSP launcher
bash scripts/smoke_lsp.sh

# End-to-end (compiled output + browser)
pnpm --dir e2e install --frozen-lockfile
pnpm --dir e2e exec playwright install chromium --with-deps
pnpm --dir e2e test
```

## Conventional commits

Commit subjects follow the prefixes already in `git log`:

| Prefix | When |
| --- | --- |
| `feat:` | New user-visible behavior. |
| `feat!:` | Breaking change. |
| `fix:` | Bug fix. |
| `test:` | Test-only additions or rewrites. |
| `docs:` | README, CHANGELOG, CONTRIBUTING, etc. |
| `ci:` | Workflow / dependency-pin changes. |
| `chore:` | Build / deps / housekeeping. |
| `refactor:` | Internal restructure with no behavior change. |
| `style:` | Formatting / cosmetic. |
| `lsp:`, `cli:`, `compiler:` | Optional scope-tagged variants used for area-specific work. |

The squash-merge subject becomes the commit subject — write it accordingly.

## Pull request checklist

When opening a PR, make sure:

- [ ] `moon check --deny-warn` passes for both `native` and `js` targets.
- [ ] `moon test` passes (snapshots updated where intentional).
- [ ] `scripts/smoke_cli.sh` and, if you touched the LSP, `scripts/smoke_lsp.sh` pass.
- [ ] If user-visible behavior changed, `CHANGELOG.md` `[Unreleased]` is updated.
- [ ] If the change affects the VS Code extension manifest or version, the
      lockfile and `editors/vscode/package.json` are in sync with
      `moon.mod.json`.

## Backlog management

- Production-readiness tasks live in GitHub Issues with the
  `production-readiness` label.
- `docs/ISSUES.md` is the short snapshot of shipped / partial / open work;
  it links into GitHub Issues, not the other way around.
- For non-trivial feature work, open an issue first to align on shape
  before sending the PR.

## Releasing

1. Bump `version` in all of these so they stay in sync:
   - `moon.mod.json`
   - `src/compiler/common/version.mbt` (the `VERSION` constant)
   - `editors/vscode/package.json` and `editors/vscode/package-lock.json`
   - `editors/zed/extension.toml`, `editors/zed/Cargo.toml`, and the
     `zed_vapor_moon` entry in `editors/zed/Cargo.lock`.
2. Update `CHANGELOG.md`: rename the `[Unreleased]` section to the new
   version + date and add a fresh `[Unreleased]` block.
3. Tag `vX.Y.Z` on `main`. The `Release Verify` workflow runs the
   compiler dry-run publish (`moon publish --dry-run`) and packages /
   uploads / publishes the VS Code extension when `VSCE_PAT` is
   configured.
