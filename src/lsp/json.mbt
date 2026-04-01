///|
/// Minimal JSON helpers for the Node-backed LSP implementation.

///|
/// Parse JSON text into a JS value while preserving parser errors as strings.
extern "js" fn safe_json_parse(text : String) -> @js.Any =
  #| (text) => {
  #|   try {
  #|     return { ok: true, value: JSON.parse(text) };
  #|   } catch (error) {
  #|     return {
  #|       ok: false,
  #|       message: String(error?.message ?? error),
  #|     };
  #|   }
  #| }

///|
/// Parse JSON text into a JS value.
pub fn parse_json(text : String) -> Result[@js.Any, String] {
  let parsed = safe_json_parse(text)
  let ok : Bool = parsed._get("ok").cast()
  if ok {
    Ok(parsed._get("value"))
  } else {
    Err(parsed._get("message").cast())
  }
}

///|
/// Serialize a JS value to JSON text.
pub fn stringify_json(value : @js.Any) -> String {
  @js.json_stringify(value)
}

///|
/// Return the JavaScript `null` value.
pub fn json_null() -> @js.Any {
  @js.null()
}

///|
/// Build a plain JS object from key/value entries.
pub fn json_object(entries : Array[(String, @js.Any)]) -> @js.Any {
  @js.from_entries(entries).cast()
}

///|
/// Read an object property while treating `undefined` as missing.
pub fn get_prop(obj : @js.Any, key : String) -> @js.Any? {
  let value = obj._get(key)
  if @js.is_undefined(value) {
    None
  } else {
    Some(value)
  }
}

///|
/// Read a string property from an object.
pub fn string_prop(obj : @js.Any, key : String) -> String? {
  match get_prop(obj, key) {
    Some(value) => string_value(value)
    None => None
  }
}

///|
/// Read an integer-like numeric property from an object.
pub fn int_prop(obj : @js.Any, key : String) -> Int? {
  match get_prop(obj, key) {
    Some(value) => int_value(value)
    None => None
  }
}

///|
/// Read a boolean property from an object.
pub fn bool_prop(obj : @js.Any, key : String) -> Bool? {
  match get_prop(obj, key) {
    Some(value) => bool_value(value)
    None => None
  }
}

///|
/// Read an object-valued property from an object.
pub fn object_prop(obj : @js.Any, key : String) -> @js.Any? {
  match get_prop(obj, key) {
    Some(value) => object_value(value)
    None => None
  }
}

///|
/// Read an array-valued property from an object.
pub fn array_prop(obj : @js.Any, key : String) -> Array[@js.Any]? {
  match get_prop(obj, key) {
    Some(value) => array_value(value)
    None => None
  }
}

///|
/// Narrow a JS value to a string.
pub fn string_value(value : @js.Any) -> String? {
  if @js.typeof_(value) == "string" {
    Some(value.cast())
  } else {
    None
  }
}

///|
/// Narrow a JS value to a number cast as `Int`.
pub fn int_value(value : @js.Any) -> Int? {
  if @js.typeof_(value) == "number" {
    Some(value.cast())
  } else {
    None
  }
}

///|
/// Narrow a JS value to a boolean.
pub fn bool_value(value : @js.Any) -> Bool? {
  if @js.typeof_(value) == "boolean" {
    Some(value.cast())
  } else {
    None
  }
}

///|
/// Narrow a JS value to an object.
pub fn object_value(value : @js.Any) -> @js.Any? {
  if @js.is_object(value) {
    Some(value)
  } else {
    None
  }
}

///|
/// Narrow a JS value to an array.
pub fn array_value(value : @js.Any) -> Array[@js.Any]? {
  if @js.is_array(value) {
    Some(value.cast())
  } else {
    None
  }
}
