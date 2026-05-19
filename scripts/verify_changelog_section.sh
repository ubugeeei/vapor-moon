#!/usr/bin/env bash
#
# Verify that CHANGELOG.md contains a section for the version currently
# declared in moon.mod.json before letting a release proceed.
#
# Failure modes (each exits non-zero with a pointed message):
#   - moon.mod.json version unreadable.
#   - CHANGELOG.md has no `## [x.y.z] — …` section for the current
#     version.
#   - When GITHUB_REF_NAME is set (CI tag push), the tag does not match
#     `v$VERSION` — caller probably forgot to bump moon.mod.json or
#     tagged the wrong commit.
#   - The [Unreleased] section is non-empty (i.e. still pointing at the
#     would-be-released body). Tagging would orphan those entries.
#
# Run locally via `bash scripts/verify_changelog_section.sh`.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

version="$(grep -m1 '"version"' moon.mod.json | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [ -z "$version" ]; then
  echo "verify_changelog_section: could not read version from moon.mod.json" >&2
  exit 1
fi

if ! grep -Eq "^## \[${version}\]" CHANGELOG.md; then
  echo "verify_changelog_section: CHANGELOG.md has no '## [${version}]' section." >&2
  echo "Add an entry under '## [${version}] — YYYY-MM-DD' before tagging." >&2
  exit 1
fi

unreleased_body="$(awk '
  /^## \[Unreleased\]/ { inside=1; next }
  /^## \[/            { inside=0 }
  inside && NF        { print }
' CHANGELOG.md | grep -Ev '^[[:space:]]*_Nothing yet' || true)"
if [ -n "$unreleased_body" ]; then
  echo "verify_changelog_section: [Unreleased] section is not empty." >&2
  echo "Move its contents under the version section before tagging." >&2
  exit 1
fi

if [ -n "${GITHUB_REF_NAME:-}" ]; then
  expected_tag="v${version}"
  if [ "${GITHUB_REF_NAME}" != "$expected_tag" ]; then
    echo "verify_changelog_section: GITHUB_REF_NAME='${GITHUB_REF_NAME}' does not match moon.mod.json version '${expected_tag}'." >&2
    echo "Either bump moon.mod.json or retag with '${expected_tag}'." >&2
    exit 1
  fi
fi

echo "verify_changelog_section: CHANGELOG.md has '## [${version}]' and [Unreleased] is empty."
