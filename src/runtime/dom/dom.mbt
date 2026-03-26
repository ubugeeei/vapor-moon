///|
/// Small luna DOM wrappers used by generated Vapor Moon client code.

///|
pub fn element(tag : String) -> @js_dom.Element {
  @js_dom.document().createElement(tag)
}

///|
pub fn el(tag : String) -> @js_dom.Element {
  element(tag)
}

///|
pub fn to_node(elem : @js_dom.Element) -> @luna_dom.DomNode {
  @luna_dom.dom_node(elem)
}

///|
pub fn into(elem : @js_dom.Element) -> @luna_dom.DomNode {
  to_node(elem)
}

///|
pub fn append_child(node : @js_dom.Node, child : @luna_dom.DomNode) -> Unit {
  node.appendChild(child.to_dom()) |> ignore
}

///|
pub fn append(node : @js_dom.Node, child : @luna_dom.DomNode) -> Unit {
  append_child(node, child)
}

///|
pub fn append_children(
  node : @js_dom.Node,
  children : Array[@luna_dom.DomNode],
) -> Unit {
  for child in children {
    append_child(node, child)
  }
}

///|
pub fn apply_attrs(
  elem : @js_dom.Element,
  attrs : Array[(String, @luna_dom.AttrValue)],
) -> Unit {
  for attr in attrs {
    apply_attr_entry(elem, attr)
  }
}

///|
pub fn apply_attr_entry(
  elem : @js_dom.Element,
  attr : (String, @luna_dom.AttrValue),
) -> Unit {
  apply_attr(elem, attr.0, attr.1)
}

///|
pub fn setAttr(
  elem : @js_dom.Element,
  attr : (String, @luna_dom.AttrValue),
) -> Unit {
  apply_attr_entry(elem, attr)
}

///|
pub fn text(content : String) -> @luna_dom.DomNode {
  @luna_dom.dom_node(@js_dom.document().createTextNode(content))
}

///|
pub fn text_expr(content : () -> String) -> @luna_dom.DomNode {
  let node = text("")
  setText(node, content)
  node
}

///|
pub fn setText(node : @luna_dom.DomNode, content : () -> String) -> Unit {
  let text_node = node.to_dom()
  text_node.setTextContent(content())
  let _ = @resource.render_effect(fn() { text_node.setTextContent(content()) })
}

///|
pub fn fragment(children : Array[@luna_dom.DomNode]) -> @luna_dom.DomNode {
  match children.length() {
    0 =>
      @luna_dom.dom_node(@js_dom.document().createDocumentFragment().as_node())
    1 => children[0]
    _ => {
      let frag = @js_dom.document().createDocumentFragment()
      for child in children {
        frag.as_node().appendChild(child.to_dom()) |> ignore
      }
      @luna_dom.dom_node(frag.as_node())
    }
  }
}

///|
pub fn frag(children : Array[@luna_dom.DomNode]) -> @luna_dom.DomNode {
  fragment(children)
}

///|
pub fn show(
  when : () -> Bool,
  render_fn : () -> @luna_dom.DomNode,
) -> @luna_dom.DomNode {
  @luna_dom.show(when, render_fn)
}

///|
pub fn[T] for_each(
  items : () -> Array[T],
  render_item : (T, Int) -> @luna_dom.DomNode,
) -> @luna_dom.DomNode {
  @luna_dom.for_each(items, render_item)
}

///|
pub fn[T] each(
  items : () -> Array[T],
  render_item : (T, Int) -> @luna_dom.DomNode,
) -> @luna_dom.DomNode {
  for_each(items, render_item)
}

///|
pub fn attr_static(value : String) -> @luna_dom.AttrValue {
  @luna_dom.attr_static(value)
}

///|
pub fn attr(value : String) -> @luna_dom.AttrValue {
  attr_static(value)
}

///|
pub fn attr_dynamic(getter : () -> String) -> @luna_dom.AttrValue {
  @luna_dom.attr_dynamic(getter)
}

///|
pub fn dynAttr(getter : () -> String) -> @luna_dom.AttrValue {
  attr_dynamic(getter)
}

///|
pub fn attr_handler(handler : (@js.Any) -> Unit) -> @luna_dom.AttrValue {
  @luna_dom.attr_handler(handler)
}

///|
extern "js" fn attach_event_modifiers(
  handler : (@js.Any) -> Unit,
  modifiers : Array[String],
) -> (@js.Any) -> Unit =
  #| (handler, modifiers) => {
  #|   handler.__vaporMoonModifiers = modifiers.slice();
  #|   return handler;
  #| }

///|
pub fn attr_handler_with_modifiers(
  handler : (@js.Any) -> Unit,
  modifiers : Array[String],
) -> @luna_dom.AttrValue {
  @luna_dom.attr_handler(attach_event_modifiers(handler, modifiers))
}

///|
pub fn on(handler : (@js.Any) -> Unit) -> @luna_dom.AttrValue {
  attr_handler(handler)
}

///|
pub fn onWith(
  handler : (@js.Any) -> Unit,
  modifiers : Array[String],
) -> @luna_dom.AttrValue {
  attr_handler_with_modifiers(handler, modifiers)
}

///|
pub fn attr_style(style : String) -> @luna_dom.AttrValue {
  @luna_dom.attr_style(style)
}

///|
pub fn style(value : String) -> @luna_dom.AttrValue {
  attr_style(value)
}

///|
pub fn attr_dynamic_style(getter : () -> String) -> @luna_dom.AttrValue {
  @luna_dom.attr_dynamic_style(getter)
}

///|
pub fn dynStyle(getter : () -> String) -> @luna_dom.AttrValue {
  attr_dynamic_style(getter)
}

///|
pub fn component_dom(
  name : String,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
) -> @luna_dom.DomNode {
  component_dom_meta(name, props, children, [])
}

///|
pub fn component_dom_meta(
  name : String,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
  meta_attrs : Array[(String, @luna_dom.AttrValue)],
) -> @luna_dom.DomNode {
  let attrs : Array[(String, @luna_dom.AttrValue)] = [
    ("data-vm-component", attr_static(name)),
  ]
  for prop in props {
    attrs.push(("data-prop-" + prop.0, attr_dynamic(prop.1)))
  }
  for attr in meta_attrs {
    attrs.push(attr)
  }
  let elem = element("vm-component")
  apply_attrs(elem, attrs)
  append_children(elem.as_node(), children)
  to_node(elem)
}

///|
pub fn component(
  name : String,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
) -> @luna_dom.DomNode {
  component_dom(name, props, children)
}

///|
pub fn componentMeta(
  name : String,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
  meta_attrs : Array[(String, @luna_dom.AttrValue)],
) -> @luna_dom.DomNode {
  component_dom_meta(name, props, children, meta_attrs)
}

///|
pub fn island_dom(
  name : String,
  mode : @vm.HydrationMode,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
) -> @luna_dom.DomNode {
  island_dom_meta(name, mode, props, children, [])
}

///|
pub fn island_dom_meta(
  name : String,
  mode : @vm.HydrationMode,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
  meta_attrs : Array[(String, @luna_dom.AttrValue)],
) -> @luna_dom.DomNode {
  let attrs : Array[(String, @luna_dom.AttrValue)] = [
    ("data-vm-island", attr_static(name)),
    ("data-vm-client", attr_static(render_mode_label(mode))),
    ("data-vm-url", attr_static(@vm.client_module_path(name))),
  ]
  for prop in props {
    attrs.push(("data-prop-" + prop.0, attr_dynamic(prop.1)))
  }
  for attr in meta_attrs {
    attrs.push(attr)
  }
  let elem = element("vm-island")
  apply_attrs(elem, attrs)
  append_children(elem.as_node(), children)
  to_node(elem)
}

///|
pub fn island(
  name : String,
  mode : @vm.HydrationMode,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
) -> @luna_dom.DomNode {
  island_dom(name, mode, props, children)
}

///|
pub fn islandMeta(
  name : String,
  mode : @vm.HydrationMode,
  props : Array[(String, () -> String)],
  children : Array[@luna_dom.DomNode],
  meta_attrs : Array[(String, @luna_dom.AttrValue)],
) -> @luna_dom.DomNode {
  island_dom_meta(name, mode, props, children, meta_attrs)
}

///|
extern "js" fn register_template_ref(name : String, target : @js.Any) -> Unit =
  #| (name, target) => {
  #|   globalThis.__vaporMoonTemplateRefs ??= new Map();
  #|   globalThis.__vaporMoonTemplateRefs.set(name, target);
  #| }

///|
extern "js" fn lookup_template_ref(name : String) -> @js.Any =
  #| (name) => globalThis.__vaporMoonTemplateRefs?.get(name) ?? undefined

///|
extern "js" fn register_bound_template_ref(
  ref_ : @js.Any,
  target : @js.Any,
) -> Unit =
  #| (ref_, target) => {
  #|   globalThis.__vaporMoonBoundTemplateRefs ??= new WeakMap();
  #|   globalThis.__vaporMoonBoundTemplateRefs.set(ref_, target);
  #| }

///|
extern "js" fn lookup_bound_template_ref(ref_ : @js.Any) -> @js.Any =
  #| (ref_) => globalThis.__vaporMoonBoundTemplateRefs?.get(ref_) ?? undefined

///|
pub fn bind_template_ref_name(name : String, target : @js.Any) -> Unit {
  register_template_ref(name, target)
}

///|
pub fn bindRefName(name : String, target : @js.Any) -> Unit {
  bind_template_ref_name(name, target)
}

///|
pub fn[T] bind_template_ref(
  ref_ : @vm.TemplateRef[T],
  target : @js.Any,
) -> Unit {
  register_bound_template_ref(@js.any(ref_), target)
}

///|
pub fn[T] bindRef(ref_ : @vm.TemplateRef[T], target : @js.Any) -> Unit {
  bind_template_ref(ref_, target)
}

///|
pub fn[T] resolve_template_ref(ref_ : @vm.TemplateRef[T]) -> T? {
  let bound_target = lookup_bound_template_ref(@js.any(ref_))
  if not(@js.is_nullish(bound_target)) {
    return Some(bound_target.cast())
  }
  let named_target = lookup_template_ref(ref_.name())
  if @js.is_nullish(named_target) {
    None
  } else {
    Some(named_target.cast())
  }
}

///|
pub fn apply_attr(
  elem : @js_dom.Element,
  name : String,
  value : @luna_dom.AttrValue,
) -> Unit {
  match value {
    @luna_dom.Static(content) =>
      if name == "style" {
        elem.setAttribute("style", content)
      } else {
        apply_static_attr(elem, name, content)
      }
    @luna_dom.Dynamic(getter) => {
      let _ = @resource.render_effect(fn() {
        let content = getter()
        if name == "style" {
          elem.setAttribute("style", content)
        } else {
          apply_static_attr(elem, name, content)
        }
      })
    }
    @luna_dom.Handler(handler) =>
      if name == "__ref" {
        handler(elem.as_any())
      } else {
        bind_event_handler(elem, name, handler)
      }
  }
}

///|
fn apply_static_attr(
  elem : @js_dom.Element,
  name : String,
  value : String,
) -> Unit {
  if name == "className" || name == "class" {
    elem.setClassName(value)
  } else if name == "__innerHTML" {
    elem.as_any()._set("innerHTML", @js.any(value)) |> ignore
  } else if name == "value" {
    elem.as_any()._set("value", @js.any(value)) |> ignore
  } else if name == "checked" {
    elem.as_any()._set("checked", @js.any(value == "true" || value == ""))
    |> ignore
  } else if name == "disabled" {
    if value == "true" || value == "" {
      elem.setAttribute("disabled", "")
    } else {
      elem.removeAttribute("disabled")
    }
  } else {
    elem.setAttribute(name, value)
  }
}

///|
extern "js" fn bind_event_handler(
  elem : @js_dom.Element,
  name : String,
  handler : (@js.Any) -> Unit,
) -> Unit =
  #| (elem, name, handler) => {
  #|   const runtime = globalThis.__vaporMoonEventDelegator ??= (() => {
  #|     const direct = new Set([
  #|       "error",
  #|       "load",
  #|       "mouseenter",
  #|       "mouseleave",
  #|       "pointerenter",
  #|       "pointerleave",
  #|       "scroll",
  #|       "unload",
  #|     ]);
  #|     const capture = new Set(["blur", "focus"]);
  #|     const docs = new WeakMap();
  #|     const storeKey = "__vaporMoonHandlers";
  #|     const modifierKey = "__vaporMoonModifiers";
  #|     const normalizeTarget = (target) => {
  #|       if (target && target.nodeType === 3) {
  #|         return target.parentNode;
  #|       }
  #|       return target;
  #|     };
  #|     const wrapEvent = (event, currentTarget) =>
  #|       new Proxy(event, {
  #|         get(target, prop) {
  #|           if (prop === "currentTarget" || prop === "delegateTarget") {
  #|             return currentTarget;
  #|           }
  #|           if (prop === "nativeEvent") {
  #|             return target;
  #|           }
  #|           const value = Reflect.get(target, prop, target);
  #|           return typeof value === "function" ? value.bind(target) : value;
  #|         },
  #|       });
  #|     const handlerModifiers = (handler) => {
  #|       if (!handler || !Array.isArray(handler[modifierKey])) {
  #|         return [];
  #|       }
  #|       return handler[modifierKey].slice();
  #|     };
  #|     const listenerOptions = (modifiers) => {
  #|       let options = null;
  #|       for (const modifier of modifiers) {
  #|         if (modifier !== "capture" && modifier !== "once" && modifier !== "passive") {
  #|           continue;
  #|         }
  #|         options ??= {};
  #|         options[modifier] = true;
  #|       }
  #|       return options;
  #|     };
  #|     const runHandler = (handler, modifiers, event, currentTarget) => {
  #|       const wrapped = wrapEvent(event, currentTarget);
  #|       const target = normalizeTarget(wrapped.target);
  #|       for (const modifier of modifiers) {
  #|         if (modifier === "stop") {
  #|           wrapped.stopPropagation();
  #|         } else if (modifier === "prevent") {
  #|           wrapped.preventDefault?.();
  #|         } else if (modifier === "self") {
  #|           if (target !== currentTarget) {
  #|             return;
  #|           }
  #|         }
  #|       }
  #|       handler(wrapped);
  #|     };
  #|     const dispatch = (name, event) => {
  #|       let current = normalizeTarget(event.target);
  #|       while (current) {
  #|         const candidate = current[storeKey]?.[name];
  #|         if (candidate) {
  #|           runHandler(candidate.handler, candidate.modifiers, event, current);
  #|           if (event.cancelBubble) {
  #|             return;
  #|           }
  #|         }
  #|         current = current.parentNode || current.host || null;
  #|       }
  #|     };
  #|     return {
  #|       direct,
  #|       capture,
  #|       docs,
  #|       storeKey,
  #|       dispatch,
  #|       handlerModifiers,
  #|       listenerOptions,
  #|       runHandler,
  #|     };
  #|   })();
  #|
  #|   const modifiers = runtime.handlerModifiers(handler);
  #|   const options = runtime.listenerOptions(modifiers);
  #|   const bindDirect = runtime.direct.has(name) || options !== null;
  #|
  #|   if (bindDirect) {
  #|     const listener = (event) => runtime.runHandler(handler, modifiers, event, elem);
  #|     elem.addEventListener(name, listener, options ?? false);
  #|     return;
  #|   }
  #|
  #|   const doc = elem.ownerDocument ?? globalThis.document;
  #|   if (!doc) {
  #|     const listener = (event) => runtime.runHandler(handler, modifiers, event, elem);
  #|     elem.addEventListener(name, listener, options ?? false);
  #|     return;
  #|   }
  #|
  #|   const store = elem[runtime.storeKey] ??= Object.create(null);
  #|   store[name] = { handler, modifiers };
  #|
  #|   let listeners = runtime.docs.get(doc);
  #|   if (!listeners) {
  #|     listeners = new Map();
  #|     runtime.docs.set(doc, listeners);
  #|   }
  #|
  #|   if (listeners.has(name)) {
  #|     return;
  #|   }
  #|
  #|   const listener = (event) => runtime.dispatch(name, event);
  #|   doc.addEventListener(name, listener, runtime.capture.has(name));
  #|   listeners.set(name, listener);
  #| }

///|
fn render_mode_label(mode : @vm.HydrationMode) -> String {
  match mode {
    Manual => "manual"
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:" + query
    Only => "only"
    ServerDefer => "server-defer"
  }
}
