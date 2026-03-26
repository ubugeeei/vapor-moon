///|
/// Vapor Moon public facade.

///|
pub using @compiler {
  type BlockAttr,
  type BlockKind,
  type CompileOutput,
  type CompilerError,
  type ForBinding,
  type GenericParam,
  type IslandMode,
  type MacroField,
  type SfcBlock,
  type SfcDocument,
  type ScriptSetupInfo,
  type ScriptSetupTemplateRef,
  type SourceSpan,
  type StyleBlock,
  type TemplateAttr,
  type TemplateAttrKind,
  type TemplateElement,
  type TemplateNode,
  compile,
  new_source_span,
  parse_sfc,
  parse_template,
}

///|
pub using @runtime {
  type HydrationMode,
  type TemplateRef,
  client_module_path,
  make_scope_id,
  props_to_json,
  scope_css,
  show_style,
  use_id,
  use_template_ref,
}

///|
pub using @tooling {
  type ToolingAnalysis,
  type ToolingCompletionItem,
  type ToolingDefinition,
  type ToolingDiagnostic,
  type ToolingHover,
  type ToolingLocation,
  type ToolingPosition,
  type ToolingRange,
  type ToolingSymbol,
  analyze,
  complete_at,
  definition_at,
  diagnostics,
  hover_at,
}
