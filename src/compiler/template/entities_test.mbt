///|
test "parse template decodes html entities in text and attrs" {
  let nodes = parse_template(
    "<div title='&lt;&amp;&gt;&quot;&#39;&#47;&#65;&#x41;'>&lt;&amp;&gt;&quot;&#39;&#47;&#65;&#x41;</div>",
  )

  assert_eq(nodes.length(), 1)
  match nodes[0] {
    Element(element) => {
      assert_eq(element.tag, "div")
      assert_eq(element.attrs.length(), 1)
      assert_eq(element.attrs[0].name, "title")
      assert_eq(element.attrs[0].kind, Static)
      assert_eq(element.attrs[0].value, "<&>\"'/AA")
      assert_eq(element.children.length(), 1)
      match element.children[0] {
        Text(content) => assert_eq(content, "<&>\"'/AA")
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "parse template decodes html entities inside directive expressions" {
  let nodes = parse_template("<div v-if='token == \"&amp;\"'>ok</div>")

  assert_eq(nodes.length(), 1)
  match nodes[0] {
    Element(element) => {
      assert_eq(element.if_expr, Some("token == \"&\""))
      assert_eq(element.children.length(), 1)
      match element.children[0] {
        Text(content) => assert_eq(content, "ok")
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "parse template keeps unknown or unterminated entities literal" {
  let nodes = parse_template("<div title='&madeup; &amp'>x &madeup; &amp</div>")

  assert_eq(nodes.length(), 1)
  match nodes[0] {
    Element(element) => {
      assert_eq(element.attrs.length(), 1)
      assert_eq(element.attrs[0].value, "&madeup; &amp")
      assert_eq(element.children.length(), 1)
      match element.children[0] {
        Text(content) => assert_eq(content, "x &madeup; &amp")
        _ => panic()
      }
    }
    _ => panic()
  }
}
