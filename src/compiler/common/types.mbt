///|
/// Shared compiler and template AST types.

///|
pub(all) struct SourceSpan {
  start : Int
  end : Int
} derive(Eq, Show)

///|
pub fn new_source_span(start : Int, end_ : Int) -> SourceSpan {
  { start, end: end_ }
}

///|
pub(all) enum BlockKind {
  Template
  Script
  ScriptSetup
  Style
} derive(Eq, Show)

///|
pub(all) struct BlockAttr {
  name : String
  value : String?
} derive(Eq, Show)

///|
pub(all) struct SfcBlock {
  kind : BlockKind
  attrs : Array[BlockAttr]
  content : String
  span : SourceSpan
} derive(Eq, Show)

///|
pub(all) struct StyleBlock {
  attrs : Array[BlockAttr]
  content : String
  scoped : Bool
  span : SourceSpan
} derive(Eq, Show)

///|
pub(all) struct MacroField {
  name : String
  signature : String?
  type_identifiers : Array[String]
  type_shape : MacroFieldTypeShape
  is_optional : Bool
} derive(Eq, Show)

///|
pub(all) enum MacroFieldTypeShape {
  UnitLike
  SingleValue
  TupleValues(Int)
} derive(Eq, Show)

///|
pub(all) struct PropDefault {
  name : String
  expr : String
} derive(Eq, Show)

///|
pub(all) struct GenericParam {
  name : String
  declaration : String
} derive(Eq, Show)

///|
pub(all) struct ScriptSetupInfo {
  source : String
  transformed : String
  import_entries : Array[String]
  props_declaration : String?
  props_binding : String?
  props : Array[MacroField]
  prop_defaults : Array[PropDefault]
  emits_binding : String?
  emits : Array[MacroField]
  slots_binding : String?
  slots : Array[MacroField]
} derive(Eq, Show)

///|
pub(all) struct SfcDocument {
  filename : String
  extension : String
  template : String
  script : String?
  script_setup : String?
  script_setup_transformed : String?
  script_setup_import_entries : Array[String]
  generics : Array[GenericParam]
  props_declaration : String?
  props_binding : String?
  props : Array[MacroField]
  prop_defaults : Array[PropDefault]
  emits_binding : String?
  emits : Array[MacroField]
  slots_binding : String?
  slots : Array[MacroField]
  styles : Array[StyleBlock]
  blocks : Array[SfcBlock]
} derive(Eq, Show)

///|
pub(all) struct TemplateModel {
  argument : String?
  expression : String
  modifiers : Array[String]
} derive(Eq, Show)

///|
pub(all) enum TemplateAttrKind {
  Static
  Dynamic
  Event
  Boolean
} derive(Eq, Show)

///|
pub(all) struct TemplateAttr {
  kind : TemplateAttrKind
  name : String
  value : String
} derive(Eq, Show)

///|
pub(all) struct ForBinding {
  value : String
  index : String?
  source : String
} derive(Eq, Show)

///|
pub(all) enum IslandMode {
  None
  Load
  Idle
  Visible
  Media(String)
  Only
  ServerDefer
} derive(Eq, Show)

///|
pub(all) struct TemplateElement {
  tag : String
  attrs : Array[TemplateAttr]
  children : Array[TemplateNode]
  is_component : Bool
  is_self_closing : Bool
  if_expr : String?
  for_binding : ForBinding?
  island_mode : IslandMode
  show_expr : String?
  html_expr : String?
  model : TemplateModel?
  key_expr : String?
  ref_name : String?
  once : Bool
} derive(Eq, Show)

///|
pub(all) enum TemplateNode {
  Element(TemplateElement)
  Text(String)
  Interpolation(String)
} derive(Eq, Show)

///|
pub(all) struct CompileOutput {
  filename : String
  component_name : String
  extension : String
  client_code : String
  server_code : String
  css_output : String
  scope_id : String?
  island_components : Array[String]
  generics : Array[GenericParam]
  props_binding : String?
  props : Array[MacroField]
  emits_binding : String?
  emits : Array[MacroField]
  slots_binding : String?
  slots : Array[MacroField]
} derive(Eq, Show)

///|
pub fn CompileOutput::snapshot(self : CompileOutput) -> String {
  let sb = StringBuilder::new()
  sb.write_string("=== client ===\n")
  sb.write_string(self.client_code.trim().to_string())
  sb.write_string("\n=== server ===\n")
  sb.write_string(self.server_code.trim().to_string())
  sb.write_string("\n=== css ===\n")
  if self.css_output.trim().length() == 0 {
    sb.write_string("<empty>")
  } else {
    sb.write_string(self.css_output.trim().to_string())
  }
  sb.write_string("\n=== meta ===\n")
  sb.write_string("component=")
  sb.write_string(self.component_name)
  sb.write_string("\nextension=")
  sb.write_string(self.extension)
  sb.write_string("\nscope=")
  match self.scope_id {
    Some(scope_id) => sb.write_string(scope_id)
    None => sb.write_string("<none>")
  }
  sb.write_string("\nislands=")
  if self.island_components.is_empty() {
    sb.write_string("<none>")
  } else {
    sb.write_string(self.island_components.join(", "))
  }
  sb.write_string("\nprops_binding=")
  match self.props_binding {
    Some(binding) => sb.write_string(binding)
    None => sb.write_string("<none>")
  }
  sb.write_string("\nprops=")
  sb.write_string(format_macro_fields(self.props))
  sb.write_string("\nemits_binding=")
  match self.emits_binding {
    Some(binding) => sb.write_string(binding)
    None => sb.write_string("<none>")
  }
  sb.write_string("\nemits=")
  sb.write_string(format_macro_fields(self.emits))
  sb.write_string("\nslots_binding=")
  match self.slots_binding {
    Some(binding) => sb.write_string(binding)
    None => sb.write_string("<none>")
  }
  sb.write_string("\nslots=")
  sb.write_string(format_macro_fields(self.slots))
  sb.to_string()
}

///|
pub(all) suberror CompilerError {
  InvalidSfc(String)
  InvalidTemplate(String)
  InvalidDirective(String)
  InvalidScriptSetup(String)
} derive(Eq, Show)

///|
pub fn SfcDocument::has_scoped_style(self : SfcDocument) -> Bool {
  for style in self.styles {
    if style.scoped {
      return true
    }
  }
  false
}

///|
fn format_macro_fields(fields : Array[MacroField]) -> String {
  if fields.is_empty() {
    return "<none>"
  }
  let parts : Array[String] = []
  for field in fields {
    let label = match field.signature {
      Some(signature) => field.name + ":" + signature
      None => field.name
    }
    parts.push(label)
  }
  parts.join(", ")
}
