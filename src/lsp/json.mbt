///|
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
pub fn stringify_json(value : @js.Any) -> String {
  @js.json_stringify(value)
}

///|
pub fn json_null() -> @js.Any {
  @js.null()
}

///|
pub fn json_object(entries : Array[(String, @js.Any)]) -> @js.Any {
  @js.from_entries(entries).cast()
}

///|
pub fn get_prop(obj : @js.Any, key : String) -> @js.Any? {
  let value = obj._get(key)
  if @js.is_undefined(value) {
    None
  } else {
    Some(value)
  }
}

///|
pub fn string_prop(obj : @js.Any, key : String) -> String? {
  match get_prop(obj, key) {
    Some(value) => string_value(value)
    None => None
  }
}

///|
pub fn int_prop(obj : @js.Any, key : String) -> Int? {
  match get_prop(obj, key) {
    Some(value) => int_value(value)
    None => None
  }
}

///|
pub fn object_prop(obj : @js.Any, key : String) -> @js.Any? {
  match get_prop(obj, key) {
    Some(value) => object_value(value)
    None => None
  }
}

///|
pub fn array_prop(obj : @js.Any, key : String) -> Array[@js.Any]? {
  match get_prop(obj, key) {
    Some(value) => array_value(value)
    None => None
  }
}

///|
pub fn string_value(value : @js.Any) -> String? {
  if @js.typeof_(value) == "string" {
    Some(value.cast())
  } else {
    None
  }
}

///|
pub fn int_value(value : @js.Any) -> Int? {
  if @js.typeof_(value) == "number" {
    Some(value.cast())
  } else {
    None
  }
}

///|
pub fn object_value(value : @js.Any) -> @js.Any? {
  if @js.is_object(value) {
    Some(value)
  } else {
    None
  }
}

///|
pub fn array_value(value : @js.Any) -> Array[@js.Any]? {
  if @js.is_array(value) {
    Some(value.cast())
  } else {
    None
  }
}
