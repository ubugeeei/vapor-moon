///|
pub struct ServerState {
  documents : Map[String, String]
  mut shutdown_requested : Bool
}

///|
pub struct ServerResult {
  messages : Array[String]
  exit_code : Int?
} derive(Default, Eq, Show)

///|
pub fn ServerState::new() -> ServerState {
  { documents: {}, shutdown_requested: false }
}

///|
pub fn ServerState::set_document(
  self : ServerState,
  uri : String,
  text : String,
) -> Unit {
  self.documents[uri] = text
}

///|
pub fn ServerState::clear_document(self : ServerState, uri : String) -> Unit {
  self.documents.remove(uri) |> ignore
}
