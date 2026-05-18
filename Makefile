# Vapor Moon — common developer tasks.
#
# Wraps the moon CLI and the editor / e2e tooling so contributors don't
# have to memorize the exact incantations from CONTRIBUTING.md. Every
# target is also documented in CONTRIBUTING.md so the manual route stays
# discoverable.

.PHONY: help fmt check test test-native test-js smoke smoke-cli smoke-lsp \
        vsce-package vsce-publish clean ci

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Run moon fmt across the workspace.
	moon fmt

check: ## Type-check the workspace on the native target with deny-warn.
	moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target native

check-js: ## Type-check the workspace on the JS target.
	moon check --deny-warn --warn-list -deprecated_syntax-deprecated --target js

test: test-native ## Alias for test-native.

test-native: ## Run native moon tests.
	moon test --target native

test-js: ## Run JS-target tests for the runtime + LSP packages.
	moon test --target js src/lsp
	moon test --target js src/runtime
	moon test --target js src/runtime/dom
	moon test --target js src/runtime/server

smoke: smoke-cli smoke-lsp ## Run all smoke scripts.

smoke-cli: ## CLI smoke script (--help, --version, basic compile).
	bash scripts/smoke_cli.sh

smoke-lsp: ## LSP launcher smoke script.
	bash scripts/smoke_lsp.sh

vsce-package: ## Package the VS Code extension into a local .vsix.
	cd editors/vscode && npm run package

vsce-publish: ## Publish the VS Code extension (needs VSCE_PAT).
	cd editors/vscode && npm run publish

ci: fmt check check-js test-native smoke ## Run the same gates CI does, locally.

clean: ## Remove moon build artifacts.
	rm -rf _build target
