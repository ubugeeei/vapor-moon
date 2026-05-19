// Entry point — Vite+ resolves the .mbtv import through
// @vapor-moon/vite-plugin, which spawns the compiler and returns the
// generated client module. The compiled output exposes `render_dom`
// from its own MoonBit module surface.

import "./components/Counter.mbtv";

// Mount target is provided by index.html. The .mbtv import above runs
// the generated render_dom function as a side-effect during evaluation
// (it appends into the document body via @dom.into).
const root = document.getElementById("app");
if (root) {
  root.textContent = "Vapor Moon mounted — open the devtools to inspect.";
}
