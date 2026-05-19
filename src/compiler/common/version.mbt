///|
/// Single source of truth for the Vapor Moon package version surfaced by the
/// CLI (`--version`) and the LSP `initialize` response.
///
/// Keep this constant in sync with the `version` field of `moon.mod.json` at
/// the repository root. `scripts/smoke_cli.sh` enforces the invariant in CI.
pub const VERSION : String = "0.2.0"
