///|
/// Language-tool oriented analysis for `.mbtv` documents.

///|
/// Symbol surfaced to editors for outline views and quick navigation.
pub struct ToolingSymbol {
  name : String
  kind : String
  span : @compiler.SourceSpan
} derive(Eq, Show)

///|
/// Aggregated semantic summary consumed by CLI tooling and the LSP layer.
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
  expose_binding : String?
  expose : Array[String]
} derive(Eq, Show)

///|
/// Analyzer scoped to one source document.
priv struct ToolingAnalyzer {
  source : String
  filename : String
}

///|
/// Run a best-effort document analysis that never raises parser/compiler errors.
/// Failures are converted into `diagnostics` so editor features can degrade gently.
pub fn analyze(
  source : String,
  filename? : String = "Component.mbtv",
) -> ToolingAnalysis {
  ToolingAnalyzer::new(source, filename).analyze()
}

///|
/// Create an analyzer scoped to one source document.
fn ToolingAnalyzer::new(source : String, filename : String) -> ToolingAnalyzer {
  { source, filename }
}

///|
/// Run a best-effort document analysis that never raises parser/compiler errors.
fn ToolingAnalyzer::analyze(self : ToolingAnalyzer) -> ToolingAnalysis {
  match self.try_analyze() {
    Some(analysis) => analysis
    None => ToolingAnalyzer::failed_analysis("failed to analyze " + self.filename)
  }
}

///|
/// Internal analysis pipeline that preserves partial results when parsing fails.
fn ToolingAnalyzer::try_analyze(self : ToolingAnalyzer) -> ToolingAnalysis? {
  let doc = @compiler.parse_sfc(self.source, filename=self.filename) catch {
    err => return Some(ToolingAnalyzer::failed_analysis(err.to_string()))
  }
  let template = @compiler.parse_template(doc.template) catch {
    err =>
      return Some(
        ToolingAnalyzer::analysis_from_template_error(doc, err.to_string()),
      )
  }
  Some(self.analysis_from_doc(doc, template))
}

///|
/// Default failure payload used when even a partial analysis cannot be produced.
fn ToolingAnalyzer::failed_analysis(
  message : String,
) -> ToolingAnalysis {
  {
    symbols: [],
    expressions: [],
    diagnostics: [message],
    island_components: [],
    extension: ".mbtv",
    props_binding: None,
    props: [],
    emits_binding: None,
    emits: [],
    expose_binding: None,
    expose: [],
  }
}

///|
/// Build the degraded analysis used when template parsing fails after SFC parsing.
fn ToolingAnalyzer::analysis_from_template_error(
  doc : @compiler.SfcDocument,
  message : String,
) -> ToolingAnalysis {
  {
    symbols:
      ToolingAnalyzer::block_symbols(doc.blocks) +
      ToolingAnalyzer::macro_symbols(doc),
    expressions: [],
    diagnostics: [message],
    island_components: [],
    extension: doc.extension,
    props_binding: doc.props_binding,
    props: ToolingAnalyzer::macro_names(doc.props),
    emits_binding: doc.emits_binding,
    emits: ToolingAnalyzer::macro_names(doc.emits),
    expose_binding: doc.expose_binding,
    expose: ToolingAnalyzer::macro_names(doc.expose),
  }
}

///|
/// Build the full semantic summary once both SFC and template parsing succeed.
fn ToolingAnalyzer::analysis_from_doc(
  self : ToolingAnalyzer,
  doc : @compiler.SfcDocument,
  template : Array[@compiler.TemplateNode],
) -> ToolingAnalysis {
  let (expressions, island_components) = self.template_metadata(template)
  {
    symbols:
      ToolingAnalyzer::block_symbols(doc.blocks) +
      ToolingAnalyzer::macro_symbols(doc),
    expressions,
    diagnostics: [],
    island_components,
    extension: doc.extension,
    props_binding: doc.props_binding,
    props: ToolingAnalyzer::macro_names(doc.props),
    emits_binding: doc.emits_binding,
    emits: ToolingAnalyzer::macro_names(doc.emits),
    expose_binding: doc.expose_binding,
    expose: ToolingAnalyzer::macro_names(doc.expose),
  }
}

///|
/// Convert discovered SFC blocks into editor outline symbols.
fn ToolingAnalyzer::block_symbols(
  blocks : Array[@compiler.SfcBlock],
) -> Array[ToolingSymbol] {
  let symbols : Array[ToolingSymbol] = []
  let mut style_index = 1
  for block in blocks {
    let (name, kind) = match block.kind {
      @compiler_common.Template => ("template", "block")
      @compiler_common.ScriptSetup => ("script", "block")
      @compiler_common.ScriptExtern => ("script extern", "block")
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
/// Surface macro bindings such as `defineProps()` as synthetic symbols.
fn ToolingAnalyzer::macro_symbols(
  doc : @compiler.SfcDocument,
) -> Array[ToolingSymbol] {
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
  match doc.expose_binding {
    Some(name) =>
      symbols.push({
        name,
        kind: "macro defineExpose",
        span: @compiler.new_source_span(0, 0),
      })
    None => ()
  }
  symbols
}

///|
/// Extract field names from compiler macro metadata.
fn ToolingAnalyzer::macro_names(
  fields : Array[@compiler.MacroField],
) -> Array[String] {
  let result : Array[String] = []
  for field in fields {
    result.push(field.name)
  }
  result
}

///|
/// Walk the template tree and collect expressions plus hydrated component tags.
fn ToolingAnalyzer::template_metadata(
  self : ToolingAnalyzer,
  template : Array[@compiler.TemplateNode],
) -> (Array[String], Array[String]) {
  let expressions : Array[String] = []
  let island_components : Array[String] = []
  for node in template {
    self.collect_template_metadata(node, expressions, island_components)
  }
  (expressions, island_components)
}

///|
/// Walk one template subtree and collect expressions plus hydrated component tags.
fn ToolingAnalyzer::collect_template_metadata(
  self : ToolingAnalyzer,
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
        self.collect_template_metadata(child, expressions, island_components)
      }
    }
    @compiler_common.Conditional(branches) =>
      for branch in branches {
        match branch.condition {
          Some(expr) => expressions.push(expr)
          None => ()
        }
        self.collect_template_metadata(
          @compiler_common.Element(branch.element),
          expressions,
          island_components,
        )
      }
    @compiler_common.Match(node) =>
      for branch in node.branches {
        self.collect_template_metadata(
          @compiler_common.Element(branch.element),
          expressions,
          island_components,
        )
      }
  }
}
