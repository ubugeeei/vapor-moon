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
fn ScriptSetupSource::statement_from_ast(
  self : ScriptSetupSource,
  impl_ : @mbt_syntax.Impl,
) -> ScriptSetupStatement raise CompilerError {
  match impl_ {
    TopLetDef(binder~, ty~, expr~, ..) =>
      LetStatement({
        declaration: self.extract_let_declaration(expr.loc()),
        binding: Some(binder.name),
        annotation: self.type_annotation_from_ast(ty),
        expr: self.parse_expr_ast(expr),
      })
    TopExpr(expr~, ..) =>
      match self.parse_expr_ast(expr) {
        RawExpr(raw) => RawStatement(raw)
        macro_expr => ExpressionStatement(macro_expr)
      }
    _ => RawStatement(self.source.trim().to_string())
  }
}

///|
fn ScriptSetupSource::type_annotation_from_ast(
  self : ScriptSetupSource,
  ty : @mbt_syntax.Type?,
) -> ScriptSetupTypeAnnotation? {
  match ty {
    Some(type_) =>
      match type_ {
        Name(constr_id~, ..) => {
          let source_text = self.slice_location(type_.loc()).trim().to_string()
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
fn ScriptSetupSource::parse_expr_ast(
  self : ScriptSetupSource,
  expr : @mbt_syntax.Expr,
) -> ScriptSetupExpression raise CompilerError {
  match self.parse_macro(expr) {
    Some(macro_) => MacroExpr(macro_)
    None => RawExpr(self.slice_location(expr.loc()).trim().to_string())
  }
}

///|
fn ScriptSetupSource::parse_macro(
  self : ScriptSetupSource,
  expr : @mbt_syntax.Expr,
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
            validate_runtime_helper_macro(
              canonical_name,
              arg_count,
              self.filename,
            )
            Some({
              name: canonical_name,
              args: self.extract_call_args(self.slice_location(loc), name),
              arg_count,
              prop_defaults: self.parse_define_props_defaults(args),
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
fn ScriptSetupSource::parse_define_props_defaults(
  self : ScriptSetupSource,
  args : @list.List[@mbt_syntax.Argument],
) -> Array[PropDefault]? {
  guard args is @list.More(arg, tail=@list.Empty) else { return None }
  guard arg.kind is Positional else { return None }
  match unwrap_group_expr(arg.value) {
    Record(type_name~, fields~, ..) =>
      match type_name {
        Some(_) => None
        None => Some(self.parse_record_defaults(fields))
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
fn ScriptSetupSource::parse_record_defaults(
  self : ScriptSetupSource,
  fields : @list.List[@mbt_syntax.FieldDef],
) -> Array[PropDefault] {
  let defaults : Array[PropDefault] = []
  for field in fields {
    defaults.push({
      name: field.label.name,
      expr: self.slice_location(field.expr.loc()).trim().to_string(),
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
fn ScriptSetupSource::slice_location(
  self : ScriptSetupSource,
  loc : @mbt_basic.Location,
) -> String {
  String::unsafe_substring(
    self.source,
    start=loc.start.cnum,
    end=loc.end.cnum,
  )
}

///|
fn ScriptSetupSource::extract_let_declaration(
  self : ScriptSetupSource,
  expr_loc : @mbt_basic.Location,
) -> String raise CompilerError {
  let prefix = String::unsafe_substring(
    self.source,
    start=0,
    end=expr_loc.start.cnum,
  )
  let prefix_source = ScriptSetupSource::new(prefix, self.filename)
  match prefix_source.find_top_level_char('=') {
    Some(index) =>
      String::unsafe_substring(prefix, start=0, end=index).trim().to_string()
    None =>
      raise CompilerError::InvalidScriptSetup(
        "failed to locate `=` in script setup declaration in \{self.filename}",
      )
  }
}

///|
fn ScriptSetupSource::extract_call_args(
  self : ScriptSetupSource,
  source : String,
  name : String,
) -> String raise CompilerError {
  let call_source = ScriptSetupSource::new(source, self.filename)
  let open_index = call_source.skip_inline_gap(name.length())
  if open_index >= call_source.chars.length() || call_source.chars[open_index] != '(' {
    raise CompilerError::InvalidScriptSetup(
      "expected \{name}() call in \{self.filename}",
    )
  }
  let close_index = call_source.find_matching_delimiter(
    open_index,
    '(',
    ')',
    "macro call",
  )
  String::unsafe_substring(source, start=open_index + 1, end=close_index)
  .trim()
  .to_string()
}
