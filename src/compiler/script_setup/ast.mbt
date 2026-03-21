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
  annotation_name : String?
  expr : ScriptSetupExpression
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
}

///|
fn parse_script_setup_chunk_ast(
  source : String,
  filename : String,
) -> Array[ScriptSetupStatement] raise CompilerError {
  let (impls, reports) = @mbt_parser.parse_string(source, name=filename)
  if not(reports.is_empty()) {
    raise CompilerError::InvalidScriptSetup(reports[0].to_string())
  }
  let statements : Array[ScriptSetupStatement] = []
  for impl_ in impls {
    statements.push(script_setup_statement_from_ast(source, impl_, filename))
  }
  statements
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
        annotation_name: type_name_from_annotation(ty),
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
        Some(name) =>
          if is_supported_macro(name) {
            let mut arg_count = 0
            for _ in args {
              arg_count += 1
            }
            Some({
              name,
              args: extract_call_args(
                slice_location(source, loc),
                name,
                filename,
              ),
              arg_count,
              prop_defaults: parse_define_props_defaults(args, source),
            })
          } else {
            None
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
  name == "defineSlot" ||
  name == "useId" ||
  name == "useTemplateRef"
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
  let open_index = skip_inline_ws(chars, name.length())
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
