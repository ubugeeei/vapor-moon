{
  description = "Vapor Moon — MoonBit-first SFC toolchain dev shell.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Expected MoonBit version — kept in sync with:
        # - .github/workflows/ci.yaml (MOONBIT_EXPECTED_VERSION)
        # - .github/actions/setup-moonbit/action.yml (expected-version default)
        # - src/compiler/common/version.mbt (build target)
        moonbitVersion = "0.1.20260512";

        moonbitTarget =
          if pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64 then "darwin-aarch64"
          else if pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64 then "linux-aarch64"
          else if pkgs.stdenv.isLinux then "linux-x86_64"
          else throw "Unsupported Nix host for MoonBit: ${system}";

        # Wrapper around the upstream MoonBit installer. We don't try to
        # build moon from source (it's not open source) — the script
        # mirrors what .github/actions/setup-moonbit/action.yml does,
        # but uses MOON_HOME inside the user's XDG data dir so multiple
        # projects on one machine can coexist.
        moonbit-install = pkgs.writeShellScriptBin "moonbit-install" ''
          set -euo pipefail
          MOON_HOME="''${MOON_HOME:-$HOME/.local/share/moonbit}"
          export MOON_HOME
          BIN_DIR="$MOON_HOME/bin"
          LIB_DIR="$MOON_HOME/lib"

          if [[ -x "$BIN_DIR/moon" ]]; then
            actual="$($BIN_DIR/moon version 2>/dev/null | sed -n 's/^moon \([^ ]*\).*/\1/p' || true)"
            if [[ "$actual" == "${moonbitVersion}" && -d "$LIB_DIR/core" ]]; then
              echo "MoonBit ${moonbitVersion} already installed at $MOON_HOME"
              exit 0
            fi
          fi

          tmp="$(mktemp -d)"
          trap 'rm -rf "$tmp"' EXIT
          echo "Downloading MoonBit ${moonbitVersion} (${moonbitTarget})..."
          ${pkgs.curl}/bin/curl --proto '=https' --tlsv1.2 -fsSL \
            "https://cli.moonbitlang.com/binaries/${moonbitVersion}/moonbit-${moonbitTarget}.tar.gz" \
            -o "$tmp/moonbit.tar.gz"

          mkdir -p "$MOON_HOME"
          rm -rf "$LIB_DIR" "$MOON_HOME/include"
          tar xf "$tmp/moonbit.tar.gz" --directory="$MOON_HOME"
          chmod +x "$BIN_DIR"/* "$BIN_DIR/internal/tcc" || true

          ${pkgs.curl}/bin/curl --proto '=https' --tlsv1.2 -fsSL \
            "https://cli.moonbitlang.com/cores/core-${moonbitVersion}.tar.gz" \
            -o "$tmp/core.tar.gz"
          mkdir -p "$LIB_DIR"
          rm -rf "$LIB_DIR/core"
          tar xf "$tmp/core.tar.gz" --directory="$LIB_DIR"

          PATH="$BIN_DIR:$PATH" "$BIN_DIR/moon" -C "$LIB_DIR/core" bundle --warn-list -a --all
          PATH="$BIN_DIR:$PATH" "$BIN_DIR/moon" -C "$LIB_DIR/core" bundle --warn-list -a --target wasm-gc --quiet

          echo "MoonBit ${moonbitVersion} installed at $MOON_HOME"
        '';

      in {
        devShells.default = pkgs.mkShell {
          name = "vapor-moon";

          packages = with pkgs; [
            # MoonBit toolchain installer (binary tarball — not buildable
            # from source today). Runs lazily via shellHook.
            moonbit-install

            # Node toolchain for the e2e suite and editor extensions.
            # Pinned to 24 to match .nvmrc and CI's NODE_VERSION.
            nodejs_24
            pnpm

            # Rust toolchain for `cargo check --locked` on the Zed extension.
            rustc
            cargo
            rust-analyzer

            # Common dev tools that scripts/ assume exist.
            bash
            curl
            git
            gnumake
            jq
            shellcheck
          ];

          shellHook = ''
            export MOON_HOME="''${MOON_HOME:-$HOME/.local/share/moonbit}"
            export PATH="$MOON_HOME/bin:$PATH"
            export MOONBIT_EXPECTED_VERSION="${moonbitVersion}"

            if [[ ! -x "$MOON_HOME/bin/moon" ]]; then
              echo "[vapor-moon] MoonBit not found in $MOON_HOME."
              echo "[vapor-moon] Run \`moonbit-install\` to fetch and pin MoonBit ${moonbitVersion}."
            fi

            echo "[vapor-moon] dev shell ready. Try: make help"
          '';
        };

        # Nix flake checks — kept minimal in Phase 1. Once moon's
        # toolchain is installed in CI we can wire `make ci` here.
        checks = {
          shell-format = pkgs.runCommand "shellcheck" { } ''
            ${pkgs.shellcheck}/bin/shellcheck \
              ${self}/scripts/smoke_cli.sh \
              ${self}/scripts/smoke_lsp.sh \
              ${self}/scripts/patch_mooncakes.sh
            touch $out
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
