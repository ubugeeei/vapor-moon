///|
fn resolve_macro_fields(
  macro_ : ScriptSetupMacro,
  annotation : ScriptSetupTypeAnnotation?,
  contract_types : Array[ScriptSetupContractType],
  filename : String,
) -> Array[MacroField] raise CompilerError {
  let fields = if accepts_typed_contract_macro(macro_) {
    resolve_typed_contract_fields(macro_, annotation, contract_types, filename)
  } else {
    raise CompilerError::InvalidScriptSetup(
      legacy_runtime_decl_message(macro_.name, filename),
    )
  }
  validate_interface_fields(fields, macro_.name, filename)
}

///|
fn resolve_prop_defaults(
  macro_ : ScriptSetupMacro,
  fields : Array[MacroField],
  declaration : String?,
  filename : String,
) -> Array[PropDefault] raise CompilerError {
  if macro_.name != "defineProps" || macro_.arg_count == 0 {
    return []
  }
  let defaults = match macro_.prop_defaults {
    Some(defaults) => defaults
    None =>
      raise CompilerError::InvalidScriptSetup(default_props_message(filename))
  }
  guard declaration is Some(_) else {
    raise CompilerError::InvalidScriptSetup(
      "defineProps({ ... }) defaults require a typed binding like `let props : Props = defineProps({ ... })` in \{filename}",
    )
  }
  validate_prop_defaults(defaults, fields, filename)
}

///|
fn resolve_typed_contract_fields(
  macro_ : ScriptSetupMacro,
  annotation : ScriptSetupTypeAnnotation?,
  contract_types : Array[ScriptSetupContractType],
  filename : String,
) -> Array[MacroField] raise CompilerError {
  let type_name = match annotation {
    Some(annotation) =>
      if annotation.is_local {
        annotation.name
      } else {
        raise CompilerError::InvalidScriptSetup(
          "\{macro_.name}() requires a local `struct \{annotation.name} {{ ... }}` contract in \{filename}; qualified type annotation `\{annotation.source}` is not supported",
        )
      }
    None =>
      raise CompilerError::InvalidScriptSetup(
        typed_contract_message(macro_.name, filename),
      )
  }
  match find_contract_type(contract_types, type_name) {
    Some(contract) =>
      match contract.fields {
        Some(fields) => fields
        None =>
          raise CompilerError::InvalidScriptSetup(
            "\{macro_.name}() requires `\{type_name}` to be a local `struct` contract in \{filename}",
          )
      }
    None =>
      raise CompilerError::InvalidScriptSetup(
        "\{macro_.name}() requires a local `struct \{type_name} {{ ... }}` contract in \{filename}",
      )
  }
}

///|
fn validate_interface_fields(
  fields : Array[MacroField],
  macro_name : String,
  filename : String,
) -> Array[MacroField] raise CompilerError {
  let validated : Array[MacroField] = []
  for field in fields {
    if not(is_identifier_literal(field.name)) {
      raise CompilerError::InvalidScriptSetup(
        "\{macro_name}() entries must be identifier-like for typed interfaces in \{filename}: \{field.name}",
      )
    }
    if has_interface_field(validated, field.name) {
      raise CompilerError::InvalidScriptSetup(
        "\{macro_name}() contract contains duplicate field `\{field.name}` in \{filename}",
      )
    }
    validated.push(field)
  }
  validated
}

///|
fn typed_contract_message(macro_name : String, filename : String) -> String {
  let contract_name = default_contract_type_name(macro_name)
  let binding_name = default_contract_binding_name(macro_name)
  "\{macro_name}() requires a typed contract like `struct \{contract_name} { ... }` plus `let \{binding_name} : \{contract_name} = \{macro_name}()` in \{filename}"
}

///|
fn accepts_typed_contract_macro(macro_ : ScriptSetupMacro) -> Bool {
  macro_.arg_count == 0 ||
  (
    macro_.name == "defineProps" &&
    macro_.arg_count == 1 &&
    macro_.prop_defaults is Some(_)
  )
}

///|
fn legacy_runtime_decl_message(
  macro_name : String,
  filename : String,
) -> String {
  if macro_name == "defineProps" {
    return "\{macro_name}() only accepts a defaults record like `defineProps({ count: 0 })` in \{filename}; " +
      typed_contract_message(macro_name, filename)
  }
  "\{macro_name}() no longer accepts runtime declaration literals in \{filename}; " +
  typed_contract_message(macro_name, filename)
}

///|
fn default_props_message(filename : String) -> String {
  "defineProps() defaults must be passed as a single record literal in \{filename}, for example `let props : Props = defineProps({ count: 0 })`"
}

///|
fn default_contract_type_name(macro_name : String) -> String {
  match macro_name {
    "defineProps" => "Props"
    "defineEmits" => "Emits"
    "defineSlot" => "Slots"
    _ => "Contract"
  }
}

///|
fn default_contract_binding_name(macro_name : String) -> String {
  match macro_name {
    "defineProps" => "props"
    "defineEmits" => "emit"
    "defineSlot" => "slots"
    _ => "contract"
  }
}

///|
fn validate_prop_defaults(
  defaults : Array[PropDefault],
  fields : Array[MacroField],
  filename : String,
) -> Array[PropDefault] raise CompilerError {
  let validated : Array[PropDefault] = []
  for default_ in defaults {
    if has_prop_default(validated, default_.name) {
      raise CompilerError::InvalidScriptSetup(
        "duplicate default for prop `\{default_.name}` in \{filename}",
      )
    }
    let field = match find_interface_field(fields, default_.name) {
      Some(field) => field
      None =>
        raise CompilerError::InvalidScriptSetup(
          "defineProps() default `\{default_.name}` does not match any declared prop in \{filename}",
        )
    }
    if field.is_optional {
      raise CompilerError::InvalidScriptSetup(
        "defineProps() default `\{default_.name}` requires a non-optional prop type in \{filename}; remove `?` from the contract field and let the default make it optional for callers",
      )
    }
    validated.push(default_)
  }
  validated
}

///|
fn find_interface_field(
  fields : Array[MacroField],
  name : String,
) -> MacroField? {
  for field in fields {
    if field.name == name {
      return Some(field)
    }
  }
  None
}

///|
fn has_prop_default(defaults : Array[PropDefault], name : String) -> Bool {
  for default_ in defaults {
    if default_.name == name {
      return true
    }
  }
  false
}

///|
fn has_interface_field(fields : Array[MacroField], name : String) -> Bool {
  for field in fields {
    if field.name == name {
      return true
    }
  }
  false
}
