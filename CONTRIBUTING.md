# Contributing to Vapor Moon

Thanks for your interest in Vapor Moon! This document collects the
day-to-day commands and conventions a contributor needs to land a change.

The project is an unpublished hobby tool, but it tries to hold itself to
production-readiness standards: deterministic CI, snapshot-tested compiler
output, and a working LSP across VS Code, Zed, and Neovim. Please help us
keep that bar.

## Prerequisites

The recommended path is **Nix** — it installs every tool below at the
exact version CI uses, with one command:

```bash
nix develop          # activates the flake's devShell
moonbit-install      # pulls the pinned MoonBit toolchain on first run
```

Or with [direnv](https://direnv.net): `direnv allow` once, and entering
the repo auto-activates the shell. The Nix devContainer at
`.devcontainer/` is the same setup for [GitHub Codespaces](https://github.com/codespaces).

If you prefer not to use Nix, install the tools manually:

| Tool | Version | Used for |
| --- | --- | --- |
| [MoonBit CLI](https://www.moonbitlang.com/) | `0.1.20260512` (CI pin) | Compiler, tooling, and tests. The `.github/actions/setup-moonbit` action also pins SHA-256 of the toolchain archive. |
| [Node.js](https://nodejs.org/) | `24.x` | LSP smoke test, VS Code extension, Playwright E2E suite, Vite+ plugin. |
| [pnpm](https://pnpm.io/) | `10.x` | Workspace root + every JS package. |
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

# Vite+ plugin (TS unit tests)
pnpm --dir packages/vite-plugin-vapor-moon install
pnpm --dir packages/vite-plugin-vapor-moon test
pnpm --dir packages/vite-plugin-vapor-moon build

# Vite+ example app (visual smoke)
pnpm --dir examples/vite-app install
pnpm --dir examples/vite-app dev   # opens http://localhost:5179
```

### Inside `nix develop`

The same commands work via the dev shell:

```bash
nix develop --command make ci
nix develop --command moon test --target native
nix develop --command pnpm --dir packages/vite-plugin-vapor-moon test
```

Or stay inside the shell once and run the commands directly.

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

## Pinning a new CI platform

`.github/workflows/ci.yaml` pins the SHA-256 of the MoonBit toolchain
archive per matrix leg. When adding a new platform (e.g. `windows-latest`,
`macos-14`, or `linux-aarch64`):

1. Add the new entry to the `check-native-matrix` `strategy.matrix.include`
   list with empty `archive-sha256` / `core-sha256` values.
2. Push the branch — the `setup-moonbit` composite action surfaces the
   real SHA-256 of `moonbit.tar.gz` and `core.tar.gz` as workflow
   notices (look for the `tar.gz=…` annotations on the new job).
3. Copy those values back into the matrix entry. Keep the inline comment
   pointing here.
4. Bumping the toolchain version (`MOONBIT_EXPECTED_VERSION`) is the
   same flow: temporarily blank the per-platform SHA values, push,
   read the notices, refill.

## Releasing

1. Bump `version` in all of these so they stay in sync:
   - `moon.mod.json`
   - `src/compiler/common/version.mbt` (the `VERSION` constant)
   - `editors/vscode/package.json` and `editors/vscode/package-lock.json`
   - `editors/zed/extension.toml`, `editors/zed/Cargo.toml`, and the
     `zed_vapor_moon` entry in `editors/zed/Cargo.lock`.
2. Update `CHANGELOG.md`: rename the `[Unreleased]` section to the new
   version + date and add a fresh `[Unreleased]` block.
3. Tag `vX.Y.Z` on `main`. The `Release Verify` workflow first runs
   `scripts/verify_changelog_section.sh` (which fails if `CHANGELOG.md`
   has no `## [X.Y.Z]` section, if `[Unreleased]` is still populated,
   or if the tag name does not match the in-repo version). After that
   gate it runs the compiler dry-run publish (`moon publish --dry-run`)
   and packages / uploads / publishes the VS Code extension when
   `VSCE_PAT` is configured.

   You can run the changelog gate locally before tagging:

   ```bash
   bash scripts/verify_changelog_section.sh
   ```
