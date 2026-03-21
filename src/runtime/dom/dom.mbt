///|
/// Small luna DOM wrappers used by generated Vapor Moon client code.

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
    ("data-vm-component", @luna_dom.attr_static(name)),
  ]
  for prop in props {
    attrs.push(("data-prop-" + prop.0, @luna_dom.attr_dynamic(prop.1)))
  }
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_dom.create_element("vm-component", attrs, children)
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
    ("data-vm-island", @luna_dom.attr_static(name)),
    ("data-vm-client", @luna_dom.attr_static(render_mode_label(mode))),
    ("data-vm-url", @luna_dom.attr_static(@vm.client_module_path(name))),
  ]
  for prop in props {
    attrs.push(("data-prop-" + prop.0, @luna_dom.attr_dynamic(prop.1)))
  }
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_dom.create_element("vm-island", attrs, children)
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
