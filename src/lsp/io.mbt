///|
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
extern "js" fn safe_path_to_file_uri(path : String) -> String =
  #| (path) => require("node:url").pathToFileURL(path).toString()

///|
fn stdin_readable(stream : @tty.ReadStream) -> @stream.Readable = "%identity"

///|
fn stdout_writable(stream : @tty.WriteStream) -> @stream.Writable = "%identity"

///|
pub fn stdin_stream() -> @stream.Readable {
  stdin_readable(@process.stdin())
}

///|
pub fn stdout_stream() -> @stream.Writable {
  stdout_writable(@process.stdout())
}

///|
pub fn exit_process(code : Int) -> Unit {
  @process.exit(code)
}

///|
pub fn coerce_chunk(chunk : @js.Any) -> @buffer.Buffer {
  if @buffer.Buffer::isBuffer(chunk) {
    chunk.cast()
  } else {
    @buffer.Buffer::from_string(chunk.cast())
  }
}

///|
pub fn uri_to_filename(uri : String) -> String {
  if uri.has_prefix("file://") {
    decode_string_result(safe_file_url_to_path(uri)).unwrap_or(uri)
  } else {
    uri
  }
}

///|
pub fn filename_to_uri(filename : String) -> String {
  if filename.contains("://") {
    filename
  } else {
    safe_path_to_file_uri(filename)
  }
}

///|
pub fn read_uri_text(uri : String) -> String? {
  if uri.contains("://") && not(uri.has_prefix("file://")) {
    None
  } else {
    read_file_text(uri_to_filename(uri))
  }
}

///|
fn read_file_text(path : String) -> String? {
  let text = @node_fs.read_file_as_string(path) catch { _ => return None }
  Some(text)
}

///|
fn decode_string_result(value : @js.Any) -> Result[String, String] {
  let ok : Bool = value._get("ok").cast()
  if ok {
    Ok(value._get("value").cast())
  } else {
    Err(value._get("message").cast())
  }
}
