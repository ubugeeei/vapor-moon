#!/usr/bin/env bash
set -eu

export LC_ALL=C
export LANG=C

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PKG="$ROOT/.mooncakes/moonbitlang/yacc/src/lib/parser/test/moon.pkg"
TEST_FILE="$ROOT/.mooncakes/moonbitlang/yacc/src/lib/parser/test/test.mbt"
PARSER_REPORT="$ROOT/.mooncakes/moonbitlang/parser/basic/report.mbt"

if [ -f "$PKG" ]; then
  perl -0pi -e 's/"moonbitlang\/core\/test",/"moonbitlang\/core\/test" \@moon_test,/g' "$PKG"
fi

if [ -f "$TEST_FILE" ]; then
  perl -0pi -e 's/\@test\.Test/\@moon_test.Test/g' "$TEST_FILE"
fi

if [ -f "$PARSER_REPORT" ]; then
  perl -0pi -e 's/} derive\(Show\)/}/g' "$PARSER_REPORT"
fi
