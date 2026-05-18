#!/usr/bin/env bash
# Devcontainer post-create — set up the Nix-based dev environment.
# The base image already ships Nix; we just need to evaluate the flake
# and pull MoonBit on first entry.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "[post-create] Evaluating Nix flake..."
nix flake show >/dev/null

echo "[post-create] Pre-warming the dev shell (this fetches all deps once)..."
nix develop --command bash -lc 'echo "shell ok"'

echo "[post-create] Installing MoonBit ${MOONBIT_EXPECTED_VERSION:-0.1.20260512}..."
nix develop --command moonbit-install

echo "[post-create] Pulling MoonBit workspace deps..."
nix develop --command bash -lc 'moon update && moon install'

if [ -x ./scripts/patch_mooncakes.sh ]; then
  echo "[post-create] Applying mooncake patches..."
  nix develop --command bash ./scripts/patch_mooncakes.sh
fi

echo "[post-create] Ready. Try: nix develop --command make ci"
echo "[post-create] Or with direnv installed: direnv allow"
