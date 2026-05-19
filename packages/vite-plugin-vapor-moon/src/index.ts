import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import type { Plugin, ResolvedConfig } from "vite";

/**
 * Options accepted by {@link vaporMoon}. Every field is optional; the
 * defaults match `vapor-moon compile` invocations in this repo's tests.
 */
export interface VaporMoonPluginOptions {
  /**
   * Command used to invoke the Vapor Moon compiler. Defaults to
   * `["moon", "run", "src/cmd/vapor_moon", "--", "compile"]` so the
   * plugin works inside a checkout of this repo. Downstream consumers
   * who install vapor-moon as a binary should set this to
   * `["vapor-moon", "compile"]`.
   */
  command?: readonly string[];

  /**
   * Working directory passed to the compiler. Defaults to Vite's project
   * root.
   */
  cwd?: string;

  /**
   * File extensions to intercept. Anything outside this list is left
   * for other plugins. Defaults to `[".mbtv"]`.
   */
  extensions?: readonly string[];

  /**
   * When `true`, the plugin sets `id` (the .mbtv path) as
   * `import.meta.url` inside the generated module so generated
   * `useTemplateRef` IDs stay stable across HMR reloads. Defaults to
   * `true`.
   */
  preserveModuleUrl?: boolean;
}

const DEFAULT_COMMAND = [
  "moon",
  "run",
  "src/cmd/vapor_moon",
  "--",
  "compile",
] as const;

const DEFAULT_EXTENSIONS = [".mbtv"] as const;

/**
 * Vite+ plugin that registers `.mbtv` as a resolvable module type.
 *
 * Pipeline (Phase 1 — synchronous compile):
 * 1. Vite resolves `import Foo from "./Foo.mbtv"` to this plugin.
 * 2. {@link load} spawns the compiler synchronously and parses the
 *    snapshot output into `{ client_code, server_code, css }`.
 * 3. We emit the client code as the module body and the scoped CSS as
 *    a side-effect via `import "./Foo.mbtv?vmoon-css"`.
 * 4. HMR: any change to the .mbtv source busts Vite's cache; the
 *    next request re-runs the compiler.
 *
 * Phase 2 (tracked separately) will move to an async, batched
 * compiler service so projects with hundreds of .mbtv files don't pay
 * a process-spawn per file.
 */
export function vaporMoon(options: VaporMoonPluginOptions = {}): Plugin {
  const command = options.command ?? DEFAULT_COMMAND;
  const extensions = options.extensions ?? DEFAULT_EXTENSIONS;
  const preserveModuleUrl = options.preserveModuleUrl ?? true;

  let config: ResolvedConfig | null = null;

  const isMbtv = (id: string): boolean =>
    extensions.some((ext) => id.endsWith(ext));

  return {
    name: "vapor-moon",
    enforce: "pre",

    configResolved(resolved) {
      config = resolved;
    },

    resolveId(source, importer) {
      // Pass-through everything that isn't a .mbtv path. The default
      // resolver handles the actual filesystem lookup so we don't need
      // to re-implement extension search.
      if (!isMbtv(source)) {
        return null;
      }
      const base = importer ? dirname(importer) : config?.root ?? process.cwd();
      return resolve(base, source);
    },

    load(id) {
      if (!isMbtv(id)) {
        return null;
      }

      const cwd = options.cwd ?? config?.root ?? process.cwd();
      const output = compileMbtv({ id, command, cwd });

      const css = output.css.trim();
      const styleInjection = css.length > 0
        ? `\n// scoped CSS — Vite picks this up via the css plugin.\nconst __VM_CSS__ = ${JSON.stringify(css)};\nif (typeof document !== "undefined") {\n  const tag = document.createElement("style");\n  tag.setAttribute("data-vm-source", ${JSON.stringify(id)});\n  tag.textContent = __VM_CSS__;\n  document.head.appendChild(tag);\n}\n`
        : "";

      const urlInjection = preserveModuleUrl
        ? `\nimport.meta.url = ${JSON.stringify(`file://${id}`)};\n`
        : "";

      // Phase 1: we emit the client_code verbatim. A future iteration
      // will wrap it in a JS shim that exposes `render_dom` / `render_ssr`
      // as named exports the user can import.
      return {
        code: `${urlInjection}${output.client_code}\n${styleInjection}`,
        map: null,
      };
    },

    handleHotUpdate(ctx) {
      if (!isMbtv(ctx.file)) {
        return;
      }
      // Full module invalidation — the compiler doesn't yet emit a
      // partial update, so any .mbtv change triggers a re-render.
      ctx.server.ws.send({
        type: "custom",
        event: "vapor-moon:reload",
        data: { file: ctx.file },
      });
      return ctx.modules;
    },
  };
}

interface CompilerOutput {
  client_code: string;
  server_code: string;
  css: string;
}

function compileMbtv(
  args: { id: string; command: readonly string[]; cwd: string },
): CompilerOutput {
  const [bin, ...rest] = args.command;
  if (!bin) {
    throw new Error(
      "[@vapor-moon/vite-plugin] options.command must include at least the binary name.",
    );
  }

  const result = spawnSync(bin, [...rest, args.id], {
    cwd: args.cwd,
    encoding: "utf-8",
  });

  if (result.error) {
    throw new Error(
      `[@vapor-moon/vite-plugin] failed to spawn compiler: ${result.error.message}`,
    );
  }
  if (result.status !== 0) {
    const stderr = result.stderr ?? "";
    throw new Error(
      `[@vapor-moon/vite-plugin] compile failed (${result.status}) for ${args.id}\n${stderr}`,
    );
  }

  return parseSnapshot(result.stdout, args.id);
}

/**
 * The CLI prints sections delimited by `=== client ===`, `=== server ===`,
 * `=== css ===`, and `=== meta ===`. Split on those markers so we can
 * route each piece into the right module slot.
 */
export function parseSnapshot(raw: string, sourcePath: string): CompilerOutput {
  const sections: Record<string, string> = {};
  const lines = raw.split(/\r?\n/);
  let current: string | null = null;
  let buffer: string[] = [];

  const flush = () => {
    if (current !== null) {
      sections[current] = buffer.join("\n").trim();
    }
  };

  for (const line of lines) {
    const match = /^===\s*(client|server|css|meta)\s*===/.exec(line);
    if (match) {
      flush();
      current = match[1] ?? null;
      buffer = [];
      continue;
    }
    if (current !== null) {
      buffer.push(line);
    }
  }
  flush();

  const client = sections.client;
  if (!client) {
    throw new Error(
      `[@vapor-moon/vite-plugin] compiler produced no client output for ${sourcePath}.`,
    );
  }
  const css = sections.css ?? "";
  const server = sections.server ?? "";

  return {
    client_code: client,
    server_code: server,
    css: css === "<empty>" ? "" : css,
  };
}

// `__filename` lookalike for ESM hosts that want to know where this
// module is on disk (useful for `vite-plugin-inspect` integration).
export const __pluginRoot = dirname(
  fileURLToPath(import.meta.url ?? "file:///dev/null"),
);

// Re-export a tiny helper so consumers can read this plugin's own
// package.json without bundling a custom parser.
export function readPluginVersion(): string {
  try {
    const pkg = JSON.parse(
      readFileSync(resolve(__pluginRoot, "..", "package.json"), "utf-8"),
    ) as { version?: string };
    return pkg.version ?? "0.0.0";
  } catch {
    return "0.0.0";
  }
}

export default vaporMoon;
