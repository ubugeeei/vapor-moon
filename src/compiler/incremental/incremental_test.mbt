///|
fn basic_source() -> String {
  let source =
    #|<script setup>
    #|let count = 0
    #|</script>
    #|
    #|<template>
    #|  <div>{{ count.to_string() }}</div>
    #|</template>
  source
}

///|
fn basic_source_v2() -> String {
  let source =
    #|<script setup>
    #|let count = 1
    #|</script>
    #|
    #|<template>
    #|  <div>{{ count.to_string() }}</div>
    #|</template>
  source
}

///|
fn scoped_style_source() -> String {
  let source =
    #|<script setup>
    #|let x = 0
    #|</script>
    #|
    #|<template>
    #|  <div class="box">{{ x.to_string() }}</div>
    #|</template>
    #|
    #|<style scoped>
    #|.box { color: red; }
    #|</style>
  source
}

///|
test "incremental compile matches direct compile" {
  let ic = IncrementalCompiler::new()
  let source = basic_source()
  let filename = "Test.mbtv"
  ic.set_source(filename, source) |> ignore
  let inc_output = ic.compile(filename) catch { _ => panic() }
  let direct_output = @compiler.compile(source, filename~) catch {
    _ => panic()
  }
  assert_eq(inc_output, direct_output)
}

///|
test "second compile with same source uses cache" {
  let ic = IncrementalCompiler::new()
  let source = basic_source()
  let filename = "Cache.mbtv"
  ic.set_source(filename, source) |> ignore
  let _ = ic.compile(filename) catch { _ => panic() }
  let rev_after_first = ic.revision()
  // set same source again
  let changed = ic.set_source(filename, source)
  assert_false(changed)
  let _ = ic.compile(filename) catch { _ => panic() }
  let rev_after_second = ic.revision()
  // revision should not have changed
  assert_eq(rev_after_first, rev_after_second)
}

///|
test "changing source invalidates cache" {
  let ic = IncrementalCompiler::new()
  let filename = "Change.mbtv"
  ic.set_source(filename, basic_source()) |> ignore
  let output1 = ic.compile(filename) catch { _ => panic() }
  let changed = ic.set_source(filename, basic_source_v2())
  assert_true(changed)
  let output2 = ic.compile(filename) catch { _ => panic() }
  assert_true(output1 != output2)
}

///|
test "reverting source reuses cached result via backdate" {
  let ic = IncrementalCompiler::new()
  let filename = "Revert.mbtv"
  ic.set_source(filename, basic_source()) |> ignore
  let output1 = ic.compile(filename) catch { _ => panic() }
  // change
  ic.set_source(filename, basic_source_v2()) |> ignore
  let _ = ic.compile(filename) catch { _ => panic() }
  // revert
  ic.set_source(filename, basic_source()) |> ignore
  let output3 = ic.compile(filename) catch { _ => panic() }
  assert_eq(output1, output3)
}

///|
test "multiple files are independently cached" {
  let ic = IncrementalCompiler::new()
  ic.set_source("A.mbtv", basic_source()) |> ignore
  ic.set_source("B.mbtv", basic_source_v2()) |> ignore
  let out_a = ic.compile("A.mbtv") catch { _ => panic() }
  let out_b = ic.compile("B.mbtv") catch { _ => panic() }
  assert_true(out_a.component_name != out_b.component_name)
  // change only A
  ic.set_source("A.mbtv", basic_source_v2()) |> ignore
  let out_a2 = ic.compile("A.mbtv") catch { _ => panic() }
  let out_b2 = ic.compile("B.mbtv") catch { _ => panic() }
  assert_true(out_a != out_a2)
  assert_eq(out_b, out_b2)
}

///|
test "error results are returned correctly" {
  let ic = IncrementalCompiler::new()
  ic.set_source("Bad.mbtv", "<div>no template block</div>") |> ignore
  let result = Ok(ic.compile("Bad.mbtv")) catch { err => Err(err) }
  assert_true(result is Err(_))
}

///|
test "get_sfc returns parsed document" {
  let ic = IncrementalCompiler::new()
  ic.set_source("Sfc.mbtv", basic_source()) |> ignore
  let doc = ic.get_sfc("Sfc.mbtv") catch { _ => panic() }
  assert_true(doc.template.length() > 0)
}

///|
test "get_template returns parsed nodes" {
  let ic = IncrementalCompiler::new()
  ic.set_source("Tpl.mbtv", basic_source()) |> ignore
  let nodes = ic.get_template("Tpl.mbtv") catch { _ => panic() }
  assert_true(nodes.length() > 0)
}

///|
test "get_css returns css output" {
  let ic = IncrementalCompiler::new()
  ic.set_source("Style.mbtv", scoped_style_source()) |> ignore
  let css = ic.get_css("Style.mbtv") catch { _ => panic() }
  assert_true(css.length() > 0)
  assert_true(css.contains("data-vm-scope"))
}

///|
test "file not found raises error" {
  let ic = IncrementalCompiler::new()
  let result = Ok(ic.compile("NotFound.mbtv")) catch { err => Err(err) }
  assert_true(result is Err(_))
}
