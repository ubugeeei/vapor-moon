///|
fn parse_script_setup_generics(
  attrs : Array[BlockAttr],
  filename : String,
) -> Array[GenericParam] raise CompilerError {
  match find_attr_value(attrs, "generic") {
    None => []
    Some(source) => parse_generic_params(source, filename)
  }
}

///|
fn validate_generic_usage(
  generics : Array[GenericParam],
  props : Array[MacroField],
  emits : Array[MacroField],
  slots : Array[MacroField],
  filename : String,
) -> Unit raise CompilerError {
  for generic_ in generics {
    if generic_used_in_fields(generic_.name, props) ||
      generic_used_in_fields(generic_.name, emits) ||
      generic_used_in_fields(generic_.name, slots) {
      continue
    }
    raise CompilerError::InvalidSfc(
      "`generic` parameter \{generic_.name} must appear in defineProps/defineEmits/defineSlot signatures in \{filename}",
    )
  }
}

///|
fn generic_used_in_fields(name : String, fields : Array[MacroField]) -> Bool {
  for field in fields {
    match field.signature {
      Some(signature) if contains_identifier_token(signature, name) =>
        return true
      _ => ()
    }
  }
  false
}

///|
fn parse_generic_params(
  source : String,
  filename : String,
) -> Array[GenericParam] raise CompilerError {
  let trimmed = source.trim().to_string()
  if trimmed.length() == 0 {
    raise CompilerError::InvalidSfc(
      "`generic` must not be empty in \{filename}",
    )
  }
  let result : Array[GenericParam] = []
  for part in split_generic_parts(trimmed) {
    let declaration = part.trim().to_string()
    if declaration.length() == 0 {
      raise CompilerError::InvalidSfc(
        "empty `generic` parameter in \{filename}",
      )
    }
    let name = generic_name_from_declaration(declaration, filename)
    if contains_generic_name(result, name) {
      raise CompilerError::InvalidSfc(
        "duplicate `generic` parameter \{name} in \{filename}",
      )
    }
    result.push({ name, declaration })
  }
  result
}

///|
fn generic_name_from_declaration(
  declaration : String,
  filename : String,
) -> String raise CompilerError {
  let name = match find_top_level_char(declaration, ':') {
    Some(index) =>
      String::unsafe_substring(declaration, start=0, end=index)
      .trim()
      .to_string()
    None => declaration
  }
  if is_identifier_literal(name) {
    name
  } else {
    raise CompilerError::InvalidSfc(
      "invalid `generic` parameter \{declaration} in \{filename}",
    )
  }
}

///|
fn split_generic_parts(source : String) -> Array[String] {
  let parts : Array[String] = []
  let chars = source.to_array()
  let mut start = 0
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    let current = chars[cursor]
    let depths = update_generic_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    if current == ',' &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      parts.push(String::unsafe_substring(source, start~, end=cursor))
      start = cursor + 1
    }
    cursor += 1
  }
  parts.push(String::unsafe_substring(source, start~, end=source.length()))
  parts
}

///|
fn find_top_level_char(source : String, target : Char) -> Int? {
  let chars = source.to_array()
  let mut cursor = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  while cursor < chars.length() {
    let current = chars[cursor]
    if current == target &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      brace_depth == 0 {
      return Some(cursor)
    }
    let depths = update_generic_depths(
      current, paren_depth, bracket_depth, brace_depth,
    )
    paren_depth = depths.0
    bracket_depth = depths.1
    brace_depth = depths.2
    cursor += 1
  }
  None
}

///|
fn update_generic_depths(
  current : Char,
  paren_depth : Int,
  bracket_depth : Int,
  brace_depth : Int,
) -> (Int, Int, Int) {
  match current {
    '(' => (paren_depth + 1, bracket_depth, brace_depth)
    ')' => (dec_depth(paren_depth), bracket_depth, brace_depth)
    '[' => (paren_depth, bracket_depth + 1, brace_depth)
    ']' => (paren_depth, dec_depth(bracket_depth), brace_depth)
    '{' => (paren_depth, bracket_depth, brace_depth + 1)
    '}' => (paren_depth, bracket_depth, dec_depth(brace_depth))
    _ => (paren_depth, bracket_depth, brace_depth)
  }
}

///|
fn dec_depth(value : Int) -> Int {
  if value > 0 {
    value - 1
  } else {
    0
  }
}

///|
fn contains_generic_name(params : Array[GenericParam], target : String) -> Bool {
  for param in params {
    if param.name == target {
      return true
    }
  }
  false
}

///|
fn contains_identifier_token(source : String, target : String) -> Bool {
  let chars = source.to_array()
  let target_chars = target.to_array()
  if target_chars.is_empty() || chars.length() < target_chars.length() {
    return false
  }
  let mut cursor = 0
  while cursor + target_chars.length() <= chars.length() {
    if matches_token_at(chars, target_chars, cursor) {
      return true
    }
    cursor += 1
  }
  false
}

///|
fn matches_token_at(
  chars : Array[Char],
  target : Array[Char],
  start : Int,
) -> Bool {
  for index in 0..<target.length() {
    if chars[start + index] != target[index] {
      return false
    }
  }
  let before_ok = start == 0 || not(is_identifier_char(chars[start - 1]))
  let end_ = start + target.length()
  let after_ok = end_ == chars.length() || not(is_identifier_char(chars[end_]))
  before_ok && after_ok
}

///|
fn is_identifier_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let chars = source.to_array()
  let first = chars[0]
  if not(
      (first >= 'a' && first <= 'z') ||
      (first >= 'A' && first <= 'Z') ||
      first == '_' ||
      first == '$',
    ) {
    return false
  }
  let mut cursor = 1
  while cursor < chars.length() {
    if not(is_identifier_char(chars[cursor])) {
      return false
    }
    cursor += 1
  }
  true
}

///|
fn is_identifier_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '$'
}
