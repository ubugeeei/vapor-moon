import { test, expect } from "@playwright/test";
import { compileFile, compileSource } from "../helpers/compile";

test.describe("compiler output structure", () => {
  test("basic.mbtv produces client, server, and css sections", () => {
    const output = compileFile("examples/basic.mbtv");

    expect(output.client_code).toContain("pub fn render_dom()");
    expect(output.client_code).toContain("@dom.el");
    expect(output.server_code).toContain("pub fn render_ssr()");
    expect(output.server_code).toContain("pub fn render_html()");
    expect(output.server_code).toContain("@luna_core.h(");
    expect(output.css_output).toContain(".counter");
    expect(output.css_output).toContain("data-vm-scope");
    expect(output.meta.component).toBe("Basic");
  });

  test("reactivity_basics.mbtv compiles with signal/computed/watch", () => {
    const output = compileFile("examples/reactivity_basics.mbtv");

    expect(output.client_code).toContain("render_dom");
    expect(output.client_code).toContain("@reactivity");
    expect(output.server_code).toContain("render_ssr");
    expect(output.meta.component).toBe("ReactivityBasics");
  });

  test("directives.mbtv compiles with v-if and v-for", () => {
    const output = compileFile("examples/directives.mbtv");

    expect(output.client_code).toContain("@dom.show(");
    expect(output.client_code).toContain("@dom.each(");
    expect(output.server_code).toContain("@luna_core.show(");
    expect(output.server_code).toContain("@luna_core.for_each(");
  });

  test("composable_counter.mbtv compiles with struct and fn", () => {
    const output = compileFile("examples/composable_counter.mbtv");

    expect(output.client_code).toContain("render_dom");
    expect(output.server_code).toContain("render_ssr");
    expect(output.meta.component).toBe("ComposableCounter");
  });
});

test.describe("compiler output correctness", () => {
  test("scoped style applies scope id to CSS selectors", () => {
    const output = compileFile("examples/basic.mbtv");
    const scopeId = output.meta.scope;

    expect(scopeId).toBeTruthy();
    expect(output.css_output).toContain(`[data-vm-scope="${scopeId}"]`);
    expect(output.client_code).toContain(`data-vm-scope`);
    expect(output.client_code).toContain(scopeId!);
  });

  test("no style block produces empty css", () => {
    const output = compileSource(
      `<script setup>
let x = 1
</script>

<template>
  <div>{{ x.to_string() }}</div>
</template>`,
      "NoStyle.mbtv"
    );

    expect(output.css_output).toBe("");
    expect(output.meta.scope).toBe("<none>");
  });

  test("component metadata is generated", () => {
    const output = compileFile("examples/basic.mbtv");

    expect(output.client_code).toContain("pub fn declared_props()");
    expect(output.client_code).toContain("pub fn declared_emits()");
    expect(output.client_code).toContain("pub fn declared_slots()");
    expect(output.client_code).toContain('pub let component_name : String = "Basic"');
  });

  test("props/emits macros generate contract metadata", () => {
    const output = compileFile("examples/macros.mbtv");

    expect(output.meta.props).toBeTruthy();
    expect(output.meta.props).not.toBe("<none>");
    expect(output.meta.emits).toBeTruthy();
    expect(output.meta.emits).not.toBe("<none>");
  });
});

test.describe("SSR HTML in browser", () => {
  test("server code contains correct element structure for basic", () => {
    const output = compileFile("examples/basic.mbtv");

    // Server code should generate h("div", ...) with class="counter"
    expect(output.server_code).toContain('@luna_core.h("div"');
    expect(output.server_code).toContain('"class"');
    expect(output.server_code).toContain('"counter"');
  });

  test("server code for directives has conditional and list rendering", () => {
    const output = compileFile("examples/directives.mbtv");

    expect(output.server_code).toContain("@luna_core.show(");
    expect(output.server_code).toContain("@luna_core.for_each(");
    expect(output.server_code).toContain('@luna_core.h("ul"');
    expect(output.server_code).toContain('@luna_core.h("li"');
  });

  test("v-if/v-else generates conditional in server code", () => {
    const output = compileSource(
      `<script setup>
let active = true
</script>

<template>
  <p v-if='active'>yes</p>
  <p v-else>no</p>
</template>`,
      "Conditional.mbtv"
    );

    expect(output.server_code).toContain("if active {");
    expect(output.server_code).toContain("} else {");
    expect(output.server_code).toContain('@luna_core.text("yes")');
    expect(output.server_code).toContain('@luna_core.text("no")');
  });
});

test.describe("compiler error handling", () => {
  test("missing template block produces error in output", () => {
    const output = compileSource("<div>no template</div>", "Bad.mbtv");
    // When compilation fails, client_code will be empty and no render_dom
    expect(output.client_code).not.toContain("pub fn render_dom()");
  });

  test("duplicate template block produces error in output", () => {
    const output = compileSource(
      `<template><div>a</div></template><template><div>b</div></template>`,
      "Dup.mbtv"
    );
    expect(output.client_code).not.toContain("pub fn render_dom()");
  });
});
