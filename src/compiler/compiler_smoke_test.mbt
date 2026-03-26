///|
test "compiler root smoke test" {
  let output = compile("<template><div>ok</div></template>") catch { _ => panic() }
  assert_true(output.client_code.length() > 0)
  assert_true(output.server_code.length() > 0)
}
