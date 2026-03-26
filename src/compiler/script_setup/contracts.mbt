///|
priv struct ScriptSetupContractType {
  name : String
  fields : Array[MacroField]?
}

///|
fn ScriptSetupSource::parse_contract_type_decl(
  self : ScriptSetupSource,
  type_decl : @mbt_syntax.TypeDecl,
) -> ScriptSetupContractType {
  let fields = match type_decl.components {
    Record(field_decls) => Some(self.parse_contract_type_fields(field_decls))
    _ => None
  }
  { name: type_decl.tycon, fields }
}

///|
fn ScriptSetupSource::parse_contract_type_fields(
  self : ScriptSetupSource,
  field_decls : @list.List[@mbt_syntax.FieldDecl],
) -> Array[MacroField] {
  let fields : Array[MacroField] = []
  for field_decl in field_decls {
    fields.push({
      name: field_decl.name.label,
      signature: Some(
        self.slice_location(field_decl.ty.loc()).trim().to_string(),
      ),
      type_identifiers: collect_type_identifiers(field_decl.ty),
      type_shape: classify_macro_field_type_shape(field_decl.ty),
      is_optional: is_optional_macro_field_type(field_decl.ty),
    })
  }
  fields
}

///|
fn collect_type_identifiers(ty : @mbt_syntax.Type) -> Array[String] {
  let identifiers : Array[String] = []
  collect_type_identifiers_into(ty, identifiers)
  identifiers
}

///|
fn collect_type_identifiers_into(
  ty : @mbt_syntax.Type,
  identifiers : Array[String],
) -> Unit {
  match ty {
    Any(_) => ()
    Arrow(args~, res~, err~, ..) => {
      for arg in args {
        collect_type_identifiers_into(arg, identifiers)
      }
      collect_type_identifiers_into(res, identifiers)
      collect_error_type_identifiers(err, identifiers)
    }
    Tuple(tys~, ..) =>
      for inner in tys {
        collect_type_identifiers_into(inner, identifiers)
      }
    Name(constr_id~, tys~, ..) => {
      push_type_identifier(identifiers, type_identifier_name(constr_id))
      for inner in tys {
        collect_type_identifiers_into(inner, identifiers)
      }
    }
    Option(ty~, ..) => collect_type_identifiers_into(ty, identifiers)
    Object(constr_id) =>
      push_type_identifier(identifiers, type_identifier_name(constr_id))
  }
}

///|
fn classify_macro_field_type_shape(
  ty : @mbt_syntax.Type,
) -> MacroFieldTypeShape {
  match ty {
    Option(ty~, ..) => classify_macro_field_type_shape(ty)
    Tuple(tys~, ..) =>
      if tys.is_empty() {
        UnitLike
      } else {
        TupleValues(list_length(tys))
      }
    Name(constr_id~, tys~, ..) =>
      if is_unit_type_name(constr_id, tys) {
        UnitLike
      } else {
        SingleValue
      }
    Any(_) | Arrow(..) | Object(_) => SingleValue
  }
}

///|
fn is_optional_macro_field_type(ty : @mbt_syntax.Type) -> Bool {
  match ty {
    Option(..) => true
    _ => false
  }
}

///|
fn is_unit_type_name(
  constr_id : @mbt_syntax.ConstrId,
  tys : @list.List[@mbt_syntax.Type],
) -> Bool {
  if not(tys.is_empty()) {
    return false
  }
  match constr_id.id {
    Ident(name~) => name == "Unit"
    Dot(pkg~, id~) => {
      ignore(pkg)
      id == "Unit"
    }
  }
}

///|
fn[T] list_length(values : @list.List[T]) -> Int {
  let mut count = 0
  for _ in values {
    count += 1
  }
  count
}

///|
fn collect_error_type_identifiers(
  err : @mbt_syntax.ErrorType,
  identifiers : Array[String],
) -> Unit {
  match err {
    ErrorType(ty~) | MaybeError(ty~) =>
      collect_type_identifiers_into(ty, identifiers)
    DefaultErrorType(_) | NoErrorType | Noraise(_) => ()
  }
}

///|
fn type_identifier_name(constr_id : @mbt_syntax.ConstrId) -> String {
  match constr_id.id {
    Ident(name~) => name
    Dot(pkg~, id~) => {
      ignore(pkg)
      id
    }
  }
}

///|
fn push_type_identifier(identifiers : Array[String], name : String) -> Unit {
  if not(contains_type_identifier(identifiers, name)) {
    identifiers.push(name)
  }
}

///|
fn contains_type_identifier(
  identifiers : Array[String],
  target : String,
) -> Bool {
  for identifier in identifiers {
    if identifier == target {
      return true
    }
  }
  false
}
