import { test, expect } from "@playwright/test";
import { compileFile, compileSource } from "../helpers/compile";

test.describe("generic components", () => {
  test("generic_list.mbtv compiles with type parameters", () => {
    const output = compileFile("examples/generic_list.mbtv");

    expect(output.meta.component).toBe("GenericList");
    // generic parameters in render signature
    expect(output.client_code).toContain("[T, U : Show]");
    expect(output.server_code).toContain("[T, U : Show]");
    // props/emits/slots all declared
    expect(output.meta.props).not.toBe("<none>");
    expect(output.meta.emits).not.toBe("<none>");
    expect(output.meta.slots).not.toBe("<none>");
  });

  test("generic props generates typed contract", () => {
    const output = compileFile("examples/generic_list.mbtv");

    expect(output.client_code).toContain("GenericListProps");
    expect(output.client_code).toContain("items");
    expect(output.client_code).toContain("selected");
  });

  test("generic emits generates typed contract", () => {
    const output = compileFile("examples/generic_list.mbtv");

    expect(output.client_code).toContain("GenericListEmits");
    expect(output.client_code).toContain("choose");
  });
});

test.describe("island directives", () => {
  test("island_visible.mbtv compiles with client:visible", () => {
    const output = compileFile("examples/island_visible.mbtv");

    expect(output.meta.component).toBe("IslandVisible");
    expect(output.meta.islands).toContain("CounterPanel");
    expect(output.client_code).toContain("island_dom");
    expect(output.server_code).toContain("island_ssr");
  });

  test("media_and_defer.mbtv compiles with client:media and server:defer", () => {
    const output = compileFile("examples/media_and_defer.mbtv");

    expect(output.meta.component).toBe("MediaAndDefer");
    expect(output.meta.islands).toContain("HeroBanner");
    expect(output.meta.islands).toContain("ArticleChunk");
    // client:media generates media query island
    expect(output.client_code).toContain("island_dom");
    expect(output.client_code).toContain("max-width: 768px");
    // server:defer generates defer island
    expect(output.server_code).toContain("island_ssr");
  });
});

test.describe("lifecycle and template refs", () => {
  test("lifecycle_refs.mbtv compiles with useTemplateRef and useId", () => {
    const output = compileFile("examples/lifecycle_refs.mbtv");

    expect(output.meta.component).toBe("LifecycleRefs");
    // useTemplateRef is lowered to runtime call
    expect(output.client_code).toContain("@vm.use_template_ref");
    expect(output.server_code).toContain("@vm.use_template_ref");
    // useId is lowered to runtime call
    expect(output.client_code).toContain("@vm.use_id");
    expect(output.server_code).toContain("@vm.use_id");
    // ref attribute generates ref binding
    expect(output.client_code).toContain("ref");
  });
});

test.describe("props with defaults", () => {
  test("props_defaults.mbtv compiles with default values", () => {
    const output = compileFile("examples/props_defaults.mbtv");

    expect(output.meta.component).toBe("PropsDefaults");
    expect(output.meta.props).toContain("title");
    expect(output.meta.props).toContain("count");
    expect(output.meta.props).toContain("tone");
    // defaults are applied in the render function
    expect(output.client_code).toContain("unwrap_or");
    expect(output.server_code).toContain("unwrap_or");
  });

  test("props defaults use correct fallback values", () => {
    const output = compileFile("examples/props_defaults.mbtv");

    expect(output.client_code).toContain("unwrap_or(0)");
    expect(output.client_code).toContain('unwrap_or("primary")');
  });
});

test.describe("slots", () => {
  test("slots.mbtv compiles with defineSlot contract", () => {
    const output = compileFile("examples/slots.mbtv");

    expect(output.meta.component).toBe("Slots");
    expect(output.meta.slots).toContain("default");
    expect(output.meta.slots).toContain("footer");
    expect(output.client_code).toContain("DomSlots");
    expect(output.server_code).toContain("SsrSlots");
  });
});

test.describe("v-else / v-else-if", () => {
  test("v-if v-else generates if/else in client code", () => {
    const output = compileSource(
      `<script setup>
let show = true
</script>

<template>
  <div v-if='show'>visible</div>
  <div v-else>fallback</div>
</template>`,
      "IfElse.mbtv"
    );

    expect(output.client_code).toContain("if show {");
    expect(output.client_code).toContain("} else {");
  });

  test("v-if v-else-if v-else generates full chain", () => {
    const output = compileSource(
      `<script setup>
let n = 0
</script>

<template>
  <span v-if='n > 0'>pos</span>
  <span v-else-if='n == 0'>zero</span>
  <span v-else>neg</span>
</template>`,
      "Chain.mbtv"
    );

    expect(output.client_code).toContain("if n > 0 {");
    expect(output.client_code).toContain("} else if n == 0 {");
    expect(output.client_code).toContain("} else {");
    expect(output.server_code).toContain("if n > 0 {");
    expect(output.server_code).toContain("} else if n == 0 {");
    expect(output.server_code).toContain("} else {");
  });

  test("v-if v-else-if without v-else compiles", () => {
    const output = compileSource(
      `<script setup>
let x = "a"
</script>

<template>
  <p v-if='x == "a"'>alpha</p>
  <p v-else-if='x == "b"'>beta</p>
</template>`,
      "NoElse.mbtv"
    );

    expect(output.client_code).toContain('if x == "a" {');
    expect(output.client_code).toContain('} else if x == "b" {');
    expect(output.client_code).not.toContain("} else {");
  });
});

test.describe("v-show directive", () => {
  test("v-show generates show wrapper", () => {
    const output = compileSource(
      `<script setup>
let visible = true
</script>

<template>
  <div v-show='visible'>content</div>
</template>`,
      "VShow.mbtv"
    );

    expect(output.client_code).toContain("@vm_dom.attr_dynamic_style");
    expect(output.client_code).toContain("@vm.show_style");
    expect(output.server_code).toContain("@vm.show_style");
  });
});

test.describe("v-unsafe-html directive", () => {
  test("v-unsafe-html generates raw html rendering", () => {
    const output = compileSource(
      `<script setup>
let html_content = "<b>bold</b>"
</script>

<template>
  <div v-unsafe-html='html_content'></div>
</template>`,
      "VUnsafeHtml.mbtv"
    );

    expect(output.server_code).toContain("raw_html");
  });
});

test.describe("v-once directive", () => {
  test("v-once generates static rendering", () => {
    const output = compileSource(
      `<script setup>
let msg = "hello"
</script>

<template>
  <div v-once>{{ msg }}</div>
</template>`,
      "VOnce.mbtv"
    );

    // v-once should use static text instead of reactive text_expr
    expect(output.client_code).toContain("@vm_dom.text(msg");
    expect(output.client_code).not.toContain("text_expr");
  });
});

test.describe("template ref and key", () => {
  test("ref attribute generates ref binding", () => {
    const output = compileSource(
      `<template>
  <div ref='myRef'>content</div>
</template>`,
      "Ref.mbtv"
    );

    expect(output.client_code).toContain("ref");
    expect(output.client_code).toContain("myRef");
  });

  test("dynamic :key generates key attribute", () => {
    const output = compileSource(
      `<script setup>
let items = [1, 2, 3]
</script>

<template>
  <ul>
    <li v-for='(item, i) in items' :key='i'>{{ item.to_string() }}</li>
  </ul>
</template>`,
      "Key.mbtv"
    );

    expect(output.client_code).toContain("for_each");
  });
});

test.describe("class and style merging", () => {
  test("static and dynamic class attributes merge", () => {
    const output = compileSource(
      `<script setup>
let accent = "highlight"
</script>

<template>
  <div class="base" :class='accent'>text</div>
</template>`,
      "ClassMerge.mbtv"
    );

    expect(output.client_code).toContain("merge_class_names");
    expect(output.client_code).toContain("base");
  });
});

test.describe("v-match / v-case pattern matching", () => {
  test("v-match with string literals generates match expression", () => {
    const output = compileSource(
      `<script setup>
let status = "loading"
</script>

<template>
  <div v-match='status'>
    <p v-case='"loading"'>Loading...</p>
    <p v-case='"error"'>Error!</p>
    <p v-default>Unknown</p>
  </div>
</template>`,
      "MatchStr.mbtv"
    );

    expect(output.client_code).toContain("match status {");
    expect(output.client_code).toContain('"loading" =>');
    expect(output.client_code).toContain('"error" =>');
    expect(output.client_code).toContain("_ =>");
    expect(output.server_code).toContain("match status {");
  });

  test("v-match with enum patterns generates match with binding", () => {
    const output = compileSource(
      `<script setup>
let result = Ok("data")
</script>

<template>
  <div v-match='result'>
    <p v-case='Ok(data)'>{{ data }}</p>
    <p v-case='Err(msg)'>{{ msg }}</p>
  </div>
</template>`,
      "MatchEnum.mbtv"
    );

    expect(output.client_code).toContain("match result {");
    expect(output.client_code).toContain("Ok(data) =>");
    expect(output.client_code).toContain("Err(msg) =>");
    expect(output.server_code).toContain("match result {");
    expect(output.server_code).toContain("Ok(data) =>");
  });

  test("v-match with wildcard underscore pattern", () => {
    const output = compileSource(
      `<script setup>
let mode = "dark"
</script>

<template>
  <div v-match='mode'>
    <p v-case='"dark"'>Dark</p>
    <p v-case='_'>Default</p>
  </div>
</template>`,
      "MatchWild.mbtv"
    );

    expect(output.client_code).toContain("match mode {");
    expect(output.client_code).toContain("_ =>");
  });

  test("v-case outside v-match produces error", () => {
    const output = compileSource(
      `<template>
  <div v-case='"x"'>text</div>
</template>`,
      "CaseNoMatch.mbtv"
    );

    expect(output.client_code).not.toContain("render_dom(");
  });

  test("v-match with no v-case children produces error", () => {
    const output = compileSource(
      `<template>
  <div v-match='x'>
    <p>no case here</p>
  </div>
</template>`,
      "MatchNoCases.mbtv"
    );

    expect(output.client_code).not.toContain("render_dom(");
  });
});

test.describe("v-slot / #name slot outlets", () => {
  test("named slots generate slots record literal", () => {
    const output = compileSource(
      `<template>
  <MyLayout>
    <template #header><h1>Title</h1></template>
    <template #footer><p>Footer</p></template>
    <p>Default</p>
  </MyLayout>
</template>`,
      "NamedSlots.mbtv"
    );

    // Client should have record literal with slot names
    expect(output.client_code).toContain("header: Some(fn()");
    expect(output.client_code).toContain("footer: Some(fn()");
    expect(output.client_code).toContain("default: Some(fn()");
    // Server same structure
    expect(output.server_code).toContain("header: Some(fn()");
    expect(output.server_code).toContain("footer: Some(fn()");
  });

  test("default-only children use array (no record)", () => {
    const output = compileSource(
      `<template>
  <MyCard><p>Content</p></MyCard>
</template>`,
      "DefaultOnly.mbtv"
    );

    // Should use flat array, not record
    expect(output.client_code).not.toContain("Some(fn()");
    expect(output.client_code).toContain("component_dom");
  });

  test("v-slot:name full syntax works", () => {
    const output = compileSource(
      `<template>
  <MyDialog>
    <template v-slot:body><p>Body</p></template>
    <template v-slot:actions><button>OK</button></template>
  </MyDialog>
</template>`,
      "VSlotFull.mbtv"
    );

    expect(output.client_code).toContain("body: Some(fn()");
    expect(output.client_code).toContain("actions: Some(fn()");
  });

  test("slots.mbtv example compiles with slot contract", () => {
    const output = compileFile("examples/slots.mbtv");

    expect(output.meta.slots).toContain("default");
    expect(output.meta.slots).toContain("footer");
    expect(output.client_code).toContain("DomSlots");
    expect(output.server_code).toContain("SsrSlots");
  });
});

test.describe("all examples compile without error", () => {
  const examples = [
    "basic",
    "composable_counter",
    "directives",
    "generic_list",
    "island_visible",
    "lifecycle_refs",
    "macros",
    "media_and_defer",
    "props_defaults",
    "reactivity_basics",
    "slots",
  ];

  for (const name of examples) {
    test(`${name}.mbtv compiles successfully`, () => {
      const output = compileFile(`examples/${name}.mbtv`);
      expect(output.client_code).toContain("render_dom(");
      expect(output.server_code).toContain("render_ssr(");
    });
  }
});
