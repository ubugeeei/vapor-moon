///|
/// Parse a `.mbtv` source file into top-level SFC blocks.

///|
pub fn parse_sfc(
  source : String,
  filename? : String = "Component.mbtv",
) -> SfcDocument raise CompilerError {
  let blocks = parse_blocks(source)
  let mut template : String? = None
  let mut script : String? = None
  let mut script_setup : String? = None
  let mut script_setup_transformed : String? = None
  let mut script_setup_import_entries : Array[String] = []
  let mut generics : Array[GenericParam] = []
  let mut props_binding : String? = None
  let mut emits_binding : String? = None
  let mut slots_binding : String? = None
  let mut props : Array[MacroField] = []
  let mut emits : Array[MacroField] = []
  let mut slots : Array[MacroField] = []
  let styles : Array[StyleBlock] = []

  for block in blocks {
    reject_unsupported_attrs(block, filename)
    match block.kind {
      Template =>
        match template {
          Some(_) =>
            raise CompilerError::InvalidSfc(
              "duplicate <template> block in \{filename}",
            )
          None => template = Some(block.content)
        }
      Script =>
        match script {
          Some(_) =>
            raise CompilerError::InvalidSfc(
              "duplicate <script> block in \{filename}",
            )
          None => script = Some(block.content)
        }
      ScriptSetup =>
        match script_setup {
          Some(_) =>
            raise CompilerError::InvalidSfc(
              "duplicate <script setup> block in \{filename}",
            )
          None => {
            let info = analyze_script_setup(block.content, filename)
            generics = parse_script_setup_generics(block.attrs, filename)
            script_setup = Some(info.source)
            script_setup_transformed = Some(info.transformed)
            script_setup_import_entries = info.import_entries
            props_binding = info.props_binding
            props = info.props
            emits_binding = info.emits_binding
            emits = info.emits
            slots_binding = info.slots_binding
            slots = info.slots
            validate_generic_usage(generics, props, emits, slots, filename)
          }
        }
      Style => {
        let scoped = has_attr(block.attrs, "scoped")
        styles.push({
          attrs: block.attrs,
          content: block.content,
          scoped,
          span: block.span,
        })
      }
    }
  }

  match script {
    Some(_) =>
      raise CompilerError::InvalidSfc(
        "plain <script> is not supported in \{filename}; use <script setup> only",
      )
    None => ()
  }

  match template {
    Some(template_content) => {
      let ext = detect_extension(filename)
      {
        filename,
        extension: ext,
        template: template_content,
        script,
        script_setup,
        script_setup_transformed,
        script_setup_import_entries,
        generics,
        props_binding,
        props,
        emits_binding,
        emits,
        slots_binding,
        slots,
        styles,
        blocks,
      }
    }
    None =>
      raise CompilerError::InvalidSfc("missing <template> block in \{filename}")
  }
}
