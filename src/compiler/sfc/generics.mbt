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
    if field_references_type_identifier(field, name) {
      return true
    }
  }
  false
}

///|
fn field_references_type_identifier(
  field : MacroField,
  target : String,
) -> Bool {
  for identifier in field.type_identifiers {
    if identifier == target {
      return true
    }
  }
  false
}

///|
fn parse_generic_params(
  source : String,
  filename : String,
) -> Array[GenericParam] raise CompilerError {
  if source.trim().is_empty() {
    raise CompilerError::InvalidSfc(
      "`generic` must not be empty in \{filename}",
    )
  }
  let trimmed = source.trim().to_string()
  validate_generic_syntax(trimmed, filename)
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
fn validate_generic_syntax(
  source : String,
  filename : String,
) -> Unit raise CompilerError {
  let chars = source.to_array()
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut brace_depth = 0
  for current in chars {
    match current {
      '(' => paren_depth += 1
      ')' => {
        if paren_depth == 0 {
          raise_invalid_generic_syntax(source, filename)
        }
        paren_depth = paren_depth - 1
      }
      '[' => bracket_depth += 1
      ']' => {
        if bracket_depth == 0 {
          raise_invalid_generic_syntax(source, filename)
        }
        bracket_depth = bracket_depth - 1
      }
      '{' => brace_depth += 1
      '}' => {
        if brace_depth == 0 {
          raise_invalid_generic_syntax(source, filename)
        }
        brace_depth = brace_depth - 1
      }
      _ => ()
    }
  }
  if paren_depth != 0 || bracket_depth != 0 || brace_depth != 0 {
    raise_invalid_generic_syntax(source, filename)
  }
}

///|
fn raise_invalid_generic_syntax(
  source : String,
  filename : String,
) -> Unit raise CompilerError {
  raise CompilerError::InvalidSfc(
    "invalid `generic` declaration `\{source}` in \{filename}",
  )
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
fn is_identifier_literal(source : String) -> Bool {
  if source.length() == 0 {
    return false
  }
  let first = source[0].to_int()
  if not(
      (first >= 'a'.to_int() && first <= 'z'.to_int()) ||
      (first >= 'A'.to_int() && first <= 'Z'.to_int()) ||
      first == '_'.to_int() ||
      first == '$'.to_int(),
    ) {
    return false
  }
  for i in 1..<source.length() {
    if not(is_identifier_charcode(source[i].to_int())) {
      return false
    }
  }
  true
}

///|
fn is_identifier_charcode(c : Int) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= '0'.to_int() && c <= '9'.to_int()) ||
  c == '_'.to_int() ||
  c == '$'.to_int()
}
