# Getting help

Thanks for using Vapor Moon. The fastest path depends on what you need.

## Questions, design discussions, "how do I"
Open a [GitHub Discussion](https://github.com/ubugeeei/vapor-moon/discussions).
Free-form prose is welcome — please link the relevant `.mbtv` snippet or
generated client/server output when possible.

## Bug reports
File a [Bug report issue](https://github.com/ubugeeei/vapor-moon/issues/new?template=bug_report.yml).
The form will ask for a minimal reproduction, expected vs. actual
behavior, and your MoonBit / Vapor Moon versions — please fill all
required fields. Small repros are typically resolved within a few days;
ten-line snippets land bug fixes faster than ten-file ones.

## Feature requests
Skim the [README "Status" section](../README.md#status) first to confirm
the feature isn't already either shipped or intentionally out of scope.
If you still want it, open a [Feature request issue](https://github.com/ubugeeei/vapor-moon/issues/new?template=feature_request.yml)
with a concrete use case.

## Security
**Do not** open a public issue for security disclosures. Follow the
process in [SECURITY.md](../SECURITY.md) — typically a private
GitHub Security Advisory.

## Editor / LSP problems
Editor integration bugs are still bug reports, but please include:
- Editor + version (e.g. `VS Code 1.96.0`),
- The output of `vapor-moon --version`,
- The LSP launcher trace (set `vaporMoon.languageServer.traceLevel` to
  `verbose` in VS Code's settings, then reproduce).
