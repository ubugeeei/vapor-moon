///|
/// Language-tool oriented analysis for `.mbtv` documents.

///|
pub struct ToolingSymbol {
  name : String
  kind : String
  span : @compiler.SourceSpan
} derive(Eq, Show)

///|
pub struct ToolingAnalysis {
  symbols : Array[ToolingSymbol]
  expressions : Array[String]
  diagnostics : Array[String]
  island_components : Array[String]
  extension : String
  props_binding : String?
  props : Array[String]
  emits_binding : String?
  emits : Array[String]
} derive(Eq, Show)

///|
pub fn analyze(
  source : String,
  filename? : String = "Component.mbtv",
) -> ToolingAnalysis {
  match try_analyze(source, filename) {
    Some(analysis) => analysis
    None =>
      {
        symbols: [],
        expressions: [],
        diagnostics: ["failed to analyze " + filename],
        island_components: [],
        extension: ".mbtv",
        props_binding: None,
        props: [],
        emits_binding: None,
        emits: [],
      }
  }
}

///|
fn try_analyze(source : String, filename : String) -> ToolingAnalysis? {
  let doc = @compiler.parse_sfc(source, filename~) catch {
    err =>
      return Some({
        symbols: [],
        expressions: [],
        diagnostics: [err.to_string()],
        island_components: [],
        extension: ".mbtv",
        props_binding: None,
        props: [],
        emits_binding: None,
        emits: [],
      })
  }
  let template = @compiler.parse_template(doc.template) catch {
    err =>
      return Some({
        symbols: block_symbols(doc.blocks),
        expressions: [],
        diagnostics: [err.to_string()],
        island_components: [],
        extension: doc.extension,
        props_binding: doc.props_binding,
        props: macro_names(doc.props),
        emits_binding: doc.emits_binding,
        emits: macro_names(doc.emits),
      })
  }
  let expressions : Array[String] = []
  let island_components : Array[String] = []
  for node in template {
    collect_template_metadata(node, expressions, island_components)
  }
  Some({
    symbols: block_symbols(doc.blocks) + macro_symbols(doc),
    expressions,
    diagnostics: [],
    island_components,
    extension: doc.extension,
    props_binding: doc.props_binding,
    props: macro_names(doc.props),
    emits_binding: doc.emits_binding,
    emits: macro_names(doc.emits),
  })
}

///|
fn block_symbols(blocks : Array[@compiler.SfcBlock]) -> Array[ToolingSymbol] {
  let symbols : Array[ToolingSymbol] = []
  let mut style_index = 1
  for block in blocks {
    let (name, kind) = match block.kind {
      @compiler_common.Template => ("template", "block")
      @compiler_common.Script => ("script", "block")
      @compiler_common.ScriptSetup => ("script setup", "block")
      @compiler_common.Style => {
        let name = "style " + style_index.to_string()
        style_index += 1
        (name, "block")
      }
    }
    symbols.push({ name, kind, span: block.span })
  }
  symbols
}

///|
fn macro_symbols(doc : @compiler.SfcDocument) -> Array[ToolingSymbol] {
  let symbols : Array[ToolingSymbol] = []
  match doc.props_binding {
    Some(name) =>
      symbols.push({
        name,
        kind: "macro defineProps",
        span: @compiler.new_source_span(0, 0),
      })
    None => ()
  }
  match doc.emits_binding {
    Some(name) =>
      symbols.push({
        name,
        kind: "macro defineEmits",
        span: @compiler.new_source_span(0, 0),
      })
    None => ()
  }
  symbols
}

///|
fn macro_names(fields : Array[@compiler.MacroField]) -> Array[String] {
  let result : Array[String] = []
  for field in fields {
    result.push(field.name)
  }
  result
}

///|
fn collect_template_metadata(
  node : @compiler.TemplateNode,
  expressions : Array[String],
  island_components : Array[String],
) -> Unit {
  match node {
    @compiler_common.Text(_) => ()
    @compiler_common.Interpolation(expr) => expressions.push(expr)
    @compiler_common.Element(element) => {
      match element.if_expr {
        Some(expr) => expressions.push(expr)
        None => ()
      }
      match element.for_binding {
        Some(binding) => expressions.push(binding.source)
        None => ()
      }
      for attr in element.attrs {
        match attr.kind {
          @compiler_common.Dynamic | @compiler_common.Event =>
            expressions.push(attr.value)
          _ => ()
        }
      }
      match element.island_mode {
        @compiler_common.Load
        | @compiler_common.Idle
        | @compiler_common.Visible
        | @compiler_common.Media(_)
        | @compiler_common.Only
        | @compiler_common.ServerDefer => island_components.push(element.tag)
        @compiler_common.None => ()
      }
      for child in element.children {
        collect_template_metadata(child, expressions, island_components)
      }
    }
    @compiler_common.Conditional(branches) =>
      for branch in branches {
        match branch.condition {
          Some(expr) => expressions.push(expr)
          None => ()
        }
        collect_template_metadata(
          @compiler_common.Element(branch.element),
          expressions,
          island_components,
        )
      }
  }
}
