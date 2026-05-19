import { defineConfig } from "vite";
import { vaporMoon } from "@vapor-moon/vite-plugin";

// Smoke-test Vite config that wires the Vapor Moon plugin. The
// `command` override points at the in-repo compiler so this example
// works without a globally installed `vapor-moon` binary.
export default defineConfig({
  root: __dirname,
  plugins: [
    vaporMoon({
      command: [
        "moon",
        "run",
        "src/cmd/vapor_moon",
        "--",
        "compile",
      ],
      // Run the compiler from the repo root so it can find moon.mod.json.
      cwd: new URL("../../", import.meta.url).pathname,
    }),
  ],
  server: {
    port: 5179,
    strictPort: true,
  },
});
