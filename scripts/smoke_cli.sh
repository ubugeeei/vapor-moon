#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp "${TMPDIR:-/tmp}/vapor-moon-cli.XXXXXX")"
trap 'rm -f "$OUT"' EXIT

cd "$ROOT"

if moon run src/cmd/vapor_moon >"$OUT" 2>&1; then
  echo "expected CLI usage without arguments to fail"
  cat "$OUT"
  exit 1
fi
grep -q "Usage:" "$OUT"

if moon run src/cmd/vapor_moon -- compile "$ROOT/.missing-smoke-input.mbtv" >"$OUT" 2>&1; then
  echo "expected compile of a missing file to fail"
  cat "$OUT"
  exit 1
fi
grep -q "failed to read" "$OUT"

if moon run src/cmd/vapor_moon -- watch "$ROOT/.missing-smoke-watch-root" >"$OUT" 2>&1; then
  echo "expected watch of a missing directory to fail"
  cat "$OUT"
  exit 1
fi
grep -q "watch root does not exist" "$OUT"

if moon run src/cmd/vapor_moon -- hover "$ROOT/examples/basic.mbtv" nope 0 >"$OUT" 2>&1; then
  echo "expected hover with an invalid line argument to fail"
  cat "$OUT"
  exit 1
fi
grep -q "invalid integer argument: nope" "$OUT"

moon run src/cmd/vapor_moon -- compile "$ROOT/examples/basic.mbtv" >"$OUT"
grep -q "=== client ===" "$OUT"
grep -q "=== server ===" "$OUT"
grep -q "component=Basic" "$OUT"

# --help / -h / help exit 0 and surface the structured help.
for flag in --help -h help; do
  moon run src/cmd/vapor_moon -- "$flag" >"$OUT"
  grep -q "^USAGE:" "$OUT"
  grep -q "^COMMANDS:" "$OUT"
done

# --version / -V exit 0 and print the package version that matches moon.mod.json.
expected_version="$(grep -m1 '"version"' "$ROOT/moon.mod.json" | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [ -z "$expected_version" ]; then
  echo "could not read version from moon.mod.json"
  exit 1
fi
for flag in --version -V; do
  moon run src/cmd/vapor_moon -- "$flag" >"$OUT"
  grep -q "^vapor-moon ${expected_version}$" "$OUT"
done

# `check` is the pass/fail gate for CI / pre-commit. Silent + exit 0 on
# success across one or many files; exit 1 with `file:line:col` lines
# when any file has diagnostics.
moon run src/cmd/vapor_moon -- check "$ROOT/examples/basic.mbtv" >"$OUT"
if [ -s "$OUT" ]; then
  echo "expected `check` to be silent on success"
  cat "$OUT"
  exit 1
fi

moon run src/cmd/vapor_moon -- check "$ROOT/examples/basic.mbtv" "$ROOT/examples/todo_list.mbtv" >"$OUT"
if [ -s "$OUT" ]; then
  echo "expected `check` to be silent on multi-file success"
  cat "$OUT"
  exit 1
fi

# Failure path: forge a broken SFC, ensure `check` exits 1 and emits a
# `path:line:col [severity] message` line.
broken="$(mktemp "${TMPDIR:-/tmp}/vapor-moon-broken.XXXXXX.mbtv")"
trap 'rm -f "$OUT" "$broken"' EXIT
cat > "$broken" <<'EOF'
<script>
let emit = defineEmits()
</script>
<template>
  <input v-model:value='broken' />
</template>
EOF
if moon run src/cmd/vapor_moon -- check "$broken" >"$OUT" 2>&1; then
  echo "expected `check` to fail on a broken SFC"
  cat "$OUT"
  exit 1
fi
grep -qE ":[0-9]+:[0-9]+ \[error\] " "$OUT"
