///|
priv struct ScriptSetupContractResolver {
  filename : String
  contract_types : Array[ScriptSetupContractType]
}

///|
fn ScriptSetupContractResolver::new(
  filename : String,
  contract_types : Array[ScriptSetupContractType],
) -> ScriptSetupContractResolver {
  { filename, contract_types }
}

///|
fn ScriptSetupContractResolver::resolve_macro_fields(
  self : ScriptSetupContractResolver,
  macro_ : ScriptSetupMacro,
  annotation : ScriptSetupTypeAnnotation?,
) -> Array[MacroField] raise CompilerError {
  let fields = if accepts_typed_contract_macro(macro_) {
    self.resolve_typed_contract_fields(macro_, annotation)
  } else {
    raise CompilerError::InvalidScriptSetup(
      legacy_runtime_decl_message(macro_.name, self.filename),
    )
  }
  self.validate_interface_fields(fields, macro_.name)
}

///|
fn ScriptSetupContractResolver::resolve_prop_defaults(
  self : ScriptSetupContractResolver,
  macro_ : ScriptSetupMacro,
  fields : Array[MacroField],
  declaration : String?,
) -> Array[PropDefault] raise CompilerError {
  if macro_.name != "defineProps" || macro_.arg_count == 0 {
    return []
  }
  let defaults = match macro_.prop_defaults {
    Some(defaults) => defaults
    None =>
      raise CompilerError::InvalidScriptSetup(
        default_props_message(self.filename),
      )
  }
  guard declaration is Some(_) else {
    raise CompilerError::InvalidScriptSetup(
      "defineProps({ ... }) defaults require a typed binding like `let props : Props = defineProps({ ... })` in \{self.filename}",
    )
  }
  self.validate_prop_defaults(defaults, fields)
}

///|
fn ScriptSetupContractResolver::resolve_typed_contract_fields(
  self : ScriptSetupContractResolver,
  macro_ : ScriptSetupMacro,
  annotation : ScriptSetupTypeAnnotation?,
) -> Array[MacroField] raise CompilerError {
  let type_name = match annotation {
    Some(annotation) =>
      if annotation.is_local {
        annotation.name
      } else {
        raise CompilerError::InvalidScriptSetup(
          "\{macro_.name}() requires a local `struct \{annotation.name} {{ ... }}` contract in \{self.filename}; qualified type annotation `\{annotation.source}` is not supported",
        )
      }
    None =>
      raise CompilerError::InvalidScriptSetup(
        typed_contract_message(macro_.name, self.filename),
      )
  }
  match self.find_contract_type(type_name) {
    Some(contract) =>
      match contract.fields {
        Some(fields) => fields
        None =>
          raise CompilerError::InvalidScriptSetup(
            "\{macro_.name}() requires `\{type_name}` to be a local `struct` contract in \{self.filename}",
          )
      }
    None =>
      raise CompilerError::InvalidScriptSetup(
        "\{macro_.name}() requires a local `struct \{type_name} {{ ... }}` contract in \{self.filename}",
      )
  }
}

///|
fn ScriptSetupContractResolver::validate_interface_fields(
  self : ScriptSetupContractResolver,
  fields : Array[MacroField],
  macro_name : String,
) -> Array[MacroField] raise CompilerError {
  let validated : Array[MacroField] = []
  for field in fields {
    if not(is_identifier_literal(field.name)) {
      raise CompilerError::InvalidScriptSetup(
        "\{macro_name}() entries must be identifier-like for typed interfaces in \{self.filename}: \{field.name}",
      )
    }
    if has_interface_field(validated, field.name) {
      raise CompilerError::InvalidScriptSetup(
        "\{macro_name}() contract contains duplicate field `\{field.name}` in \{self.filename}",
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
    "defineSlots" => "Slots"
    "defineExpose" => "Expose"
    _ => "Contract"
  }
}

///|
fn default_contract_binding_name(macro_name : String) -> String {
  match macro_name {
    "defineProps" => "props"
    "defineEmits" => "emit"
    "defineSlots" => "slots"
    "defineExpose" => "expose"
    _ => "contract"
  }
}

///|
fn ScriptSetupContractResolver::validate_prop_defaults(
  self : ScriptSetupContractResolver,
  defaults : Array[PropDefault],
  fields : Array[MacroField],
) -> Array[PropDefault] raise CompilerError {
  let validated : Array[PropDefault] = []
  for default_ in defaults {
    if has_prop_default(validated, default_.name) {
      raise CompilerError::InvalidScriptSetup(
        "duplicate default for prop `\{default_.name}` in \{self.filename}",
      )
    }
    let field = match find_interface_field(fields, default_.name) {
      Some(field) => field
      None =>
        raise CompilerError::InvalidScriptSetup(
          "defineProps() default `\{default_.name}` does not match any declared prop in \{self.filename}",
        )
    }
    if field.is_optional {
      raise CompilerError::InvalidScriptSetup(
        "defineProps() default `\{default_.name}` requires a non-optional prop type in \{self.filename}; remove `?` from the contract field and let the default make it optional for callers",
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

///|
fn ScriptSetupContractResolver::find_contract_type(
  self : ScriptSetupContractResolver,
  name : String,
) -> ScriptSetupContractType? {
  for contract in self.contract_types {
    if contract.name == name {
      return Some(contract)
    }
  }
  None
}
