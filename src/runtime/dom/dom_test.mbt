///|
extern "js" fn fake_document() -> @js.Any =
  #| () => ({
  #|   listeners: Object.create(null),
  #|   addEventListener(name, handler) {
  #|     (this.listeners[name] ??= []).push(handler);
  #|   },
  #| })

///|
extern "js" fn fake_element(
  doc : @js.Any,
  label : String,
  parent : @js.Any?,
) -> @js_dom.Element =
  #| (doc, label, parent) => ({
  #|   label,
  #|   ownerDocument: doc,
  #|   parentNode: parent ?? null,
  #|   listeners: Object.create(null),
  #|   addEventListener(name, handler) {
  #|     (this.listeners[name] ??= []).push(handler);
  #|   },
  #| })

///|
extern "js" fn dispatch_delegated_event(
  doc : @js.Any,
  name : String,
  target : @js.Any,
) -> Unit =
  #| (doc, name, target) => {
  #|   const event = {
  #|     type: name,
  #|     target,
  #|     cancelBubble: false,
  #|     stopPropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|     stopImmediatePropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|   };
  #|   for (const handler of doc.listeners[name] ?? []) {
  #|     handler(event);
  #|     if (event.cancelBubble) {
  #|       return;
  #|     }
  #|   }
  #| }

///|
extern "js" fn document_listener_count(doc : @js.Any, name : String) -> Int =
  #| (doc, name) => doc.listeners[name]?.length ?? 0

///|
extern "js" fn element_listener_count(elem : @js.Any, name : String) -> Int =
  #| (elem, name) => elem.listeners[name]?.length ?? 0

///|
extern "js" fn event_current_target_label(event : @js.Any) -> String =
  #| (event) => event.currentTarget?.label ?? ""

///|
extern "js" fn stop_event(event : @js.Any) -> Unit =
  #| (event) => event.stopPropagation()

///|
test "delegated handlers bubble through parent chain with currentTarget" {
  let doc = fake_document()
  let parent = fake_element(doc, "parent", None)
  let child = fake_element(doc, "child", Some(parent.as_any()))
  let targets : Array[String] = []

  apply_attr(
    child,
    "click",
    attr_handler(fn(event) { targets.push(event_current_target_label(event)) }),
  )
  apply_attr(
    parent,
    "click",
    attr_handler(fn(event) { targets.push(event_current_target_label(event)) }),
  )

  assert_eq(document_listener_count(doc, "click"), 1)
  assert_eq(element_listener_count(child.as_any(), "click"), 0)
  assert_eq(element_listener_count(parent.as_any(), "click"), 0)

  dispatch_delegated_event(doc, "click", child.as_any())

  assert_eq(targets, ["child", "parent"])
}

///|
test "delegated handlers respect stopPropagation" {
  let doc = fake_document()
  let parent = fake_element(doc, "parent", None)
  let child = fake_element(doc, "child", Some(parent.as_any()))
  let targets : Array[String] = []

  apply_attr(
    child,
    "click",
    attr_handler(fn(event) {
      targets.push(event_current_target_label(event))
      stop_event(event)
    }),
  )
  apply_attr(
    parent,
    "click",
    attr_handler(fn(event) { targets.push(event_current_target_label(event)) }),
  )

  dispatch_delegated_event(doc, "click", child.as_any())

  assert_eq(targets, ["child"])
}

///|
test "non bubbling events stay on direct listeners" {
  let doc = fake_document()
  let elem = fake_element(doc, "hover", None)

  apply_attr(elem, "mouseenter", attr_handler(fn(_event) { () }))

  assert_eq(document_listener_count(doc, "mouseenter"), 0)
  assert_eq(element_listener_count(elem.as_any(), "mouseenter"), 1)
}

///|
test "template refs resolve per TemplateRef instance" {
  let doc = fake_document()
  let first_target = fake_element(doc, "first", None)
  let second_target = fake_element(doc, "second", None)
  let first_ref = @vm.use_template_ref[@js_dom.Element]("shared")
  let second_ref = @vm.use_template_ref[@js_dom.Element]("shared")

  bind_template_ref(first_ref, first_target.as_any())
  bind_template_ref(second_ref, second_target.as_any())

  let first = match resolve_template_ref(first_ref) {
    Some(target) => target
    None => panic()
  }
  let second = match resolve_template_ref(second_ref) {
    Some(target) => target
    None => panic()
  }

  assert_eq(first.as_any()._get("label").cast(), "first")
  assert_eq(second.as_any()._get("label").cast(), "second")
}

///|
test "template refs still fall back to name lookup" {
  let doc = fake_document()
  let target = fake_element(doc, "legacy", None)
  let ref_ = @vm.use_template_ref[@js_dom.Element]("legacy")

  bind_template_ref_name("legacy", target.as_any())

  let resolved = match resolve_template_ref(ref_) {
    Some(target) => target
    None => panic()
  }

  assert_eq(resolved.as_any()._get("label").cast(), "legacy")
}
