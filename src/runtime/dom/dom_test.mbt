///|
extern "js" fn fake_document() -> @js.Any =
  #| () => ({
  #|   listeners: Object.create(null),
  #|   addEventListener(name, handler, options = false) {
  #|     (this.listeners[name] ??= []).push({ handler, options });
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
  #|   addEventListener(name, handler, options = false) {
  #|     (this.listeners[name] ??= []).push({ handler, options });
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
  #|     defaultPrevented: false,
  #|     preventDefault() {
  #|       this.defaultPrevented = true;
  #|     },
  #|     stopPropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|     stopImmediatePropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|   };
  #|   for (const entry of doc.listeners[name] ?? []) {
  #|     entry.handler(event);
  #|     if (event.cancelBubble) {
  #|       return;
  #|     }
  #|   }
  #| }

///|
extern "js" fn dispatch_direct_event(
  elem : @js.Any,
  name : String,
  target : @js.Any,
) -> Unit =
  #| (elem, name, target) => {
  #|   const event = {
  #|     type: name,
  #|     target,
  #|     cancelBubble: false,
  #|     defaultPrevented: false,
  #|     preventDefault() {
  #|       this.defaultPrevented = true;
  #|     },
  #|     stopPropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|     stopImmediatePropagation() {
  #|       this.cancelBubble = true;
  #|     },
  #|   };
  #|   const entries = elem.listeners[name] ?? [];
  #|   for (let index = 0; index < entries.length; index += 1) {
  #|     const entry = entries[index];
  #|     entry.handler(event);
  #|     if (entry.options?.once) {
  #|       entries.splice(index, 1);
  #|       index -= 1;
  #|     }
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
extern "js" fn listener_option_enabled(
  elem : @js.Any,
  name : String,
  option : String,
) -> Bool =
  #| (elem, name, option) => {
  #|   const entry = elem.listeners[name]?.[0];
  #|   if (!entry) {
  #|     return false;
  #|   }
  #|   if (entry.options === true) {
  #|     return option === "capture";
  #|   }
  #|   return Boolean(entry.options?.[option]);
  #| }

///|
extern "js" fn event_current_target_label(event : @js.Any) -> String =
  #| (event) => event.currentTarget?.label ?? ""

///|
extern "js" fn stop_event(event : @js.Any) -> Unit =
  #| (event) => event.stopPropagation()

///|
extern "js" fn event_default_prevented(event : @js.Any) -> Bool =
  #| (event) => Boolean(event.defaultPrevented)

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

///|
test "event modifiers can stop propagation and prevent default" {
  let doc = fake_document()
  let parent = fake_element(doc, "parent", None)
  let child = fake_element(doc, "child", Some(parent.as_any()))
  let targets : Array[String] = []
  let prevented : Array[Bool] = []

  apply_attr(
    child,
    "click",
    attr_handler_with_modifiers(
      fn(event) {
        targets.push(event_current_target_label(event))
        prevented.push(event_default_prevented(event))
      },
      ["prevent", "stop"],
    ),
  )
  apply_attr(
    parent,
    "click",
    attr_handler(fn(event) { targets.push(event_current_target_label(event)) }),
  )

  dispatch_delegated_event(doc, "click", child.as_any())

  assert_eq(targets, ["child"])
  assert_eq(prevented, [true])
}

///|
test "self modifier only fires on the bound element" {
  let doc = fake_document()
  let parent = fake_element(doc, "parent", None)
  let child = fake_element(doc, "child", Some(parent.as_any()))
  let targets : Array[String] = []

  apply_attr(
    parent,
    "click",
    attr_handler_with_modifiers(
      fn(event) { targets.push(event_current_target_label(event)) },
      ["self"],
    ),
  )

  dispatch_delegated_event(doc, "click", child.as_any())
  dispatch_delegated_event(doc, "click", parent.as_any())

  assert_eq(targets, ["parent"])
}

///|
test "listener option modifiers bind direct listeners" {
  let doc = fake_document()
  let elem = fake_element(doc, "button", None)
  let calls : Array[Int] = []

  apply_attr(
    elem,
    "click",
    attr_handler_with_modifiers(
      fn(_event) { calls.push(1) },
      ["capture", "once", "passive"],
    ),
  )

  assert_eq(document_listener_count(doc, "click"), 0)
  assert_eq(element_listener_count(elem.as_any(), "click"), 1)
  assert_true(listener_option_enabled(elem.as_any(), "click", "capture"))
  assert_true(listener_option_enabled(elem.as_any(), "click", "once"))
  assert_true(listener_option_enabled(elem.as_any(), "click", "passive"))

  dispatch_direct_event(elem.as_any(), "click", elem.as_any())
  dispatch_direct_event(elem.as_any(), "click", elem.as_any())

  assert_eq(calls.length(), 1)
}
