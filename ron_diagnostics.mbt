///|
/// Render a parser error with its source line and a caret.
pub fn render_error(source : StringView, error : RonError) -> String {
  let message = error_message(error)
  match error_position(error) {
    Some(position) => {
      let line = source_line(source, position.line)
      let column = visual_column(line, position.column)
      let caret = String::make(column, ' ')
      "error: " +
      message +
      " at line \{position.line}, column \{position.column + 1}\n  |\n" +
      position.line.to_string() +
      " | " +
      line +
      "\n  | " +
      caret +
      "^"
    }
    None => "error: " + message
  }
}

///|
/// Render a typed decoding error. Syntax errors include a source caret.
pub fn render_decode_error(
  source : StringView,
  error : RonDecodeError,
) -> String {
  match error {
    Syntax(error) => render_error(source, error)
    TypeMismatch(path, expected, actual) =>
      "error: expected " +
      expected +
      ", found " +
      actual +
      "\n  at " +
      path.to_string()
    MissingField(path, name) =>
      "error: missing field " + name + "\n  at " + path.to_string()
    UnexpectedTupleLength(path, expected, actual) =>
      "error: expected tuple length " +
      expected.to_string() +
      ", found " +
      actual.to_string() +
      "\n  at " +
      path.to_string()
    UnknownVariant(path, variant) =>
      "error: unknown variant " + variant + "\n  at " + path.to_string()
    InvalidValue(path, message) =>
      "error: " + message + "\n  at " + path.to_string()
  }
}

///|
fn error_position(error : RonError) -> RonPosition? {
  match error {
    UnexpectedChar(position, _) => Some(position)
    UnexpectedEof(position) => Some(position)
    InvalidEscape(position) => Some(position)
    InvalidNumber(position, _) => Some(position)
    InvalidValue(position, _) => Some(position)
    UnknownExtension(position, _) => Some(position)
    UnknownAttribute(position, _) => Some(position)
    InvalidAttribute(position, _) => Some(position)
    DepthLimitExceeded(_) => None
  }
}

///|
fn error_message(error : RonError) -> String {
  match error {
    UnexpectedChar(_, char) => "unexpected character " + display_char(char)
    UnexpectedEof(_) => "unexpected end of input"
    InvalidEscape(_) => "invalid escape sequence"
    InvalidNumber(_, token) => "invalid number " + token
    InvalidValue(_, message) => message
    UnknownExtension(_, name) => "unknown extension " + name
    UnknownAttribute(_, name) => "unknown attribute " + name
    InvalidAttribute(_, name) => "invalid attribute " + name
    DepthLimitExceeded(limit) => "maximum nesting depth \{limit} exceeded"
  }
}

///|
fn display_char(char : Char) -> String {
  match char {
    '\n' => "\\n"
    '\r' => "\\r"
    '\t' => "\\t"
    char => "'" + char.to_string() + "'"
  }
}

///|
fn source_line(source : StringView, line : Int) -> String {
  let lines = Array::from_iter(source.split("\n"))
  match lines.get(line - 1) {
    Some(value) => value.to_owned()
    None => ""
  }
}

///|
fn visual_column(line : String, column : Int) -> Int {
  let chars = line.to_array()
  let end = if column < chars.length() { column } else { chars.length() }
  let mut width = 0
  for i = 0; i < end; i = i + 1 {
    width = width + (if chars[i] == '\t' { 4 } else { 1 })
  }
  width
}
