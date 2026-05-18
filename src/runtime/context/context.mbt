///|
/// Provide / inject — Phase 1.
///
/// This module exposes the API surface that the Vue 3-style `provide` /
/// `inject` pattern lowers to. The naming and semantics are designed to
/// match what generated `.client.mbt` code can call directly:
///
/// ```mbt
/// // inside a <script> block:
/// let theme = @context.provide("theme", "dark")
/// let theme = @context.inject("theme")
/// ```
///
/// Scope contract (read carefully)
/// -------------------------------
/// Phase 1 is intentionally **flat / global** within one JS realm. There
/// is exactly one context registry per page; `provide` overwrites the
/// previous value for the same key, and `inject` returns the most
/// recently provided value (or `None`).
///
/// True ancestor scoping — where one component's `provide` is only
/// visible to its descendants and not to siblings — requires:
/// 1. A scope stack with `push_scope` / `pop_scope` lifecycle calls;
/// 2. The compiler wrapping each generated `render_dom` / `render_ssr`
///    body in those calls.
///
/// That work is tracked in
/// <https://github.com/ubugeeei/vapor-moon/issues/14>. The
/// Phase 1 API is shaped so that the Phase 2 swap-in stays
/// backwards-compatible: existing call sites do not change, only the
/// underlying lookup gains scope awareness.
///
/// Until Phase 2 lands, do not rely on `provide` for component-private
/// state. Use it for app-wide singletons (theme, locale, router).

///|
extern "js" fn context_store_set(key : String, value : @js.Any) -> Unit =
  #| (key, value) => {
  #|   const store = (globalThis.__vaporMoonContext ??= new Map());
  #|   store.set(key, value);
  #| }

///|
extern "js" fn context_store_get(key : String) -> @js.Any =
  #| (key) => {
  #|   const store = (globalThis.__vaporMoonContext ??= new Map());
  #|   return store.has(key) ? store.get(key) : undefined;
  #| }

///|
extern "js" fn context_store_has(key : String) -> Bool =
  #| (key) => {
  #|   const store = (globalThis.__vaporMoonContext ??= new Map());
  #|   return store.has(key);
  #| }

///|
extern "js" fn context_store_clear() -> Unit =
  #| () => {
  #|   const store = (globalThis.__vaporMoonContext ??= new Map());
  #|   store.clear();
  #| }

///|
/// Register a value for `key`. The value flows through the JS-side
/// global context map; consumers retrieve it via `inject`.
///
/// Returns the value back unchanged so call sites can write
/// `let theme = provide("theme", "dark")` idiomatically.
pub fn[T] provide(key : String, value : T) -> T {
  context_store_set(key, @js.any(value))
  value
}

///|
/// Look up the value previously provided for `key`, returning `None` if
/// no `provide` has been called for that key in the current realm.
pub fn[T] inject(key : String) -> T? {
  if context_store_has(key) {
    Some(context_store_get(key).cast())
  } else {
    None
  }
}

///|
/// Look up the value for `key`, falling back to `default_value` when no
/// `provide` has been called.
pub fn[T] inject_or(key : String, default_value : T) -> T {
  match inject(key) {
    Some(value) => value
    None => default_value
  }
}

///|
/// Test helper — empty the registry. Production code should not need
/// this; it exists so unit tests can run in isolation.
pub fn reset_for_tests() -> Unit {
  context_store_clear()
}
