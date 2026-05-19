import { describe, expect, it } from "vitest";

import { parseSnapshot } from "./index.js";

describe("parseSnapshot", () => {
  it("splits client/server/css/meta sections", () => {
    const raw = [
      "=== client ===",
      "let foo = 1",
      "let bar = 2",
      "=== server ===",
      "let server_foo = 1",
      "=== css ===",
      ".counter { color: red; }",
      "=== meta ===",
      "component=Basic",
    ].join("\n");

    const parsed = parseSnapshot(raw, "examples/basic.mbtv");

    expect(parsed.client_code).toContain("let foo = 1");
    expect(parsed.client_code).toContain("let bar = 2");
    expect(parsed.server_code).toBe("let server_foo = 1");
    expect(parsed.css).toBe(".counter { color: red; }");
  });

  it("treats <empty> css as no css", () => {
    const raw = [
      "=== client ===",
      "x",
      "=== css ===",
      "<empty>",
    ].join("\n");
    expect(parseSnapshot(raw, "x.mbtv").css).toBe("");
  });

  it("throws when client section is missing", () => {
    expect(() =>
      parseSnapshot("=== server ===\nnope\n", "x.mbtv"),
    ).toThrow(/produced no client output/);
  });
});
