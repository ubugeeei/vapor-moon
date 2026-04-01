///|
priv struct ToolingDocument {
  source : String
  filename : String
  chars : Array[Char]
}

///|
fn ToolingDocument::new(source : String, filename : String) -> ToolingDocument {
  { source, filename, chars: source.to_array() }
}

///|
fn ToolingDocument::position_to_offset(
  self : ToolingDocument,
  line : Int,
  character : Int,
) -> Int {
  let chars = self.chars
  let mut cursor = 0
  let mut current_line = 0
  let mut current_character = 0
  while cursor < chars.length() {
    if current_line == line && character <= current_character {
      return cursor
    }
    let char_ = chars[cursor]
    if char_ == '\n' {
      if current_line == line {
        return cursor
      }
      current_line += 1
      current_character = 0
    } else {
      let width = utf16_width(char_)
      if current_line == line && character < current_character + width {
        return cursor
      }
      current_character += width
    }
    cursor += 1
  }
  chars.length()
}

///|
fn utf16_width(c : Char) -> Int {
  if c.to_int() > 0xFFFF {
    2
  } else {
    1
  }
}

///|
fn ToolingDocument::offset_to_position(
  self : ToolingDocument,
  offset : Int,
) -> ToolingPosition {
  let chars = self.chars
  let limit = if offset < chars.length() { offset } else { chars.length() }
  let mut cursor = 0
  let mut line = 0
  let mut character = 0
  while cursor < limit {
    if chars[cursor] == '\n' {
      line += 1
      character = 0
    } else {
      character += utf16_width(chars[cursor])
    }
    cursor += 1
  }
  { line, character }
}

///|
fn ToolingDocument::location_from_span(
  self : ToolingDocument,
  span : @compiler.SourceSpan,
) -> ToolingLocation {
  {
    filename: self.filename,
    span,
    range: {
      start: self.offset_to_position(span.start),
      end_: self.offset_to_position(span.end),
    },
  }
}

///|
pub fn full_document_range(source : String) -> ToolingRange {
  let document = ToolingDocument::new(source, "")
  {
    start: { line: 0, character: 0 },
    end_: document.offset_to_position(source.length()),
  }
}

///|
fn contains_offset(span : @compiler.SourceSpan, offset : Int) -> Bool {
  offset >= span.start && offset < span.end
}

///|
fn spans_overlap(a : @compiler.SourceSpan, b : @compiler.SourceSpan) -> Bool {
  a.start < b.end && b.start < a.end
}

///|
fn is_identifier_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '$'
}

///|
fn token_boundary(c : Char) -> Bool {
  c == ' ' ||
  c == '\n' ||
  c == '\t' ||
  c == '\r' ||
  c == '<' ||
  c == '>' ||
  c == '"' ||
  c == '\'' ||
  c == '='
}

///|
fn ToolingDocument::span_text(
  self : ToolingDocument,
  span : @compiler.SourceSpan,
) -> String {
  String::unsafe_substring(self.source, start=span.start, end=span.end)
}

///|
fn ToolingDocument::current_token_prefix(
  self : ToolingDocument,
  offset : Int,
) -> String {
  let chars = self.chars
  let limit = if offset < chars.length() { offset } else { chars.length() }
  let mut start = limit
  while start > 0 && not(token_boundary(chars[start - 1])) {
    start -= 1
  }
  String::unsafe_substring(self.source, start~, end=limit)
}
