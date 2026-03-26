///|
/// Fixture tests for incremental compilation behavior.
/// Verifies that partial changes only recompute affected queries.

// ── Fixtures ───────────────────────────────────────────────────

///|
fn fixture_full() -> String {
  let source =
    #|<script setup>
    #|let msg = "hello"
    #|</script>
    #|
    #|<template>
    #|  <p class="greeting">{{ msg }}</p>
    #|</template>
    #|
    #|<style scoped>
    #|.greeting { color: blue; }
    #|</style>
  source
}

///|
fn fixture_template_changed() -> String {
  let source =
    #|<script setup>
    #|let msg = "hello"
    #|</script>
    #|
    #|<template>
    #|  <span class="greeting">{{ msg }}</span>
    #|</template>
    #|
    #|<style scoped>
    #|.greeting { color: blue; }
    #|</style>
  source
}

///|
fn fixture_style_changed() -> String {
  let source =
    #|<script setup>
    #|let msg = "hello"
    #|</script>
    #|
    #|<template>
    #|  <p class="greeting">{{ msg }}</p>
    #|</template>
    #|
    #|<style scoped>
    #|.greeting { color: red; }
    #|</style>
  source
}

///|
fn fixture_script_changed() -> String {
  let source =
    #|<script setup>
    #|let msg = "world"
    #|</script>
    #|
    #|<template>
    #|  <p class="greeting">{{ msg }}</p>
    #|</template>
    #|
    #|<style scoped>
    #|.greeting { color: blue; }
    #|</style>
  source
}

///|
fn fixture_whitespace_only_change() -> String {
  let source =
    #|<script setup>
    #|let msg = "hello"
    #|</script>
    #|
    #|
    #|<template>
    #|  <p class="greeting">{{ msg }}</p>
    #|</template>
    #|
    #|<style scoped>
    #|.greeting { color: blue; }
    #|</style>
  source
}

///|
fn fixture_broken() -> String {
  "<div>not a valid SFC</div>"
}

///|
fn fixture_no_style() -> String {
  let source =
    #|<script setup>
    #|let x = 1
    #|</script>
    #|
    #|<template>
    #|  <div>{{ x.to_string() }}</div>
    #|</template>
  source
}

// ── Template-only change ───────────────────────────────────────

///|
test "template change: css stays the same" {
  let ic = IncrementalCompiler::new()
  let f = "Tpl.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let css1 = ic.get_css(f) catch { _ => panic() }
  let out1 = ic.compile(f) catch { _ => panic() }
  // change only the template tag: <p> → <span>
  ic.set_source(f, fixture_template_changed()) |> ignore
  let css2 = ic.get_css(f) catch { _ => panic() }
  let out2 = ic.compile(f) catch { _ => panic() }
  // css should be identical
  assert_eq(css1, css2)
  // but client/server code should differ (different tag)
  assert_true(out1.client_code != out2.client_code)
  assert_true(out1.server_code != out2.server_code)
}

// ── Style-only change ──────────────────────────────────────────

///|
test "style change: client and server code stay the same" {
  let ic = IncrementalCompiler::new()
  let f = "Style.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let out1 = ic.compile(f) catch { _ => panic() }
  let css1 = ic.get_css(f) catch { _ => panic() }
  // change only the style: color: blue → red
  ic.set_source(f, fixture_style_changed()) |> ignore
  let out2 = ic.compile(f) catch { _ => panic() }
  let css2 = ic.get_css(f) catch { _ => panic() }
  // css should differ
  assert_true(css1 != css2)
  assert_true(css2.contains("red"))
  // client and server code should be identical (same template, same script)
  assert_eq(out1.client_code, out2.client_code)
  assert_eq(out1.server_code, out2.server_code)
}

// ── Script-only change ─────────────────────────────────────────

///|
test "script change: template nodes stay the same" {
  let ic = IncrementalCompiler::new()
  let f = "Script.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let tpl1 = ic.get_template(f) catch { _ => panic() }
  let css1 = ic.get_css(f) catch { _ => panic() }
  // change only the script: msg = "hello" → "world"
  ic.set_source(f, fixture_script_changed()) |> ignore
  let tpl2 = ic.get_template(f) catch { _ => panic() }
  let css2 = ic.get_css(f) catch { _ => panic() }
  // template AST should be identical (same template block)
  assert_eq(tpl1, tpl2)
  // css should be identical (same style block)
  assert_eq(css1, css2)
}

// ── Whitespace-only change ─────────────────────────────────────

///|
test "whitespace-only change: source differs but output matches" {
  let ic = IncrementalCompiler::new()
  let f = "Ws.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let out1 = ic.compile(f) catch { _ => panic() }
  // add an extra blank line between blocks
  let changed = ic.set_source(f, fixture_whitespace_only_change())
  assert_true(changed) // source string is different
  let out2 = ic.compile(f) catch { _ => panic() }
  // output should be identical because the parsed blocks are the same
  assert_eq(out1, out2)
}

// ── Error recovery ─────────────────────────────────────────────

///|
test "error then fix: recovers and compiles successfully" {
  let ic = IncrementalCompiler::new()
  let f = "Recover.mbtv"
  // set broken source
  ic.set_source(f, fixture_broken()) |> ignore
  let err_result = try { Ok(ic.compile(f)) } catch { e => Err(e) }
  assert_true(err_result is Err(_))
  // fix the source
  ic.set_source(f, fixture_full()) |> ignore
  let ok_result = try { Ok(ic.compile(f)) } catch { e => Err(e) }
  assert_true(ok_result is Ok(_))
}

// ── compile_from_parts consistency ─────────────────────────────

///|
test "compile_from_parts matches compile for all fixtures" {
  let fixtures = [
    ("Full.mbtv", fixture_full()),
    ("NoStyle.mbtv", fixture_no_style()),
    ("ScriptChanged.mbtv", fixture_script_changed()),
  ]
  for pair in fixtures {
    let filename = pair.0
    let source = pair.1
    let direct = @compiler.compile(source, filename~) catch { _ => panic() }
    let doc = @compiler.parse_sfc(source, filename~) catch { _ => panic() }
    let tpl = @compiler.parse_template(doc.template) catch { _ => panic() }
    let from_parts = @compiler.compile_from_parts(doc, tpl, filename) catch {
      _ => panic()
    }
    assert_eq(direct, from_parts)
  }
}

// ── Intermediate queries work independently ────────────────────

///|
test "get_css works without calling compile" {
  let ic = IncrementalCompiler::new()
  let f = "CssOnly.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  // call get_css without ever calling compile
  let css = ic.get_css(f) catch { _ => panic() }
  assert_true(css.contains("greeting"))
  assert_true(css.contains("data-vm-scope"))
}

///|
test "get_template works without calling compile" {
  let ic = IncrementalCompiler::new()
  let f = "TplOnly.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let nodes = ic.get_template(f) catch { _ => panic() }
  assert_true(nodes.length() > 0)
}

///|
test "get_sfc works without calling compile" {
  let ic = IncrementalCompiler::new()
  let f = "SfcOnly.mbtv"
  ic.set_source(f, fixture_full()) |> ignore
  let doc = ic.get_sfc(f) catch { _ => panic() }
  assert_true(doc.template.contains("greeting"))
  assert_true(doc.script_setup is Some(_))
  assert_true(doc.styles.length() > 0)
}

// ── No style: css query returns empty ──────────────────────────

///|
test "no style block: get_css returns empty string" {
  let ic = IncrementalCompiler::new()
  let f = "NoStyle.mbtv"
  ic.set_source(f, fixture_no_style()) |> ignore
  let css = ic.get_css(f) catch { _ => panic() }
  assert_eq(css, "")
}
