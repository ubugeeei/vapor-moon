# Security policy

Vapor Moon is an unpublished hobby project, but the compiler emits code
that runs in users' browsers, so we treat security reports seriously.

## Supported versions

We backport security fixes to the latest minor release on the default
branch. Older `0.x` releases are not maintained.

| Version | Supported |
| --- | --- |
| `0.1.x` | Yes |
| `< 0.1` | No |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for suspected vulnerabilities.

Use [GitHub Security Advisories](https://github.com/ubugeeei/vapor-moon/security/advisories/new)
("Report a vulnerability") so the maintainers can triage privately. If
GitHub Security Advisories are unavailable to you, email the maintainer
listed in the repository profile.

We aim to acknowledge new reports within seven days and to ship a fix or
mitigation within thirty days of triage. Reporters will be credited in the
release notes unless they ask otherwise.

## In-scope surfaces

The following areas are explicitly in scope for vulnerability reports:

- **HTML injection / XSS in generated client and SSR output.** The
  template compiler is expected to HTML-escape every interpolation
  (`{{ ... }}`, `v-text`, dynamic attribute values) on both targets. See
  the README "Security model" section for the full contract.
- **`v-unsafe-html` lowering.** Bypassing escape is the directive's
  *advertised* behavior, but the compiler must reject the directive on
  void elements, components, and slots (see #62). If you can sneak `<`
  past the validator without using `v-unsafe-html`, that is a bug.
- **LSP request handling.** The stdio server runs locally but parses
  arbitrary JSON-RPC payloads. Crashes, out-of-memory paths, or path
  traversal via `textDocument/uri` are in scope.
- **CLI argument and file handling.** Path traversal via `compile`,
  `watch`, or `format` arguments is in scope; the CLI assumes the caller
  controls the working tree but should not silently follow attacker-
  controlled symlinks outside it.

## Out of scope

- Vulnerabilities in upstream MoonBit toolchains, `mizchi/luna`,
  `mizchi/js`, `mizchi/ripple`, or `moonbitlang/*` packages. Please
  report those to their respective maintainers; we will mirror the fix.
- Issues that only reproduce against `node_modules/` of `editors/vscode`
  or `e2e/` — those are pinned via lockfiles and updated through
  Dependabot.
- Denial of service via deeply nested user input where the only mitigation
  is "don't compile attacker-supplied components." Defense-in-depth ideas
  are still welcome as enhancement issues, but won't be treated as
  embargoed reports.
