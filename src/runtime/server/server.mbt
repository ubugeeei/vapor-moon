///|
/// SSR helpers layered on top of luna islands and HTML rendering.

///|
pub fn component_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
) -> @luna_core.StaticDomNode {
  @luna_core.h(
    "vm-component",
    [
      ("data-vm-component", @luna_core.attr_static(name)),
      ("data-vm-props", @luna_core.attr_static(props_json)),
    ],
    children,
  )
}

///|
pub fn island_ssr(
  name : String,
  props_json : String,
  children : Array[@luna_core.StaticDomNode],
  mode : @vm.HydrationMode,
) -> @luna_core.StaticDomNode {
  match mode {
    Only =>
      @luna_core.h(
        "vm-island",
        [
          ("data-vm-island", @luna_core.attr_static(name)),
          ("data-vm-client", @luna_core.attr_static("only")),
          ("data-vm-props", @luna_core.attr_static(props_json)),
        ],
        [],
      )
    ServerDefer =>
      @luna_core.h(
        "vm-server-defer",
        [
          ("data-vm-component", @luna_core.attr_static(name)),
          ("data-vm-props", @luna_core.attr_static(props_json)),
        ],
        children,
      )
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
