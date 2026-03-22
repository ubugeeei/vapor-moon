///|
pub using @common {
  type BlockAttr,
  type BlockKind,
  type CompileOutput,
  type CompilerError,
  type ForBinding,
  type GenericParam,
  type IslandMode,
  type MacroField,
  type MacroFieldTypeShape,
  type SfcBlock,
  type SfcDocument,
  type ScriptSetupInfo,
  type SourceSpan,
  type StyleBlock,
  type TemplateAttr,
  type TemplateAttrKind,
  type TemplateElement,
  type TemplateNode,
  new_source_span,
}

///|
pub using @sfc {parse_sfc}

///|
pub using @template {parse_template}

///|
pub using @script_setup {analyze_script_setup}
