///|
fn macro_completion_items(prefix : String) -> Array[ToolingCompletionItem] {
  let entries = [
    ("defineProps", "macro", "declare typed props"),
    ("defineEmits", "macro", "declare typed emits"),
    ("defineSlot", "macro", "declare typed slots"),
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
  let entries = ["v-if", "v-for", "v-show", "v-html", "v-model", "v-once"]
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry,
      kind: "directive",
      detail: "template directive",
      insert_text: entry,
    })
  }
  items
}

///|
fn island_completion_items(
  prefix : String,
  kind : String,
  entries : Array[String],
) -> Array[ToolingCompletionItem] {
  let items : Array[ToolingCompletionItem] = []
  for entry in entries {
    if not(entry.has_prefix(prefix)) {
      continue
    }
    items.push({
      label: entry,
      kind,
      detail: "island directive",
      insert_text: entry,
    })
  }
  items
}
