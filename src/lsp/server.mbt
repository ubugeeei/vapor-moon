///|
pub fn handle_message(state : ServerState, body : String) -> ServerResult {
  match decode_request(body) {
    Ok(request) => dispatch_request(state, request)
    Err((code, message)) =>
      { messages: [error_message(json_null(), code, message)], exit_code: None }
  }
}

///|
fn ServerState::document_text(self : ServerState, uri : String) -> String? {
  match self.documents.get(uri) {
    Some(text) => Some(text)
    None => read_uri_text(uri)
  }
}

///|
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
    "textDocument/completion" => handle_completion(state, request)
    _ => reply_missing_method(request)
  }
}

///|
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
fn publish_diagnostics(state : ServerState, uri : String) -> ServerResult {
  let source = state.document_text(uri).unwrap_or("")
  let diagnostics = @tooling.diagnostics(source, filename=uri_to_filename(uri))
  { messages: [diagnostics_notification(uri, diagnostics)], exit_code: None }
}

///|
fn reply_ok(request : RequestMessage, payload : @js.Any) -> ServerResult {
  match request.id {
    Some(id) => { messages: [success_message(id, payload)], exit_code: None }
    None => ServerResult::default()
  }
}

///|
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
fn reply_missing_method(request : RequestMessage) -> ServerResult {
  reply_error(
    request,
    method_not_found_code,
    "unsupported method `" + request.method_name + "`",
  )
}
