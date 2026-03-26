///|
/// Incremental compilation infrastructure backed by ripple (salsa-inspired).
/// Wraps the compiler pipeline so that unchanged files skip recompilation.

///|
pub struct IncrementalCompiler {
  db : @ripple.Database
  file_sources : @ripple.Input[String, String]
  sfc_query : @ripple.Query[String, Result[@common.SfcDocument, @common.CompilerError]]
  template_query : @ripple.Query[String, Result[Array[@common.TemplateNode], @common.CompilerError]]
  css_query : @ripple.Query[String, Result[String, @common.CompilerError]]
  compile_query : @ripple.Query[String, Result[@common.CompileOutput, @common.CompilerError]]
}

///|
pub fn IncrementalCompiler::new() -> IncrementalCompiler {
  let db = @ripple.Database::new()
  let rt = db.runtime()
  let file_sources : @ripple.Input[String, String] = db.input()
  file_sources.register(rt)
  let not_found = fn(filename : String) -> @common.CompilerError {
    @common.CompilerError::InvalidSfc("file not found: " + filename)
  }
  let sfc_query : @ripple.Query[String, Result[@common.SfcDocument, @common.CompilerError]] = db.query(
    fn(rt, filename) {
      match file_sources.get(rt, filename) {
        Some(source) =>
          try { Ok(@compiler.parse_sfc(source, filename~)) } catch { e => Err(e) }
        None => Err(not_found(filename))
      }
    },
  )
  sfc_query.register(rt)
  let template_query : @ripple.Query[String, Result[Array[@common.TemplateNode], @common.CompilerError]] = db.query(
    fn(rt, filename) {
      match sfc_query.fetch(rt, filename) {
        Ok(doc) =>
          try { Ok(@compiler.parse_template(doc.template)) } catch { e => Err(e) }
        Err(e) => Err(e)
      }
    },
  )
  template_query.register(rt)
  let css_query : @ripple.Query[String, Result[String, @common.CompilerError]] = db.query(
    fn(rt, filename) {
      match sfc_query.fetch(rt, filename) {
        Ok(doc) => {
          let scope_id = @compiler.compute_scope_id(doc, filename)
          Ok(@compiler.emit_css(doc.styles, scope_id))
        }
        Err(e) => Err(e)
      }
    },
  )
  css_query.register(rt)
  let compile_query : @ripple.Query[String, Result[@common.CompileOutput, @common.CompilerError]] = db.query(
    fn(rt, filename) {
      let doc = match sfc_query.fetch(rt, filename) {
        Ok(doc) => doc
        Err(e) => return Err(e)
      }
      let template = match template_query.fetch(rt, filename) {
        Ok(nodes) => nodes
        Err(e) => return Err(e)
      }
      try {
        Ok(@compiler.compile_from_parts(doc, template, filename))
      } catch {
        e => Err(e)
      }
    },
  )
  compile_query.register(rt)
  { db, file_sources, sfc_query, template_query, css_query, compile_query }
}

///|
/// Set or update file source. Returns true if the content actually changed.
pub fn IncrementalCompiler::set_source(
  self : IncrementalCompiler,
  filename : String,
  source : String,
) -> Bool {
  let rev_before = self.db.current_revision()
  let rev_after = self.file_sources.set(self.db.runtime(), filename, source)
  rev_before != rev_after
}

///|
/// Compile a file incrementally. Returns cached result if source unchanged.
pub fn IncrementalCompiler::compile(
  self : IncrementalCompiler,
  filename : String,
) -> @common.CompileOutput raise @common.CompilerError {
  match self.compile_query.fetch(self.db.runtime(), filename) {
    Ok(output) => output
    Err(e) => raise e
  }
}

///|
/// Get parsed SFC document.
pub fn IncrementalCompiler::get_sfc(
  self : IncrementalCompiler,
  filename : String,
) -> @common.SfcDocument raise @common.CompilerError {
  match self.sfc_query.fetch(self.db.runtime(), filename) {
    Ok(doc) => doc
    Err(e) => raise e
  }
}

///|
/// Get parsed template nodes.
pub fn IncrementalCompiler::get_template(
  self : IncrementalCompiler,
  filename : String,
) -> Array[@common.TemplateNode] raise @common.CompilerError {
  match self.template_query.fetch(self.db.runtime(), filename) {
    Ok(nodes) => nodes
    Err(e) => raise e
  }
}

///|
/// Get CSS output.
pub fn IncrementalCompiler::get_css(
  self : IncrementalCompiler,
  filename : String,
) -> String raise @common.CompilerError {
  match self.css_query.fetch(self.db.runtime(), filename) {
    Ok(css) => css
    Err(e) => raise e
  }
}

///|
/// Get current revision (useful for testing cache behavior).
pub fn IncrementalCompiler::revision(
  self : IncrementalCompiler,
) -> @ripple.Revision {
  self.db.current_revision()
}
