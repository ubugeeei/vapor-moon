///|
fn bench_source_basic() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|}
    #|
    #|let count = signal(0)
    #|</script>
    #|
    #|<template>
    #|  <div class="counter">{{ count.get() }}</div>
    #|</template>
    #|
    #|<style scoped>
    #|.counter { color: red; }
    #|</style>
  source
}

///|
fn bench_source_composable() -> String {
  let source =
    #|<script setup>
    #|import {
    #|  "mizchi/luna/js/resource" @reactivity,
    #|  let signal = @reactivity.signal,
    #|  let computed = @reactivity.computed,
    #|  let watch = @reactivity.watch,
    #|  let effect = @reactivity.effect,
    #|}
    #|
    #|struct CounterComposable {
    #|  count : @reactivity.Signal[Int]
    #|  doubled : () -> Int
    #|  last_change : @reactivity.Signal[String]
    #|}
    #|
    #|fn useCounter(initial : Int) -> CounterComposable {
    #|  let count = signal(initial)
    #|  let doubled = computed(fn() { count.get() * 2 })
    #|  let last_change = signal("ready")
    #|  let doubled_effect = effect(fn() { ignore(doubled()) })
    #|  let change_watch = watch(fn() { count.get() }, fn(next, prev) {
    #|    last_change.set(prev.to_string() + " -> " + next.to_string())
    #|  })
    #|  { count, doubled, last_change }
    #|}
    #|
    #|let counter = useCounter(2)
    #|</script>
    #|
    #|<template>
    #|  <section class="composable">
    #|    <button @click='counter.count.update(fn(n) { n + 1 })'>inc</button>
    #|    <p>{{ counter.count.get() }}</p>
    #|    <p>{{ counter.doubled() }}</p>
    #|    <small>{{ counter.last_change.get() }}</small>
    #|  </section>
    #|</template>
  source
}

// ── Direct compile (no cache, every call recompiles) ───────────

///|
test "bench/direct/basic" (b : @bench.T) {
  let source = bench_source_basic()
  b.bench(fn() {
    let result = @compiler.compile(source, filename="Bench.mbtv") catch {
      _ => panic()
    }
    b.keep(result)
  })
}

///|
test "bench/direct/composable" (b : @bench.T) {
  let source = bench_source_composable()
  b.bench(fn() {
    let result = @compiler.compile(source, filename="Bench.mbtv") catch {
      _ => panic()
    }
    b.keep(result)
  })
}

// ── Incremental compile (cached, 2nd+ call hits cache) ─────────

///|
test "bench/incremental/basic" (b : @bench.T) {
  let ic = IncrementalCompiler::new()
  let source = bench_source_basic()
  ic.set_source("Bench.mbtv", source) |> ignore
  // warm up: first compile populates cache
  let _ = ic.compile("Bench.mbtv") catch { _ => panic() }
  // bench: repeated compile with same source (should hit cache)
  b.bench(fn() {
    let result = ic.compile("Bench.mbtv") catch { _ => panic() }
    b.keep(result)
  })
}

///|
test "bench/incremental/composable" (b : @bench.T) {
  let ic = IncrementalCompiler::new()
  let source = bench_source_composable()
  ic.set_source("Bench.mbtv", source) |> ignore
  let _ = ic.compile("Bench.mbtv") catch { _ => panic() }
  b.bench(fn() {
    let result = ic.compile("Bench.mbtv") catch { _ => panic() }
    b.keep(result)
  })
}
