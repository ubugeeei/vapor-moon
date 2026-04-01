///|
/// JSON-RPC request router for the stdio LSP server.

///|
/// Decode one JSON-RPC body and dispatch it to the appropriate request handler.
pub fn handle_message(state : ServerState, body : String) -> ServerResult {
  match decode_request(body) {
    Ok(request) => dispatch_request(state, request)
    Err((code, message)) =>
      { messages: [error_message(json_null(), code, message)], exit_code: None }
  }
}

///|
/// Resolve the current document text, falling back to disk when not cached in memory.
fn ServerState::document_text(self : ServerState, uri : String) -> String? {
  match self.documents.get(uri) {
    Some(text) => Some(text)
    None => read_uri_text(uri)
  }
}

///|
/// Route one decoded request to the matching LSP method implementation.
fn dispatch_request(
  state : ServerState,
  request : RequestMessage,
) -> ServerResult {
  match request.method_name {
    "initialize" => reply_ok(request, initialize_payload())
    "initialized" => ServerResult::default()
    "shutdown" => {
      state.shutdown_requested = true
      reply_ok(request, json_null())
    }
    "exit" =>
      {
        messages: [],
        exit_code: Some(if state.shutdown_requested { 0 } else { 1 }),
      }
    "textDocument/didOpen" => handle_did_open(state, request.params)
    "textDocument/didChange" => handle_did_change(state, request.params)
    "textDocument/didSave" => handle_did_save(state, request.params)
    "textDocument/didClose" => handle_did_close(state, request.params)
    "textDocument/hover" => handle_hover(state, request)
    "textDocument/definition" => handle_definition(state, request)
    "textDocument/references" => handle_references(state, request)
    "textDocument/completion" => handle_completion(state, request)
    "textDocument/formatting" => handle_formatting(state, request)
    _ => reply_missing_method(request)
  }
}

///|
/// Cache the opened document and immediately publish diagnostics.
fn handle_did_open(state : ServerState, params : @js.Any?) -> ServerResult {
  match (request_document_uri(params), request_document_text(params)) {
    (Some(uri), Some(text)) => {
      state.set_document(uri, text)
      publish_diagnostics(state, uri)
    }
    _ => ServerResult::default()
  }
}

///|
/// Replace the cached document text with the latest incremental change payload.
fn handle_did_change(state : ServerState, params : @js.Any?) -> ServerResult {
  match (request_document_uri(params), request_change_text(params)) {
    (Some(uri), Some(text)) => {
      state.set_document(uri, text)
      publish_diagnostics(state, uri)
    }
    _ => ServerResult::default()
  }
}

///|
/// Refresh diagnostics on save, optionally updating the cached text first.
fn handle_did_save(state : ServerState, params : @js.Any?) -> ServerResult {
  match request_document_uri(params) {
    Some(uri) => {
      match request_document_text(params) {
        Some(text) => state.set_document(uri, text)
        None => ()
      }
      publish_diagnostics(state, uri)
    }
    None => ServerResult::default()
  }
}

///|
/// Clear cached document state and publish an empty diagnostics set.
fn handle_did_close(state : ServerState, params : @js.Any?) -> ServerResult {
  match request_document_uri(params) {
    Some(uri) => {
      state.clear_document(uri)
      { messages: [diagnostics_notification(uri, [])], exit_code: None }
    }
    None => ServerResult::default()
  }
}

///|
/// Serve `textDocument/hover` requests from the tooling query layer.
fn handle_hover(state : ServerState, request : RequestMessage) -> ServerResult {
  match request_document_position(request.params) {
    Some((uri, line, character)) => {
      let hover = match state.document_text(uri) {
        Some(source) =>
          @tooling.hover_at(
            source,
            line,
            character,
            filename=uri_to_filename(uri),
          )
        None => None
      }
      reply_ok(request, hover_payload(hover))
    }
    None =>
      reply_error(
        request, invalid_params_code, "hover requires textDocument.uri and position",
      )
  }
}

///|
/// Serve `textDocument/definition` requests from the tooling query layer.
fn handle_definition(
  state : ServerState,
  request : RequestMessage,
) -> ServerResult {
  match request_document_position(request.params) {
    Some((uri, line, character)) => {
      let definition = match state.document_text(uri) {
        Some(source) =>
          @tooling.definition_at(
            source,
            line,
            character,
            filename=uri_to_filename(uri),
          )
        None => None
      }
      reply_ok(request, definition_payload(definition))
    }
    None =>
      reply_error(
        request, invalid_params_code, "definition requires textDocument.uri and position",
      )
  }
}

///|
/// Serve `textDocument/completion` requests from the tooling query layer.
fn handle_completion(
  state : ServerState,
  request : RequestMessage,
) -> ServerResult {
  match request_document_position(request.params) {
    Some((uri, line, character)) => {
      let items = match state.document_text(uri) {
        Some(source) =>
          @tooling.complete_at(
            source,
            line,
            character,
            filename=uri_to_filename(uri),
          )
        None => []
      }
      reply_ok(request, completion_payload(items))
    }
    None =>
      reply_error(
        request, invalid_params_code, "completion requires textDocument.uri and position",
      )
  }
}

///|
/// Serve `textDocument/references` requests from the tooling query layer.
fn handle_references(
  state : ServerState,
  request : RequestMessage,
) -> ServerResult {
  match request_document_position(request.params) {
    Some((uri, line, character)) => {
      let include_declaration = request_include_declaration(request.params)
      let locations = match state.document_text(uri) {
        Some(source) =>
          @tooling.references_at(
            source,
            line,
            character,
            include_declaration~,
            filename=uri_to_filename(uri),
          )
        None => []
      }
      reply_ok(request, references_payload(locations))
    }
    None =>
      reply_error(
        request, invalid_params_code, "references requires textDocument.uri, position, and optional context",
      )
  }
}

///|
/// Serve `textDocument/formatting` requests using one full-document edit.
fn handle_formatting(
  state : ServerState,
  request : RequestMessage,
) -> ServerResult {
  match request_document_uri(request.params) {
    Some(uri) => {
      let edits = match state.document_text(uri) {
        Some(source) =>
          match
            @tooling.formatting_edit(source, filename=uri_to_filename(uri)) {
            Some(edit) => [edit]
            None => []
          }
        None => []
      }
      reply_ok(request, formatting_payload(edits))
    }
    None =>
      reply_error(
        request, invalid_params_code, "formatting requires textDocument.uri",
      )
  }
}

///|
/// Recompute diagnostics for one document and wrap them in an LSP notification.
fn publish_diagnostics(state : ServerState, uri : String) -> ServerResult {
  let source = state.document_text(uri).unwrap_or("")
  let diagnostics = @tooling.diagnostics(source, filename=uri_to_filename(uri))
  { messages: [diagnostics_notification(uri, diagnostics)], exit_code: None }
}

///|
/// Emit a successful JSON-RPC response when the request expects one.
fn reply_ok(request : RequestMessage, payload : @js.Any) -> ServerResult {
  match request.id {
    Some(id) => { messages: [success_message(id, payload)], exit_code: None }
    None => ServerResult::default()
  }
}

///|
/// Emit an error JSON-RPC response when the request expects one.
fn reply_error(
  request : RequestMessage,
  code : Int,
  message : String,
) -> ServerResult {
  match request.id {
    Some(id) =>
      { messages: [error_message(id, code, message)], exit_code: None }
    None => ServerResult::default()
  }
}

///|
/// Standard fallback for unsupported JSON-RPC methods.
fn reply_missing_method(request : RequestMessage) -> ServerResult {
  reply_error(
    request,
    method_not_found_code,
    "unsupported method `" + request.method_name + "`",
  )
}
