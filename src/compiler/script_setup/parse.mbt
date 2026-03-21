///|
fn resolve_macro_fields(
  macro_ : ScriptSetupMacro,
  annotation_name : String?,
  contract_types : Array[ScriptSetupContractType],
  filename : String,
) -> Array[MacroField] raise CompilerError {
  let fields = if macro_.arg_count == 0 {
    resolve_typed_contract_fields(
      macro_, annotation_name, contract_types, filename,
    )
  } else {
    raise CompilerError::InvalidScriptSetup(
      legacy_runtime_decl_message(macro_.name, filename),
    )
  }
  validate_interface_fields(fields, macro_.name, filename)
}

///|
fn resolve_typed_contract_fields(
  macro_ : ScriptSetupMacro,
  annotation_name : String?,
  contract_types : Array[ScriptSetupContractType],
  filename : String,
) -> Array[MacroField] raise CompilerError {
  let type_name = match annotation_name {
    Some(name) => name
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
  for field in fields {
    if not(is_identifier_literal(field.name)) {
      raise CompilerError::InvalidScriptSetup(
        "\{macro_name}() entries must be identifier-like for typed interfaces in \{filename}: \{field.name}",
      )
    }
  }
  fields
}

///|
fn typed_contract_message(macro_name : String, filename : String) -> String {
  let contract_name = default_contract_type_name(macro_name)
  let binding_name = default_contract_binding_name(macro_name)
  "\{macro_name}() requires a typed contract like `struct \{contract_name} { ... }` plus `let \{binding_name} : \{contract_name} = \{macro_name}()` in \{filename}"
}

///|
fn legacy_runtime_decl_message(
  macro_name : String,
  filename : String,
) -> String {
  "\{macro_name}() no longer accepts runtime declaration literals in \{filename}; " +
  typed_contract_message(macro_name, filename)
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
