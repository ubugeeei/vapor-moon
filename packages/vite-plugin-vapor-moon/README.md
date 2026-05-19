# @vapor-moon/vite-plugin

Vite+ plugin for [Vapor Moon](https://github.com/ubugeeei/vapor-moon)
`.mbtv` Single File Components.

> **Status: Phase 1.** Synchronous compile-per-load, no batching, no
> partial HMR updates. Suitable for prototyping with small projects;
> tracked work on Phase 2 (async batched compile) lives in the main
> repo's issue tracker.

## Install

```bash
pnpm add -D @vapor-moon/vite-plugin
# plus the compiler itself somewhere on PATH:
#   inside this repo:   make ci  (uses `moon run src/cmd/vapor_moon`)
#   distributed:        npm i -g vapor-moon (when the binary ships)
```

## Use

```ts
// vite.config.ts
import { defineConfig } from "vite";
import { vaporMoon } from "@vapor-moon/vite-plugin";

export default defineConfig({
  plugins: [
    vaporMoon({
      // Optional — defaults to the in-repo `moon run` invocation.
      command: ["vapor-moon", "compile"],
    }),
  ],
});
```

```ts
// any .ts in your app:
import Counter from "./components/Counter.mbtv";
```

The plugin spawns the Vapor Moon compiler for each `.mbtv` file, parses
the `=== client ===` / `=== css ===` sections, emits the client code as
the module body, and appends a `<style>` tag for any scoped CSS. HMR
busts the cache on every `.mbtv` change.

## Options

| Option | Default | Notes |
| --- | --- | --- |
| `command` | `["moon", "run", "src/cmd/vapor_moon", "--", "compile"]` | Compiler invocation. The plugin appends the resolved file path. |
| `cwd` | Vite's project root | Working directory for the spawn. |
| `extensions` | `[".mbtv"]` | Which extensions to intercept. |
| `preserveModuleUrl` | `true` | Sets `import.meta.url` on the generated module so `useTemplateRef` IDs survive HMR. |

## Roadmap

- **Phase 1 (this release)** — synchronous compile, full module
  invalidation on change.
- **Phase 2** — long-lived compiler service over stdio so we don't
  spawn `moon` per file.
- **Phase 3** — partial HMR updates (re-render only the changed
  component without rebuilding its module graph).
- **Phase 4** — SSR adapter exposing `render_ssr` as a named export.

## License

MIT, same as the parent project.
