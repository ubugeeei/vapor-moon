///|
priv struct ScriptSetupContractType {
  name : String
  fields : Array[MacroField]?
}

///|
fn collect_script_setup_contract_types(
  source : String,
  filename : String,
) -> Array[ScriptSetupContractType] raise CompilerError {
  let contracts : Array[ScriptSetupContractType] = []
  for chunk in split_top_level_statements(source) {
    let trimmed = chunk.trim().to_string()
    if trimmed.length() == 0 || is_script_setup_import_statement(trimmed) {
      continue
    }
    let (impls, reports) = @mbt_parser.parse_string(trimmed, name=filename)
    if not(reports.is_empty()) {
      raise CompilerError::InvalidScriptSetup(reports[0].to_string())
    }
    for impl_ in impls {
      match impl_ {
        TopTypeDef(type_decl) =>
          contracts.push(parse_contract_type_decl(trimmed, type_decl))
        _ => ()
      }
    }
  }
  contracts
}

///|
fn parse_contract_type_decl(
  source : String,
  type_decl : @mbt_syntax.TypeDecl,
) -> ScriptSetupContractType {
  let fields = match type_decl.components {
    Record(field_decls) => Some(parse_contract_type_fields(source, field_decls))
    _ => None
  }
  { name: type_decl.tycon, fields }
}

///|
fn parse_contract_type_fields(
  source : String,
  field_decls : @list.List[@mbt_syntax.FieldDecl],
) -> Array[MacroField] {
  let fields : Array[MacroField] = []
  for field_decl in field_decls {
    fields.push({
      name: field_decl.name.label,
      signature: Some(
        slice_location(source, field_decl.ty.loc()).trim().to_string(),
      ),
    })
  }
  fields
}

///|
fn find_contract_type(
  contract_types : Array[ScriptSetupContractType],
  name : String,
) -> ScriptSetupContractType? {
  for contract in contract_types {
    if contract.name == name {
      return Some(contract)
    }
  }
  None
}

///|
fn type_name_from_annotation(ty : @mbt_syntax.Type?) -> String? {
  match ty {
    Some(type_) =>
      match type_ {
        Name(constr_id~, ..) =>
          match constr_id.id {
            Ident(name~) => Some(name)
            Dot(pkg~, id~) => {
              ignore(pkg)
              Some(id)
            }
          }
        _ => None
      }
    None => None
  }
}
