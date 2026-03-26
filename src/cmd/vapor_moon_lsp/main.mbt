///|
/// stdio JSON-RPC server for Vapor Moon editor integrations.

///|
/// Bridge stdin/stdout streams to the LSP request handler.
fn main {
  let state = @lsp.ServerState::new()
  let buffer = @lsp.MessageBuffer::new()
  let input = @lsp.stdin_stream()
  let output = @lsp.stdout_stream()

  input.on("data", fn(chunk : @js.Any) {
    let bodies = buffer.push(@lsp.coerce_chunk(chunk))
    for body in bodies {
      let result = @lsp.handle_message(state, body)
      for message in result.messages {
        ignore(output.write(@js.any(message)))
      }
      match result.exit_code {
        Some(code) => @lsp.exit_process(code)
        None => ()
      }
    }
  })
  input.on("error", fn(_error : @js.Any) { @lsp.exit_process(1) })
  input.resume_() |> ignore
}
