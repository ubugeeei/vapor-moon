///|
fn macro_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    ("defineProps", "macro", "declare typed props"),
    ("defineEmits", "macro", "declare typed emits"),
    ("defineSlots", "macro", "declare typed slots"),
    ("useId", "macro", "generate stable ids"),
    ("useTemplateRef", "macro", "create a template ref"),
  ]
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if prefix.length() > 0 && not(entry.0.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry.0,
      kind: entry.1,
      detail: entry.2,
      insert_text: entry.0,
    })
  }
  items
}

///|
fn directive_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    ("v-if", "conditional rendering"),
    ("v-else-if", "conditional branch (requires preceding v-if)"),
    ("v-else", "fallback branch (requires preceding v-if or v-else-if)"),
    ("v-for", "list rendering"),
    ("v-show", "toggle visibility via CSS display"),
    ("v-html", "render raw HTML content"),
    ("v-model", "two-way binding on form elements"),
    ("v-once", "render once (skip reactivity)"),
    ("v-match", "pattern matching on an expression"),
    ("v-case", "match branch pattern (inside v-match)"),
    ("v-default", "default match branch (inside v-match)"),
  ]
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.0.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry.0,
      kind: "directive",
      detail: entry.1,
      insert_text: entry.0,
    })
  }
  items
}

///|
fn event_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    "@click", "@input", "@change", "@submit", "@keydown", "@keyup", "@focus", "@blur",
  ]
  prefixed_completion_items(prefix, entries, "event", "event handler")
}

///|
fn long_event_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    "v-on:click", "v-on:input", "v-on:change", "v-on:submit", "v-on:keydown", "v-on:keyup",
    "v-on:focus", "v-on:blur",
  ]
  prefixed_completion_items(prefix, entries, "event", "event handler")
}

///|
fn binding_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    ":class", ":style", ":key", ":ref", ":value", ":checked", ":disabled",
  ]
  prefixed_completion_items(prefix, entries, "binding", "dynamic attribute")
}

///|
fn long_binding_completion_items(
  prefix : String,
) -> Array[ToolingCompletionItem] {
  let entries = [
    "v-bind:class", "v-bind:style", "v-bind:key", "v-bind:ref", "v-bind:value", "v-bind:checked",
    "v-bind:disabled",
  ]
  prefixed_completion_items(prefix, entries, "binding", "dynamic attribute")
}

///|
fn island_completion_items(
  prefix : String,
  kind : String,
  entries : Array[String],
) -> Array[ToolingCompletionItem] {
  prefixed_completion_items(prefix, entries, kind, "island directive")
}

///|
fn prefixed_completion_items(
  prefix : String,
  entries : Array[String],
  kind : String,
  detail : String,
) -> Array[ToolingCompletionItem] {
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.has_prefix(prefix)) {
      continue
    }
    items.push({ label: entry, kind, detail, insert_text: entry })
  }
  items
}
