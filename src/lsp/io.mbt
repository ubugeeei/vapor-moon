///|
/// Node/stdio IO helpers for the Vapor Moon LSP server.

///|
/// Convert a file URI to a platform path while surfacing any Node error message.
extern "js" fn safe_file_url_to_path(uri : String) -> @js.Any =
  #| (uri) => {
  #|   try {
  #|     return { ok: true, value: require("node:url").fileURLToPath(uri) };
  #|   } catch (error) {
  #|     return {
  #|       ok: false,
  #|       message: String(error?.message ?? error),
  #|     };
  #|   }
  #| }

///|
/// Convert a platform path to a `file://` URI.
extern "js" fn safe_path_to_file_uri(path : String) -> String =
  #| (path) => require("node:url").pathToFileURL(path).toString()

///|
fn stdin_readable(stream : @tty.ReadStream) -> @stream.Readable = "%identity"

///|
fn stdout_writable(stream : @tty.WriteStream) -> @stream.Writable = "%identity"

///|
/// Expose stdin as a generic readable stream.
pub fn stdin_stream() -> @stream.Readable {
  stdin_readable(@process.stdin())
}

///|
/// Expose stdout as a generic writable stream.
pub fn stdout_stream() -> @stream.Writable {
  stdout_writable(@process.stdout())
}

///|
/// Terminate the current Node process with an exit code.
pub fn exit_process(code : Int) -> Unit {
  @process.exit(code)
}

///|
/// Normalize stream chunks so the codec always receives a `Buffer`.
pub fn coerce_chunk(chunk : @js.Any) -> @buffer.Buffer {
  if @buffer.Buffer::isBuffer(chunk) {
    chunk.cast()
  } else {
    @buffer.Buffer::from_string(chunk.cast())
  }
}

///|
/// Convert a document URI into a local filename when possible.
pub fn uri_to_filename(uri : String) -> String {
  if uri.has_prefix("file://") {
    decode_string_result(safe_file_url_to_path(uri)).unwrap_or(uri)
  } else {
    uri
  }
}

///|
/// Convert a local filename into an LSP document URI.
pub fn filename_to_uri(filename : String) -> String {
  if filename.contains("://") {
    filename
  } else {
    safe_path_to_file_uri(filename)
  }
}

///|
/// Read a document by URI, ignoring unsupported non-file schemes.
pub fn read_uri_text(uri : String) -> String? {
  if uri.contains("://") && not(uri.has_prefix("file://")) {
    None
  } else {
    read_file_text(uri_to_filename(uri))
  }
}

///|
/// Read a UTF-8 file from disk, returning `None` on failure.
fn read_file_text(path : String) -> String? {
  let text = @node_fs.read_file_as_string(path) catch { _ => return None }
  Some(text)
}

///|
/// Decode the `{ ok, value | message }` result shape returned by JS helpers.
fn decode_string_result(value : @js.Any) -> Result[String, String] {
  let ok : Bool = value._get("ok").cast()
  if ok {
    Ok(value._get("value").cast())
  } else {
    Err(value._get("message").cast())
  }
}
