///|
/// Decoded JSON-RPC request used by the LSP server dispatcher.
pub struct RequestMessage {
  id : @js.Any?
  method_name : String
  params : @js.Any?
}

///|
/// Decode one JSON-RPC request body into the internal request representation.
pub fn decode_request(body : String) -> Result[RequestMessage, (Int, String)] {
  match parse_json(body) {
    Ok(value) => decode_request_value(value)
    Err(message) =>
      Err((-32700, "failed to parse JSON-RPC payload: " + message))
  }
}

///|
/// Return the request id or JSON null when the request is a notification.
pub fn request_id(request : RequestMessage) -> @js.Any {
  request.id.unwrap_or(json_null())
}

///|
/// Extract `textDocument.uri` from request params.
pub fn request_document_uri(params : @js.Any?) -> String? {
  match params_object(params) {
    Some(value) =>
      match object_prop(value, "textDocument") {
        Some(document) => string_prop(document, "uri")
        None => None
      }
    None => None
  }
}

///|
/// Extract `textDocument.text` from request params when present.
pub fn request_document_text(params : @js.Any?) -> String? {
  match params_object(params) {
    Some(value) =>
      match object_prop(value, "textDocument") {
        Some(document) => string_prop(document, "text")
        None => None
      }
    None => None
  }
}

///|
/// Extract the newest text value from `contentChanges`.
pub fn request_change_text(params : @js.Any?) -> String? {
  match params_object(params) {
    Some(params) =>
      match array_prop(params, "contentChanges") {
        Some(changes) =>
          if changes.length() == 0 {
            None
          } else {
            let change = changes[changes.length() - 1]
            match object_value(change) {
              Some(value) => string_prop(value, "text")
              None => None
            }
          }
        None => None
      }
    None => None
  }
}

///|
/// Extract `(uri, line, character)` from params used by hover/definition/completion.
pub fn request_document_position(params : @js.Any?) -> (String, Int, Int)? {
  match params_object(params) {
    Some(params) =>
      match
        (object_prop(params, "textDocument"), object_prop(params, "position")) {
        (Some(document), Some(position)) =>
          match
            (
              string_prop(document, "uri"),
              int_prop(position, "line"),
              int_prop(position, "character"),
            ) {
            (Some(uri), Some(line), Some(character)) =>
              Some((uri, line, character))
            _ => None
          }
        _ => None
      }
    None => None
  }
}

///|
/// Extract `context.includeDeclaration` from a references request.
pub fn request_include_declaration(params : @js.Any?) -> Bool {
  match params_object(params) {
    Some(params) =>
      match object_prop(params, "context") {
        Some(context) =>
          bool_prop(context, "includeDeclaration").unwrap_or(true)
        None => true
      }
    None => true
  }
}

///|
/// Validate the JSON-RPC envelope and build a `RequestMessage`.
fn decode_request_value(
  value : @js.Any,
) -> Result[RequestMessage, (Int, String)] {
  guard @js.is_object(value) else {
    return Err((-32600, "JSON-RPC payload must be an object"))
  }
  guard string_prop(value, "jsonrpc") == Some("2.0") else {
    return Err((-32600, "expected jsonrpc = \"2.0\""))
  }
  match string_prop(value, "method") {
    Some(method_name) =>
      Ok({
        id: get_prop(value, "id"),
        method_name,
        params: get_prop(value, "params"),
      })
    None => Err((-32600, "request is missing method"))
  }
}

///|
/// Treat missing or non-object params as absent.
fn params_object(params : @js.Any?) -> @js.Any? {
  match params {
    Some(value) => object_value(value)
    None => None
  }
}
