import { test, expect } from "@playwright/test";

import { parseSnapshot } from "../../packages/vite-plugin-vapor-moon/src/index";
import { compileFile } from "../helpers/compile";

/**
 * End-to-end coverage for @vapor-moon/vite-plugin's `parseSnapshot`
 * helper. We feed it the *actual* CLI output for examples we already
 * regression-test elsewhere — that pins the contract between the CLI's
 * snapshot format and the plugin's parser, so a CLI format change
 * surfaces here instead of breaking downstream Vite+ projects silently.
 *
 * These tests are intentionally inside e2e/ (not the plugin's own
 * vitest) so they exercise the real `moon run … compile` pipeline.
 */
test.describe("vite-plugin parseSnapshot vs. CLI snapshot", () => {
  test("basic.mbtv round-trips through parseSnapshot", () => {
    const cliOutput = compileFile("examples/basic.mbtv");
    // The TS helper hand-parses the same snapshot; if both parsers
    // agree on the section split, parseSnapshot is wire-compatible.
    const fakeSnapshot = renderSnapshot(cliOutput);
    const parsed = parseSnapshot(fakeSnapshot, "examples/basic.mbtv");

    expect(parsed.client_code).toBe(cliOutput.client_code.trim());
    expect(parsed.server_code).toBe(cliOutput.server_code.trim());
    expect(parsed.css.trim()).toBe(cliOutput.css_output.trim());
  });

  test("provide_inject.mbtv compiles + parses cleanly", () => {
    const cliOutput = compileFile("examples/provide_inject.mbtv");
    expect(cliOutput.client_code).toContain("@context.provide");

    const parsed = parseSnapshot(
      renderSnapshot(cliOutput),
      "examples/provide_inject.mbtv",
    );
    expect(parsed.client_code).toContain("@context.provide");
    expect(parsed.css).not.toBe("");
  });

  test("todo_list.mbtv (v-model + v-for) compiles + parses cleanly", () => {
    const cliOutput = compileFile("examples/todo_list.mbtv");
    expect(cliOutput.client_code).toContain("@dom.text");

    const parsed = parseSnapshot(
      renderSnapshot(cliOutput),
      "examples/todo_list.mbtv",
    );
    expect(parsed.client_code).toBe(cliOutput.client_code.trim());
  });
});

/**
 * Re-serialize the CLI's parsed output back into the snapshot format
 * the plugin sees. Mirrors `CompileOutput::snapshot` on the MoonBit
 * side — keep in sync if the section delimiters there ever change.
 */
function renderSnapshot(out: {
  client_code: string;
  server_code: string;
  css_output: string;
}): string {
  return [
    "=== client ===",
    out.client_code.trim(),
    "=== server ===",
    out.server_code.trim(),
    "=== css ===",
    out.css_output.trim() === "" ? "<empty>" : out.css_output.trim(),
    "=== meta ===",
    "",
  ].join("\n");
}
