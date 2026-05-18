#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp "${TMPDIR:-/tmp}/vapor-moon-publish.XXXXXX")"
trap 'rm -f "$OUT"' EXIT

cd "$ROOT"

set +e
moon publish --dry-run 2>&1 | tee "$OUT"
status=${PIPESTATUS[0]}
set -e

if [ "$status" -eq 0 ]; then
  exit 0
fi

if grep -q "Dry run completed successfully" "$OUT"; then
  echo "::warning::moon publish --dry-run completed successfully, but moon exited with status $status."
  exit 0
fi

if grep -q "duplicated with an existing version" "$OUT"; then
  echo "::warning::moon publish --dry-run reached the registry, but this version already exists."
  exit 0
fi

exit "$status"
