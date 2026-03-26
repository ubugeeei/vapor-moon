///|
/// Mutable server state shared across JSON-RPC request handlers.
pub struct ServerState {
  documents : Map[String, String]
  mut shutdown_requested : Bool
}

///|
/// Outgoing server action: zero or more framed messages plus an optional exit code.
pub struct ServerResult {
  messages : Array[String]
  exit_code : Int?
} derive(Default, Eq, Show)

///|
/// Create the initial empty LSP server state.
pub fn ServerState::new() -> ServerState {
  { documents: {}, shutdown_requested: false }
}

///|
/// Cache the latest text for a document URI.
pub fn ServerState::set_document(
  self : ServerState,
  uri : String,
  text : String,
) -> Unit {
  self.documents[uri] = text
}

///|
/// Remove cached text for a document URI.
pub fn ServerState::clear_document(self : ServerState, uri : String) -> Unit {
  self.documents.remove(uri) |> ignore
}
