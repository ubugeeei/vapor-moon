///|
/// Benchmarks for the SFC compiler pipeline.

// ── Full compile pipeline ──────────────────────────────────────────

///|
test "bench/compile/basic" (b : @bench.T) {
  let source = basic_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/compile/reactivity" (b : @bench.T) {
  let source = reactivity_basics_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/compile/composable" (b : @bench.T) {
  let source = composable_counter_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/compile/directives" (b : @bench.T) {
  let source = directives_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/compile/macros" (b : @bench.T) {
  let source = macros_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/compile/generic" (b : @bench.T) {
  let source = generic_source()
  b.bench(fn() {
    let result = compile(source) catch { _ => panic() }
    b.keep(result)
  })
}

// ── SFC parsing phase ──────────────────────────────────────────────

///|
test "bench/parse_sfc/basic" (b : @bench.T) {
  let source = basic_source()
  b.bench(fn() {
    let result = parse_sfc(source) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/parse_sfc/composable" (b : @bench.T) {
  let source = composable_counter_source()
  b.bench(fn() {
    let result = parse_sfc(source) catch { _ => panic() }
    b.keep(result)
  })
}

// ── Template parsing phase ─────────────────────────────────────────

///|
test "bench/parse_template/basic" (b : @bench.T) {
  let doc = parse_sfc(basic_source()) catch { _ => panic() }
  let template = doc.template
  b.bench(fn() {
    let result = parse_template(template) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/parse_template/directives" (b : @bench.T) {
  let doc = parse_sfc(directives_source()) catch { _ => panic() }
  let template = doc.template
  b.bench(fn() {
    let result = parse_template(template) catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/parse_template/reactivity" (b : @bench.T) {
  let doc = parse_sfc(reactivity_basics_source()) catch { _ => panic() }
  let template = doc.template
  b.bench(fn() {
    let result = parse_template(template) catch { _ => panic() }
    b.keep(result)
  })
}
