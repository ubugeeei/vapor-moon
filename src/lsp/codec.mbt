///|
/// Byte buffer that incrementally frames LSP `Content-Length` messages.
pub struct MessageBuffer {
  mut pending : @buffer.Buffer
}

///|
/// Create an empty message buffer for the stdio transport.
pub fn MessageBuffer::new() -> MessageBuffer {
  { pending: @buffer.Buffer::alloc(0) }
}

///|
/// Append a new byte chunk and drain every complete JSON-RPC message body.
pub fn MessageBuffer::push(
  self : MessageBuffer,
  chunk : @buffer.Buffer,
) -> Array[String] {
  self.pending = if self.pending.length() == 0 {
    chunk
  } else {
    @buffer.Buffer::concat([self.pending, chunk])
  }
  self.drain_messages()
}

///|
/// Add the `Content-Length` header required by the LSP stdio transport.
pub fn frame_json_text(json_text : String) -> String {
  "Content-Length: " +
  @buffer.Buffer::byteLength(json_text).to_string() +
  "\r\n\r\n" +
  json_text
}

///|
/// Drain all complete frames currently available in the pending buffer.
fn MessageBuffer::drain_messages(self : MessageBuffer) -> Array[String] {
  let messages : Array[String] = []
  while true {
    match next_message(self.pending) {
      Some((body, consumed)) => {
        messages.push(body)
        self.pending = if consumed >= self.pending.length() {
          @buffer.Buffer::alloc(0)
        } else {
          self.pending.subarray(start=consumed)
        }
      }
      None => break
    }
  }
  messages
}

///|
/// Parse the next complete message body from the pending byte buffer.
fn next_message(pending : @buffer.Buffer) -> (String, Int)? {
  match find_header_end(pending) {
    Some((header_end, separator_length)) => {
      let header_text = pending.toString(end=header_end)
      match parse_content_length(header_text) {
        Some(content_length) => {
          let start = header_end + separator_length
          let end_ = start + content_length
          if pending.length() < end_ {
            None
          } else {
            Some((pending.toString(start~, end=end_), end_))
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// Find the boundary between LSP headers and the message body.
fn find_header_end(pending : @buffer.Buffer) -> (Int, Int)? {
  let header = @buffer.Buffer::from_string("\r\n\r\n")
  let index = pending.indexOf(header.as_any())
  if index >= 0 {
    return Some((index, 4))
  }
  let alt = @buffer.Buffer::from_string("\n\n")
  let alt_index = pending.indexOf(alt.as_any())
  if alt_index >= 0 {
    Some((alt_index, 2))
  } else {
    None
  }
}

///|
/// Read the `Content-Length` header from a decoded header block.
fn parse_content_length(header_text : String) -> Int? {
  for raw_line in header_text.split("\n") {
    let line = raw_line.trim(char_set=" \r")
    if line.to_lower().has_prefix("content-length:") {
      let parts : Array[StringView] = line.split(":").collect()
      if parts.length() < 2 {
        return None
      }
      let value = parts[1].trim(char_set=" ").to_string()
      let parsed = @strconv.parse_int(value) catch { _ => return None }
      return Some(parsed)
    }
  }
  None
}
