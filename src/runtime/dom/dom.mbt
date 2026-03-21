///|
/// Small luna DOM wrappers used by generated Vapor Moon client code.

///|
pub fn element(tag : String) -> @js_dom.Element {
  @js_dom.document().createElement(tag)
}

///|
pub fn to_node(elem : @js_dom.Element) -> @luna_dom.DomNode {
  @luna_dom.dom_node(elem)
}

///|
pub fn append_child(node : @js_dom.Node, child : @luna_dom.DomNode) -> Unit {
  node.appendChild(child.to_dom()) |> ignore
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
pub fn text(content : String) -> @luna_dom.DomNode {
  @luna_dom.dom_node(@js_dom.document().createTextNode(content))
}

///|
pub fn text_expr(content : () -> String) -> @luna_dom.DomNode {
  let doc = @js_dom.document()
  let node = doc.createTextNode(content())
  let _ = @resource.render_effect(fn() {
    node.as_node().setTextContent(content())
  })
  @luna_dom.dom_node(node)
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
pub fn attr_static(value : String) -> @luna_dom.AttrValue {
  @luna_dom.attr_static(value)
}

///|
pub fn attr_dynamic(getter : () -> String) -> @luna_dom.AttrValue {
  @luna_dom.attr_dynamic(getter)
}

///|
pub fn attr_handler(handler : (@js.Any) -> Unit) -> @luna_dom.AttrValue {
  @luna_dom.attr_handler(handler)
}

///|
pub fn attr_style(style : String) -> @luna_dom.AttrValue {
  @luna_dom.attr_style(style)
}

///|
pub fn attr_dynamic_style(getter : () -> String) -> @luna_dom.AttrValue {
  @luna_dom.attr_dynamic_style(getter)
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
  append_children(elem, children)
  to_node(elem)
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
  append_children(elem, children)
  to_node(elem)
}

///|
extern "js" fn register_template_ref(name : String, target : @js.Any) -> Unit =
  #| (name, target) => {
  #|   globalThis.__vaporMoonTemplateRefs ??= new Map();
  #|   globalThis.__vaporMoonTemplateRefs.set(name, target);
  #| }

///|
extern "js" fn lookup_template_ref(name : String) -> @js.Any? =
  #| (name) => globalThis.__vaporMoonTemplateRefs?.get(name) ?? null

///|
pub fn bind_template_ref(name : String, target : @js.Any) -> Unit {
  register_template_ref(name, target)
}

///|
pub fn resolve_template_ref(ref_ : @vm.TemplateRef) -> @js.Any? {
  lookup_template_ref(ref_.name())
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
  #|(elem, name, handler) => elem.addEventListener(name, handler)

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
