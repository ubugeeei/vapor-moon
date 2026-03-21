///|
pub struct RequestMessage {
  id : @js.Any?
  method_name : String
  params : @js.Any?
}

///|
pub fn decode_request(body : String) -> Result[RequestMessage, (Int, String)] {
  match parse_json(body) {
    Ok(value) => decode_request_value(value)
    Err(message) =>
      Err((-32700, "failed to parse JSON-RPC payload: " + message))
  }
}

///|
pub fn request_id(request : RequestMessage) -> @js.Any {
  request.id.unwrap_or(json_null())
}

///|
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
fn params_object(params : @js.Any?) -> @js.Any? {
  match params {
    Some(value) => object_value(value)
    None => None
  }
}
