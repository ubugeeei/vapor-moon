///|
test "message buffer keeps multibyte content-length framing intact" {
  let json = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"name\":\"月\"}}"
  let frame = frame_json_text(json)
  let bytes = @buffer.Buffer::from_string(frame)
  let left = bytes.slice(end=19)
  let right = bytes.slice(start=19)
  let buffer = MessageBuffer::new()

  let first = buffer.push(left)
  let second = buffer.push(right)

  assert_eq(first, [])
  assert_eq(second, [json])
}

///|
test "message buffer drains consecutive frames" {
  let first = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}"
  let second = "{\"jsonrpc\":\"2.0\",\"method\":\"initialized\"}"
  let bytes = @buffer.Buffer::from_string(
    frame_json_text(first) + frame_json_text(second),
  )
  let buffer = MessageBuffer::new()

  let messages = buffer.push(bytes)

  assert_eq(messages, [first, second])
}
