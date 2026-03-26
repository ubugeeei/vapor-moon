///|
/// SSR helpers layered on top of luna islands and HTML rendering.

///|
/// Render a component placeholder node for server output.
pub fn component_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
) -> @luna_core.StaticDomNode {
  component_ssr_meta(name, props_json, children, [])
}

///|
/// Render a component placeholder node with extra metadata attributes.
pub fn component_ssr_meta(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  meta_attrs : Array[(String, @luna_core.Attr[Unit, String])],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.Attr[Unit, String])] = [
    ("data-vm-component", @luna_core.attr_static(name)),
    ("data-vm-props", @luna_core.attr_static(props_json)),
  ]
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_core.h("vm-component", attrs, children)
}

///|
/// Render an island shell for the requested hydration mode.
pub fn island_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  mode : @vm.HydrationMode,
) -> @luna_core.StaticDomNode {
  island_ssr_meta(name, props_json, children, mode, [])
}

///|
/// Render an island shell with extra metadata attributes.
pub fn island_ssr_meta(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  mode : @vm.HydrationMode,
  meta_attrs : Array[(String, @luna_core.Attr[Unit, String])],
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
/// Render a client-only island marker with no SSR children.
fn island_only_ssr(
  name : String,
  props_json : String,
  meta_attrs : Array[(String, @luna_core.Attr[Unit, String])],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.Attr[Unit, String])] = [
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
/// Render the server-deferred shell that preserves SSR children.
fn island_defer_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  meta_attrs : Array[(String, @luna_core.Attr[Unit, String])],
) -> @luna_core.StaticDomNode {
  let attrs : Array[(String, @luna_core.Attr[Unit, String])] = [
    ("data-vm-component", @luna_core.attr_static(name)),
    ("data-vm-props", @luna_core.attr_static(props_json)),
  ]
  for attr in meta_attrs {
    attrs.push(attr)
  }
  @luna_core.h("vm-server-defer", attrs, children)
}

///|
/// Convert a Luna static DOM tree into HTML.
pub fn render_html(node : @luna_core.StaticDomNode) -> String {
  @render.render_to_string(node).html
}

///|
/// Map Vapor Moon hydration modes to Luna island triggers.
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
/// Build a deterministic island id from component name and serialized props.
fn island_id(name : String, props_json : String) -> String {
  "vm-island-" + hash_string(name + ":" + props_json)
}

///|
/// Shared string hash used for SSR island ids.
fn hash_string(source : String) -> String {
  let mut hash : UInt = 5381
  for ch in source {
    hash = (hash << 5) + hash + ch.to_uint()
  }
  hash.to_string()
}
