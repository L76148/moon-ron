///|
/// Render an error with its source line and a caret.
pub fn render_error(source : StringView, error : MonError) -> String {
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
fn error_position(error : MonError) -> MonPosition? {
  match error {
    UnexpectedChar(position, _) => Some(position)
    UnexpectedEof(position) => Some(position)
    Expected(position, _) => Some(position)
    InvalidEscape(position) => Some(position)
    InvalidNumber(position, _) => Some(position)
    InvalidLiteral(position, _) => Some(position)
    DepthLimitExceeded(_) => None
  }
}

///|
fn error_message(error : MonError) -> String {
  match error {
    UnexpectedChar(_, char) => "unexpected character " + display_char(char)
    UnexpectedEof(_) => "unexpected end of input"
    Expected(_, description) => "expected " + description
    InvalidEscape(_) => "invalid escape sequence"
    InvalidNumber(_, token) => "invalid number " + token
    InvalidLiteral(_, message) => message
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
fn source_line(source : StringView, line : Int32) -> String {
  let lines = Array::from_iter(source.split("\n"))
  match lines.get(line - 1) {
    Some(value) => value.to_owned()
    None => ""
  }
}

///|
fn visual_column(line : String, column : Int32) -> Int32 {
  let chars = line.to_array()
  let end = if column < chars.length() { column } else { chars.length() }
  let mut width = 0
  for i = 0; i < end; i = i + 1 {
    width = width + (if chars[i] == '\t' { 4 } else { 1 })
  }
  width
}
