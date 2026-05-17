#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import subprocess
import sys

root = sys.argv[1]
body = json.dumps({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {},
}, separators=(",", ":")).encode("utf-8")
wire = b"Content-Length: " + str(len(body)).encode("ascii") + b"\r\n\r\n" + body

proc = subprocess.run(
    ["bin/vapor-moon-lsp"],
    cwd=root,
    input=wire,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    timeout=20,
)

stdout = proc.stdout.decode("utf-8", "replace")
stderr = proc.stderr.decode("utf-8", "replace")

if proc.returncode != 0:
    print(stderr or stdout)
    raise SystemExit(proc.returncode)

if "Content-Length:" not in stdout or '"hoverProvider":true' not in stdout:
    print("LSP initialize response did not include expected capabilities")
    print(stdout)
    print(stderr)
    raise SystemExit(1)
PY
