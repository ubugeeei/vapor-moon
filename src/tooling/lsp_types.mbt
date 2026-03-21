///|
pub struct ToolingPosition {
  line : Int
  character : Int
} derive(Eq, Show)

///|
pub struct ToolingRange {
  start : ToolingPosition
  end_ : ToolingPosition
} derive(Eq, Show)

///|
pub struct ToolingLocation {
  filename : String
  span : @compiler.SourceSpan
  range : ToolingRange
} derive(Eq, Show)

///|
pub struct ToolingDiagnostic {
  severity : String
  message : String
  location : ToolingLocation
} derive(Eq, Show)

///|
pub struct ToolingHover {
  contents : String
  location : ToolingLocation
} derive(Eq, Show)

///|
pub struct ToolingDefinition {
  name : String
  location : ToolingLocation
} derive(Eq, Show)

///|
pub struct ToolingCompletionItem {
  label : String
  kind : String
  detail : String
  insert_text : String
} derive(Eq, Show)
