///|
/// SSR helpers layered on top of luna islands and HTML rendering.

///|
pub fn component_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
) -> @luna_core.StaticDomNode {
  component_ssr_meta(name, props_json, children, [])
}

///|
pub fn component_ssr_meta(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  meta_attrs : Array[(String, @luna_core.AttrValue)],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.AttrValue)] = [
    ("data-vm-component", @luna_core.attr_static(name)),
    ("data-vm-props", @luna_core.attr_static(props_json)),
  ]
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_core.h("vm-component", attrs, children)
}

///|
pub fn island_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  mode : @vm.HydrationMode,
) -> @luna_core.StaticDomNode {
  island_ssr_meta(name, props_json, children, mode, [])
}

///|
pub fn island_ssr_meta(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  mode : @vm.HydrationMode,
  meta_attrs : Array[(String, @luna_core.AttrValue)],
) -> @luna_core.StaticDomNode {
  match mode {
    Only => island_only_ssr(name, props_json, meta_attrs)
    ServerDefer => island_defer_ssr(name, props_json, children, meta_attrs)
    _ =>
      @luna_core.island(
        island_id(name, props_json),
        @vm.client_module_path(name),
        props_json,
        children,
        trigger=to_luna_trigger(mode),
      )
  }
}

///|
fn island_only_ssr(
  name : String,
  props_json : String,
  meta_attrs : Array[(String, @luna_core.AttrValue)],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.AttrValue)] = [
    ("data-vm-island", @luna_core.attr_static(name)),
    ("data-vm-client", @luna_core.attr_static("only")),
    ("data-vm-props", @luna_core.attr_static(props_json)),
  ]
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_core.h("vm-island", attrs, [])
}

///|
fn island_defer_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  meta_attrs : Array[(String, @luna_core.AttrValue)],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.AttrValue)] = [
    ("data-vm-component", @luna_core.attr_static(name)),
    ("data-vm-props", @luna_core.attr_static(props_json)),
  ]
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_core.h("vm-server-defer", attrs, children)
}

///|
pub fn render_html(node : @luna_core.StaticDomNode) -> String {
  @render.render_to_string(node).html
}

///|
fn to_luna_trigger(mode : @vm.HydrationMode) -> @luna_core.Trigger {
  match mode {
    Load => @luna_core.Load
    Idle => @luna_core.Idle
    Visible => @luna_core.Visible
    Media(query) => @luna_core.Media(query)
    _ => @luna_core.None
  }
}

///|
fn island_id(name : String, props_json : String) -> String {
  "vm-island-" + hash_string(name + ":" + props_json)
}

///|
fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}
