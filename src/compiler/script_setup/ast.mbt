///|
priv struct ScriptSetupModule {
  statements : Array[ScriptSetupStatement]
}

///|
priv enum ScriptSetupStatement {
  ImportStatement(Array[String])
  LetStatement(ScriptSetupLet)
  ExpressionStatement(ScriptSetupExpression)
  RawStatement(String)
}

///|
priv struct ScriptSetupLet {
  declaration : String
  binding : String?
  annotation : ScriptSetupTypeAnnotation?
  expr : ScriptSetupExpression
}

///|
priv struct ScriptSetupTypeAnnotation {
  name : String
  source : String
  is_local : Bool
}

///|
priv enum ScriptSetupExpression {
  RawExpr(String)
  MacroExpr(ScriptSetupMacro)
}

///|
priv struct ScriptSetupMacro {
  name : String
  args : String
  arg_count : Int
  prop_defaults : Array[PropDefault]?
  static_string_arg : String?
}

///|
fn script_setup_statement_from_ast(
  source : String,
  impl_ : @mbt_syntax.Impl,
  filename : String,
) -> ScriptSetupStatement raise CompilerError {
  match impl_ {
    TopLetDef(binder~, ty~, expr~, ..) =>
      LetStatement({
        declaration: extract_let_declaration(source, expr.loc(), filename),
        binding: Some(binder.name),
        annotation: type_annotation_from_ast(source, ty),
        expr: parse_script_setup_expr_ast(source, expr, filename),
      })
    TopExpr(expr~, ..) =>
      match parse_script_setup_expr_ast(source, expr, filename) {
        RawExpr(raw) => RawStatement(raw)
        macro_expr => ExpressionStatement(macro_expr)
      }
    _ => RawStatement(source.trim().to_string())
  }
}

///|
fn type_annotation_from_ast(
  source : String,
  ty : @mbt_syntax.Type?,
) -> ScriptSetupTypeAnnotation? {
  match ty {
    Some(type_) =>
      match type_ {
        Name(constr_id~, ..) => {
          let source_text = slice_location(source, type_.loc())
            .trim()
            .to_string()
          match constr_id.id {
            Ident(name~) => Some({ name, source: source_text, is_local: true })
            Dot(pkg~, id~) => {
              ignore(pkg)
              Some({ name: id, source: source_text, is_local: false })
            }
          }
        }
        _ => None
      }
    None => None
  }
}

///|
fn parse_script_setup_expr_ast(
  source : String,
  expr : @mbt_syntax.Expr,
  filename : String,
) -> ScriptSetupExpression raise CompilerError {
  match parse_script_setup_macro(expr, source, filename) {
    Some(macro_) => MacroExpr(macro_)
    None => RawExpr(slice_location(source, expr.loc()).trim().to_string())
  }
}

///|
fn parse_script_setup_macro(
  expr : @mbt_syntax.Expr,
  source : String,
  filename : String,
) -> ScriptSetupMacro? raise CompilerError {
  let expr = unwrap_group_expr(expr)
  match expr {
    Apply(func~, args~, loc~, ..) =>
      match macro_name_from_expr(func) {
        Some(name) => {
          let canonical_name = canonical_macro_name(name)
          if is_supported_macro(canonical_name) {
            let mut arg_count = 0
            for _ in args {
              arg_count += 1
            }
            validate_runtime_helper_macro(canonical_name, arg_count, filename)
            Some({
              name: canonical_name,
              args: extract_call_args(
                slice_location(source, loc),
                name,
                filename,
              ),
              arg_count,
              prop_defaults: parse_define_props_defaults(args, source),
              static_string_arg: extract_static_string_arg(args),
            })
          } else {
            None
          }
        }
        None => None
      }
    _ => None
  }
}

///|
fn macro_name_from_expr(expr : @mbt_syntax.Expr) -> String? {
  let expr = unwrap_group_expr(expr)
  match expr {
    Ident(id={ name: Ident(name~), .. }, ..) => Some(name)
    _ => None
  }
}

///|
fn is_supported_macro(name : String) -> Bool {
  name == "defineProps" ||
  name == "defineEmits" ||
  name == "defineSlots" ||
  name == "defineExpose" ||
  name == "useId" ||
  name == "useTemplateRef"
}

///|
fn canonical_macro_name(name : String) -> String {
  if name == "defineExporse" {
    "defineExpose"
  } else {
    name
  }
}

///|
fn validate_runtime_helper_macro(
  name : String,
  arg_count : Int,
  filename : String,
) -> Unit raise CompilerError {
  match name {
    "useId" =>
      if arg_count != 0 {
        raise CompilerError::InvalidScriptSetup(
          "useId() does not take arguments in \{filename}",
        )
      }
    "useTemplateRef" =>
      if arg_count != 1 {
        raise CompilerError::InvalidScriptSetup(
          "useTemplateRef() requires exactly one argument in \{filename}",
        )
      }
    _ => ()
  }
}

///|
fn parse_define_props_defaults(
  args : @list.List[@mbt_syntax.Argument],
  source : String,
) -> Array[PropDefault]? {
  guard args is @list.More(arg, tail=@list.Empty) else { return None }
  guard arg.kind is Positional else { return None }
  match unwrap_group_expr(arg.value) {
    Record(type_name~, fields~, ..) =>
      match type_name {
        Some(_) => None
        None => Some(parse_record_defaults(fields, source))
      }
    _ => None
  }
}

///|
fn extract_static_string_arg(
  args : @list.List[@mbt_syntax.Argument],
) -> String? {
  guard args is @list.More(arg, tail=@list.Empty) else { return None }
  guard arg.kind is Positional else { return None }
  match unwrap_group_expr(arg.value) {
    Constant(c~, ..) =>
      match c {
        String(value) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn parse_record_defaults(
  fields : @list.List[@mbt_syntax.FieldDef],
  source : String,
) -> Array[PropDefault] {
  let defaults : Array[PropDefault] = []
  for field in fields {
    defaults.push({
      name: field.label.name,
      expr: slice_location(source, field.expr.loc()).trim().to_string(),
    })
  }
  defaults
}

///|
fn unwrap_group_expr(expr : @mbt_syntax.Expr) -> @mbt_syntax.Expr {
  match expr {
    Group(expr~, ..) => unwrap_group_expr(expr)
    _ => expr
  }
}

///|
fn slice_location(source : String, loc : @mbt_basic.Location) -> String {
  String::unsafe_substring(source, start=loc.start.cnum, end=loc.end.cnum)
}

///|
fn extract_let_declaration(
  source : String,
  expr_loc : @mbt_basic.Location,
  filename : String,
) -> String raise CompilerError {
  let prefix = String::unsafe_substring(
    source,
    start=0,
    end=expr_loc.start.cnum,
  )
  match find_top_level_char(prefix, prefix.to_array(), '=') {
    Some(index) =>
      String::unsafe_substring(prefix, start=0, end=index).trim().to_string()
    None =>
      raise CompilerError::InvalidScriptSetup(
        "failed to locate `=` in script setup declaration in \{filename}",
      )
  }
}

///|
fn extract_call_args(
  source : String,
  name : String,
  filename : String,
) -> String raise CompilerError {
  let chars = source.to_array()
  let open_index = skip_inline_gap(source, chars, name.length())
  if open_index >= chars.length() || chars[open_index] != '(' {
    raise CompilerError::InvalidScriptSetup(
      "expected \{name}() call in \{filename}",
    )
  }
  let close_index = find_matching_delimiter(
    source, chars, open_index, '(', ')', filename, "macro call",
  )
  String::unsafe_substring(source, start=open_index + 1, end=close_index)
  .trim()
  .to_string()
}
