///|
/// JSON-RPC/LSP message builders shared by the server handlers.

///|
/// Standard JSON-RPC error code for malformed request objects.
pub let invalid_request_code : Int = -32600

///|
/// Standard JSON-RPC error code for unsupported methods.
pub let method_not_found_code : Int = -32601

///|
/// Standard JSON-RPC error code for structurally invalid parameters.
pub let invalid_params_code : Int = -32602

///|
/// Build a successful JSON-RPC response frame.
pub fn success_message(id : @js.Any, result : @js.Any) -> String {
  let payload = json_object([
    ("jsonrpc", @js.any("2.0")),
    ("id", id),
    ("result", result),
  ])
  frame_json_text(stringify_json(payload))
}

///|
/// Build an error JSON-RPC response frame.
pub fn error_message(id : @js.Any, code : Int, message : String) -> String {
  let payload = json_object([
    ("jsonrpc", @js.any("2.0")),
    ("id", id),
    (
      "error",
      json_object([("code", @js.any(code)), ("message", @js.any(message))]),
    ),
  ])
  frame_json_text(stringify_json(payload))
}

///|
/// Advertise the Vapor Moon server capabilities during `initialize`.
pub fn initialize_payload() -> @js.Any {
  json_object([
    (
      "capabilities",
      json_object([
        (
          "textDocumentSync",
          json_object([
            ("openClose", @js.any(true)),
            ("change", @js.any(1)),
            ("save", @js.any(true)),
          ]),
        ),
        ("hoverProvider", @js.any(true)),
        ("definitionProvider", @js.any(true)),
        ("referencesProvider", @js.any(true)),
        ("documentFormattingProvider", @js.any(true)),
        (
          "completionProvider",
          json_object([
            ("resolveProvider", @js.any(false)),
            ("triggerCharacters", @js.any([".", ":", "-", "@", "#"])),
          ]),
        ),
      ]),
    ),
    (
      "serverInfo",
      json_object([
        ("name", @js.any("Vapor Moon LSP")),
        ("version", @js.any("0.1.0")),
      ]),
    ),
    ("positionEncoding", @js.any("utf-16")),
  ])
}

///|
/// Convert a hover result into the LSP `Hover` payload shape.
pub fn hover_payload(result : @tooling.ToolingHover?) -> @js.Any {
  match result {
    Some(hover) =>
      json_object([
        (
          "contents",
          json_object([
            ("kind", @js.any("plaintext")),
            ("value", @js.any(hover.contents)),
          ]),
        ),
        ("range", range_json(hover.location.range)),
      ])
    None => json_null()
  }
}

///|
/// Convert a definition result into the LSP `Location` payload shape.
pub fn definition_payload(result : @tooling.ToolingDefinition?) -> @js.Any {
  match result {
    Some(definition) =>
      location_json(
        filename_to_uri(definition.location.filename),
        definition.location.range,
      )
    None => json_null()
  }
}

///|
/// Convert tooling completion items into the LSP completion-list payload.
pub fn completion_payload(
  items : Array[@tooling.ToolingCompletionItem],
) -> @js.Any {
  let payload : Array[@js.Any] = []
  for item in items {
    payload.push(completion_item_json(item))
  }
  json_object([("isIncomplete", @js.any(false)), ("items", @js.any(payload))])
}

///|
/// Convert reference locations into the LSP locations array shape.
pub fn references_payload(
  locations : Array[@tooling.ToolingLocation],
) -> @js.Any {
  let payload : Array[@js.Any] = []
  for location in locations {
    payload.push(
      location_json(filename_to_uri(location.filename), location.range),
    )
  }
  @js.any(payload)
}

///|
/// Convert text edits into the LSP formatting result payload.
pub fn formatting_payload(edits : Array[@tooling.ToolingTextEdit]) -> @js.Any {
  let payload : Array[@js.Any] = []
  for edit in edits {
    payload.push(
      json_object([
        ("range", range_json(edit.range)),
        ("newText", @js.any(edit.new_text)),
      ]),
    )
  }
  @js.any(payload)
}

///|
/// Build a `textDocument/publishDiagnostics` notification frame.
pub fn diagnostics_notification(
  uri : String,
  diagnostics : Array[@tooling.ToolingDiagnostic],
) -> String {
  let payload : Array[@js.Any] = []
  for diagnostic in diagnostics {
    payload.push(diagnostic_json(diagnostic))
  }
  notification_message(
    "textDocument/publishDiagnostics",
    json_object([("uri", @js.any(uri)), ("diagnostics", @js.any(payload))]),
  )
}

///|
/// Build a framed JSON-RPC notification with the given method and params.
fn notification_message(method_name : String, params : @js.Any) -> String {
  let payload = json_object([
    ("jsonrpc", @js.any("2.0")),
    ("method", @js.any(method_name)),
    ("params", params),
  ])
  frame_json_text(stringify_json(payload))
}

///|
/// Convert one tooling diagnostic into the LSP diagnostic shape.
fn diagnostic_json(diagnostic : @tooling.ToolingDiagnostic) -> @js.Any {
  json_object([
    ("range", range_json(diagnostic.location.range)),
    ("severity", @js.any(diagnostic_severity(diagnostic.severity))),
    ("source", @js.any("vapor-moon")),
    ("message", @js.any(diagnostic.message)),
  ])
}

///|
/// Convert one tooling completion item into the LSP completion-item shape.
fn completion_item_json(item : @tooling.ToolingCompletionItem) -> @js.Any {
  json_object([
    ("label", @js.any(item.label)),
    ("kind", @js.any(completion_kind(item.kind))),
    ("detail", @js.any(item.detail)),
    ("insertText", @js.any(item.insert_text)),
    ("insertTextFormat", @js.any(1)),
  ])
}

///|
/// Convert a filename/range pair into the LSP location shape.
fn location_json(uri : String, range : @tooling.ToolingRange) -> @js.Any {
  json_object([("uri", @js.any(uri)), ("range", range_json(range))])
}

///|
/// Convert a tooling range into the LSP range shape.
fn range_json(range : @tooling.ToolingRange) -> @js.Any {
  json_object([
    ("start", position_json(range.start)),
    ("end", position_json(range.end_)),
  ])
}

///|
/// Convert a tooling position into the LSP position shape.
fn position_json(position : @tooling.ToolingPosition) -> @js.Any {
  json_object([
    ("line", @js.any(position.line)),
    ("character", @js.any(position.character)),
  ])
}

///|
/// Map textual severities to LSP numeric severity codes.
fn diagnostic_severity(severity : String) -> Int {
  match severity {
    "error" => 1
    "warning" => 2
    "hint" => 4
    _ => 3
  }
}

///|
/// Map Vapor Moon completion categories to LSP completion kinds.
fn completion_kind(kind : String) -> Int {
  match kind {
    "props" | "emit" | "slots" => 5
    "directive" | "macro" | "event" | "binding" => 14
    "client" | "server" => 14
    _ => 10
  }
}
