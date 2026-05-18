#!/usr/bin/env bash
# Devcontainer post-create — install MoonBit + project deps so the
# container is ready to `moon test --target native` on first open.
set -euo pipefail

EXPECTED_VERSION="${MOONBIT_EXPECTED_VERSION:-0.1.20260512}"

if ! command -v moon >/dev/null 2>&1; then
  echo "[post-create] Installing MoonBit toolchain..."
  curl --proto '=https' --tlsv1.2 -fsSL \
    "https://cli.moonbitlang.com/install/unix.sh" | bash
  echo 'export PATH="$HOME/.moon/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.moon/bin:$PATH"
fi

# Pin to the expected version so the devcontainer matches CI.
moon version

# Pull workspace dependencies.
moon update
moon install

# Apply the project's mooncake patches if the script exists.
if [ -x ./scripts/patch_mooncakes.sh ]; then
  bash ./scripts/patch_mooncakes.sh
fi

echo "[post-create] Ready. Try: make ci"
