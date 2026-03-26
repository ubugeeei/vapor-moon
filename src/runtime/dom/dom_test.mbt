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
  #| (doc, label, parent) => {
  #|   const parentNode =
  #|     parent && typeof parent === "object" && "$tag" in parent
  #|       ? (parent.$tag === 1 ? parent._0 : null)
  #|       : (parent ?? null);
  #|   return ({
  #|   label,
  #|   ownerDocument: doc,
  #|   parentNode,
  #|   listeners: Object.create(null),
  #|   addEventListener(name, handler, options = false) {
  #|     (this.listeners[name] ??= []).push({ handler, options });
  #|   },
  #|   });
  #| }

///|
extern "js" fn install_fake_dom() -> Unit =
  #| () => {
  #|   const makeNode = (nodeType, label, ownerDocument) => ({
  #|     nodeType,
  #|     label,
  #|     tagName: label,
  #|     ownerDocument,
  #|     parentNode: null,
  #|     children: [],
  #|     attributes: Object.create(null),
  #|     listeners: Object.create(null),
  #|     className: "",
  #|     textContent: "",
  #|     appendChild(child) {
  #|       child.parentNode = this;
  #|       this.children.push(child);
  #|       return child;
  #|     },
  #|     addEventListener(name, handler, options = false) {
  #|       (this.listeners[name] ??= []).push({ handler, options });
  #|     },
  #|     setAttribute(name, value) {
  #|       const text = String(value);
  #|       this.attributes[name] = text;
  #|       if (name === "class") {
  #|         this.className = text;
  #|       }
  #|     },
  #|     removeAttribute(name) {
  #|       delete this.attributes[name];
  #|     },
  #|     setClassName(value) {
  #|       const text = String(value);
  #|       this.className = text;
  #|       this.attributes.class = text;
  #|     },
  #|     setTextContent(value) {
  #|       this.textContent = String(value);
  #|     },
  #|   });
  #|   const doc = {
  #|     listeners: Object.create(null),
  #|     addEventListener(name, handler, options = false) {
  #|       (this.listeners[name] ??= []).push({ handler, options });
  #|     },
  #|     createElement(tag) {
  #|       return makeNode(1, tag, doc);
  #|     },
  #|     createTextNode(content) {
  #|       const node = makeNode(3, "#text", doc);
  #|       node.textContent = String(content);
  #|       return node;
  #|     },
  #|     createDocumentFragment() {
  #|       return makeNode(11, "#fragment", doc);
  #|     },
  #|   };
  #|   globalThis.document = doc;
  #|   delete globalThis.__vaporMoonEventDelegator;
  #|   delete globalThis.__vaporMoonTemplateRefs;
  #|   delete globalThis.__vaporMoonBoundTemplateRefs;
  #| }

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
extern "js" fn node_tag(node : @js.Any) -> String =
  #| (node) => node.tagName ?? node.label ?? ""

///|
extern "js" fn node_attr(node : @js.Any, name : String) -> String =
  #| (node, name) => String(node.attributes?.[name] ?? (name === "class" ? node.className : "") ?? "")

///|
extern "js" fn node_has_attr(node : @js.Any, name : String) -> Bool =
  #| (node, name) => Object.prototype.hasOwnProperty.call(node.attributes ?? {}, name)

///|
extern "js" fn node_prop_string(node : @js.Any, name : String) -> String =
  #| (node, name) => String(node?.[name] ?? "")

///|
extern "js" fn node_prop_bool(node : @js.Any, name : String) -> Bool =
  #| (node, name) => Boolean(node?.[name])

///|
extern "js" fn node_child_count(node : @js.Any) -> Int =
  #| (node) => node.children?.length ?? 0

///|
extern "js" fn node_child_text(node : @js.Any, index : Int) -> String =
  #| (node, index) => String(node.children?.[index]?.textContent ?? "")

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
  let first_ref : @vm.TemplateRef[@js_dom.Element] = @vm.use_template_ref(
    "shared",
  )
  let second_ref : @vm.TemplateRef[@js_dom.Element] = @vm.use_template_ref(
    "shared",
  )

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
  let ref_ : @vm.TemplateRef[@js_dom.Element] = @vm.use_template_ref("legacy")

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
    attr_handler_with_modifiers(fn(_event) { calls.push(1) }, [
      "capture", "once", "passive",
    ]),
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

///|
test "component dom meta renders wrapper attrs and children" {
  install_fake_dom()
  let node = component_dom_meta(
    "Panel",
    [("title", fn() { "hello" })],
    [text("slot")],
    [("data-extra", attr_static("yes"))],
  )
  let elem = node.to_dom()

  assert_eq(node_tag(elem.as_any()), "vm-component")
  assert_eq(node_attr(elem.as_any(), "data-vm-component"), "Panel")
  assert_eq(node_attr(elem.as_any(), "data-prop-title"), "hello")
  assert_eq(node_attr(elem.as_any(), "data-extra"), "yes")
  assert_eq(node_child_count(elem.as_any()), 1)
  assert_eq(node_child_text(elem.as_any(), 0), "slot")
}

///|
test "island dom meta renders hydration metadata and children" {
  install_fake_dom()
  let node = island_dom_meta(
    "Hero Banner",
    @vm.HydrationMode::Media("(max-width: 768px)"),
    [("count", fn() { "2" })],
    [text("fallback")],
    [("data-extra", attr_static("yes"))],
  )
  let elem = node.to_dom()

  assert_eq(node_tag(elem.as_any()), "vm-island")
  assert_eq(node_attr(elem.as_any(), "data-vm-island"), "Hero Banner")
  assert_eq(
    node_attr(elem.as_any(), "data-vm-client"),
    "media:(max-width: 768px)",
  )
  assert_eq(
    node_attr(elem.as_any(), "data-vm-url"),
    @vm.client_module_path("Hero Banner"),
  )
  assert_eq(node_attr(elem.as_any(), "data-prop-count"), "2")
  assert_eq(node_attr(elem.as_any(), "data-extra"), "yes")
  assert_eq(node_child_text(elem.as_any(), 0), "fallback")
}

///|
test "apply_attr handles special attribute names and refs" {
  install_fake_dom()
  let elem = element("input")
  let refs : Array[String] = []

  apply_attr(elem, "class", attr_static("field"))
  apply_attr(elem, "value", attr_static("hello"))
  apply_attr(elem, "checked", attr_static("true"))
  apply_attr(elem, "disabled", attr_static("true"))
  apply_attr(elem, "__innerHTML", attr_static("<b>ok</b>"))
  apply_attr(
    elem,
    "__ref",
    attr_handler(fn(target) { refs.push(node_tag(target)) }),
  )

  assert_eq(node_attr(elem.as_any(), "class"), "field")
  assert_eq(node_prop_string(elem.as_any(), "value"), "hello")
  assert_true(node_prop_bool(elem.as_any(), "checked"))
  assert_true(node_has_attr(elem.as_any(), "disabled"))
  assert_eq(node_prop_string(elem.as_any(), "innerHTML"), "<b>ok</b>")
  assert_eq(refs, ["input"])

  apply_attr(elem, "disabled", attr_static("false"))
  apply_attr(elem, "checked", attr_static("false"))

  assert_false(node_has_attr(elem.as_any(), "disabled"))
  assert_false(node_prop_bool(elem.as_any(), "checked"))
}
