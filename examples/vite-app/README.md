# Vapor Moon × Vite+ example

Smoke-test app that exercises `@vapor-moon/vite-plugin` end-to-end. The
plugin intercepts `Counter.mbtv` at module-resolution time, spawns the
in-repo compiler, and returns the generated client module to Vite+.

## Run it

```bash
# From this directory (inside the monorepo):
pnpm install
pnpm dev
```

Open the URL Vite prints. Click the button; the count updates via the
signal-driven `render_dom` function in `Counter.mbtv`.

## What this app proves

- `.mbtv` files compile through the plugin without any manual build
  step.
- Scoped CSS lands as a `<style data-vm-source="…">` tag in the
  document head.
- HMR triggers re-render on `.mbtv` change (Phase 1: full module
  invalidation; Phase 2 will land partial updates).

## Notes for the maintainer

- `vite.config.ts` overrides `options.command` so the plugin uses the
  in-repo `moon run` invocation instead of a globally installed
  `vapor-moon` binary. Consumers outside this repo can drop the
  override entirely.
- Lives under `examples/` (not `e2e/`) because it's an integration
  *demonstration*, not a regression gate. The plugin's own unit tests
  cover `parseSnapshot`; this example exists so the README has
  something runnable to point at.
