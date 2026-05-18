## Summary

<!-- One or two sentences on what this PR changes. -->

## Why

<!-- The motivation: linked issue, bug repro, user need. -->

Closes #

## Test plan

- [ ] `moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target native`
- [ ] `moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target js`
- [ ] `moon test --target native`
- [ ] `moon test --target js src/lsp` (if LSP changed)
- [ ] `bash scripts/smoke_cli.sh` (if CLI changed)
- [ ] `bash scripts/smoke_lsp.sh` (if LSP launcher changed)
- [ ] Updated `CHANGELOG.md` `[Unreleased]` if user-visible behavior changed.

## Checklist

- [ ] Commits use the conventional prefixes documented in CONTRIBUTING.md.
- [ ] No accidental snapshot updates: every changed file under
      `src/compiler/snapshot/` / `src/compiler/coverage/` is intentional.
- [ ] If the VS Code extension was touched, `editors/vscode/package.json`
      and `package-lock.json` versions still match `moon.mod.json`.
