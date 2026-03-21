///|
pub let invalid_request_code : Int = -32600

///|
pub let method_not_found_code : Int = -32601

///|
pub let invalid_params_code : Int = -32602

///|
pub fn success_message(id : @js.Any, result : @js.Any) -> String {
  let payload = json_object([
    ("jsonrpc", @js.any("2.0")),
    ("id", id),
    ("result", result),
  ])
  frame_json_text(stringify_json(payload))
}

///|
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
        (
          "completionProvider",
          json_object([
            ("resolveProvider", @js.any(false)),
            ("triggerCharacters", @js.any([".", ":", "-", "@"])),
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
fn notification_message(method_name : String, params : @js.Any) -> String {
  let payload = json_object([
    ("jsonrpc", @js.any("2.0")),
    ("method", @js.any(method_name)),
    ("params", params),
  ])
  frame_json_text(stringify_json(payload))
}

///|
fn diagnostic_json(diagnostic : @tooling.ToolingDiagnostic) -> @js.Any {
  json_object([
    ("range", range_json(diagnostic.location.range)),
    ("severity", @js.any(diagnostic_severity(diagnostic.severity))),
    ("source", @js.any("vapor-moon")),
    ("message", @js.any(diagnostic.message)),
  ])
}

///|
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
fn location_json(uri : String, range : @tooling.ToolingRange) -> @js.Any {
  json_object([("uri", @js.any(uri)), ("range", range_json(range))])
}

///|
fn range_json(range : @tooling.ToolingRange) -> @js.Any {
  json_object([
    ("start", position_json(range.start)),
    ("end", position_json(range.end_)),
  ])
}

///|
fn position_json(position : @tooling.ToolingPosition) -> @js.Any {
  json_object([
    ("line", @js.any(position.line)),
    ("character", @js.any(position.character)),
  ])
}

///|
fn diagnostic_severity(severity : String) -> Int {
  match severity {
    "error" => 1
    "warning" => 2
    "hint" => 4
    _ => 3
  }
}

///|
fn completion_kind(kind : String) -> Int {
  match kind {
    "props" | "emit" | "slots" => 5
    "directive" | "macro" => 14
    "client" | "server" => 14
    _ => 10
  }
}
