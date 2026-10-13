///|
/// The number of hex digits allowed in a `\u{...}` escape.
const MAX_UNICODE_DIGITS : Int32 = 6

///|
/// The largest value an unsuffixed integer literal can hold.
const INT_MAX : Int64 = 2147483647L

///|
/// The smallest value an unsuffixed integer literal can hold.
const INT_MIN : Int64 = -2147483648L

///|
/// The largest value a `UInt` literal can hold.
const UINT_MAX : UInt64 = 4294967295UL

///|
/// One lexical token of a MON document.
///
/// `()` is two tokens, `(` and `)`, exactly as the grammar reads it.
priv enum MonToken {
  Bool(Bool)
  Number(MonNumber)
  Char(Char)
  Byte(Byte)
  String(String)
  Bytes(Bytes)
  LowerName(String)
  UpperName(String)
  Path(String)
  LBrace
  RBrace
  LBracket
  RBracket
  LParen
  RParen
  Comma
  Colon
  DotDot
  DotDotEq
  Eof
}

///|
/// A token together with the position it starts at.
priv struct MonTokenInfo {
  token : MonToken
  position : MonPosition
}

///|
/// A short description of a token for diagnostics.
fn token_label(token : MonToken) -> String {
  match token {
    Bool(_) => "a boolean"
    Number(_) => "a number"
    Char(_) => "a character"
    String(_) => "a string"
    Bytes(_) => "a byte string"
    Byte(_) => "a byte"
    LowerName(name) => "the name `" + name + "`"
    UpperName(name) => "the name `" + name + "`"
    Path(name) => "the name `" + name + "`"
    LBrace => "`{`"
    RBrace => "`}`"
    LBracket => "`[`"
    RBracket => "`]`"
    LParen => "`(`"
    RParen => "`)`"
    Comma => "`,`"
    Colon => "`:`"
    DotDot => "`..`"
    DotDotEq => "`..=`"
    Eof => "the end of the document"
  }
}

///|
fn is_name_start(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char == '_'
}

///|
fn is_name_continue(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
}

///|
fn is_digit_of(char : Char, radix : Int32) -> Bool {
  match radix {
    2 => char == '0' || char == '1'
    8 => char.to_int() >= '0'.to_int() && char.to_int() <= '7'.to_int()
    10 => char.is_ascii_digit()
    _ =>
      char.is_ascii_digit() ||
      (char.to_int() >= 'a'.to_int() && char.to_int() <= 'f'.to_int()) ||
      (char.to_int() >= 'A'.to_int() && char.to_int() <= 'F'.to_int())
  }
}

///|
/// Tokenize a whole MON document.
fn tokenize(source : StringView) -> Array[MonTokenInfo] raise MonError {
  let lexer = MonLexer::new(source)
  let tokens = []
  while true {
    let info = lexer.next()
    let last = match info.token {
      Eof => true
      _ => false
    }
    tokens.push(info)
    if last {
      break
    }
  }
  tokens
}

///|
priv struct MonLexer {
  chars : Array[Char]
  mut offset : Int32
  mut line : Int32
  mut column : Int32
}

///|
fn MonLexer::new(source : StringView) -> MonLexer {
  let lexer : MonLexer = {
    chars: source.to_array(),
    offset: 0,
    line: 1,
    column: 0,
  }
  // A byte order mark is written by some editors and carries no meaning for
  // the document, so it is skipped before the first token.
  match lexer.peek() {
    Some('\u{FEFF}') => lexer.advance() |> ignore
    _ => ()
  }
  lexer
}

///|
fn MonLexer::position(self : MonLexer) -> MonPosition {
  { index: self.offset, line: self.line, column: self.column, }
}

///|
fn MonLexer::peek(self : MonLexer) -> Char? {
  self.chars.get(self.offset)
}

///|
fn MonLexer::peek_at(self : MonLexer, distance : Int32) -> Char? {
  self.chars.get(self.offset + distance)
}

///|
fn MonLexer::advance(self : MonLexer) -> Char? {
  match self.chars.get(self.offset) {
    Some(char) => {
      self.offset = self.offset + 1
      if char == '\n' {
        self.line = self.line + 1
        self.column = 0
      } else {
        self.column = self.column + 1
      }
      Some(char)
    }
    None => None
  }
}

///|
fn MonLexer::single(self : MonLexer, token : MonToken) -> MonToken {
  self.advance() |> ignore
  token
}

///|
/// Skip whitespace and `//` comments.
///
/// MON follows MoonBit here: MoonBit has no block comments, so `/*` is not
/// trivia and reports an unexpected character.
fn MonLexer::skip_trivia(self : MonLexer) -> Unit {
  while true {
    match self.peek() {
      Some(char) if char.is_whitespace() => self.advance() |> ignore
      Some('/') if self.peek_at(1) == Some('/') => {
        self.advance() |> ignore
        self.advance() |> ignore
        while true {
          match self.peek() {
            Some('\n') | None => break
            _ => self.advance() |> ignore
          }
        }
      }
      _ => break
    }
  }
}

///|
fn MonLexer::next(self : MonLexer) -> MonTokenInfo raise MonError {
  self.skip_trivia()
  let position = self.position()
  let token = match self.peek() {
    None => MonToken::Eof
    Some('(') => self.single(MonToken::LParen)
    Some(')') => self.single(MonToken::RParen)
    Some('[') => self.single(MonToken::LBracket)
    Some(']') => self.single(MonToken::RBracket)
    Some('{') => self.single(MonToken::LBrace)
    Some('}') => self.single(MonToken::RBrace)
    Some(',') => self.single(MonToken::Comma)
    Some(':') => self.single(MonToken::Colon)
    Some('.') => self.lex_range_operator()
    Some('#') =>
      if self.peek_at(1) == Some('|') {
        MonToken::String(self.lex_multiline_string())
      } else {
        raise UnexpectedChar(position, '#')
      }
    Some('\'') => MonToken::Char(self.lex_char())
    Some('"') => MonToken::String(self.lex_string())
    Some('b') =>
      match self.peek_at(1) {
        Some('\'') => MonToken::Byte(self.lex_byte_char())
        Some('"') => MonToken::Bytes(self.lex_byte_string())
        _ => self.lex_name()
      }
    Some('-') =>
      match self.peek_at(1) {
        Some(char) if char.is_ascii_digit() =>
          MonToken::Number(self.lex_number())
        _ => raise UnexpectedChar(position, '-')
      }
    Some(char) if char.is_ascii_digit() => MonToken::Number(self.lex_number())
    Some(char) if is_name_start(char) => self.lex_name()
    Some(char) => raise UnexpectedChar(position, char)
  }
  { token, position, }
}

///|
fn MonLexer::lex_range_operator(self : MonLexer) -> MonToken raise MonError {
  match self.peek_at(1) {
    Some('.') =>
      if self.peek_at(2) == Some('=') {
        self.advance() |> ignore
        self.advance() |> ignore
        self.advance() |> ignore
        MonToken::DotDotEq
      } else {
        self.advance() |> ignore
        self.advance() |> ignore
        MonToken::DotDot
      }
    _ =>
      match self.peek() {
        Some(char) => raise UnexpectedChar(self.position(), char)
        None => raise UnexpectedEof(self.position())
      }
  }
}

///|
/// Read a name, `true`, `false`, or a `A::B` constructor path.
fn MonLexer::lex_name(self : MonLexer) -> MonToken raise MonError {
  let start = self.position()
  let name = self.read_identifier()
  match name {
    "true" => MonToken::Bool(true)
    "false" => MonToken::Bool(false)
    _ => {
      let upper = starts_uppercase(name)
      if self.peek() == Some(':') && self.peek_at(1) == Some(':') {
        if !upper {
          raise InvalidLiteral(
            start, "a qualified name must start with an uppercase letter",
          )
        }
        let buffer = StringBuilder()
        buffer.write_string(name)
        while self.peek() == Some(':') && self.peek_at(1) == Some(':') {
          self.advance() |> ignore
          self.advance() |> ignore
          let segment = self.read_identifier()
          if !starts_uppercase(segment) {
            raise InvalidLiteral(
              start, "every segment of a qualified name must start with an uppercase letter",
            )
          }
          buffer.write_string("::")
          buffer.write_string(segment)
        }
        MonToken::Path(buffer.to_string())
      } else if upper {
        MonToken::UpperName(name)
      } else {
        MonToken::LowerName(name)
      }
    }
  }
}

///|
fn starts_uppercase(name : String) -> Bool {
  match name.get_char(0) {
    Some(char) => char.is_ascii_uppercase()
    None => false
  }
}

///|
fn MonLexer::read_identifier(self : MonLexer) -> String {
  let buffer = StringBuilder()
  while true {
    match self.peek() {
      Some(char) if is_name_continue(char) => {
        buffer.write_char(char)
        self.advance() |> ignore
      }
      _ => break
    }
  }
  buffer.to_string()
}

///|
fn MonLexer::lex_char(self : MonLexer) -> Char raise MonError {
  let start = self.position()
  self.advance() |> ignore
  let value = self.lex_character(start)
  self.expect_quote(start)
  value
}

///|
fn MonLexer::expect_quote(
  self : MonLexer,
  start : MonPosition,
) -> Unit raise MonError {
  match self.peek() {
    Some('\'') => self.advance() |> ignore
    Some(_) =>
      raise InvalidLiteral(start, "a character literal holds one character")
    None => raise UnexpectedEof(self.position())
  }
}

///|
fn MonLexer::lex_character(
  self : MonLexer,
  start : MonPosition,
) -> Char raise MonError {
  match self.advance() {
    Some('\\') => self.lex_unicode_escape(start)
    Some('\'') =>
      raise InvalidLiteral(start, "a character literal holds one character")
    Some('\n') | None =>
      raise InvalidLiteral(start, "a character literal holds one character")
    Some(char) => char
  }
}

///|
/// Read the body of a `"..."` string.
fn MonLexer::lex_string(self : MonLexer) -> String raise MonError {
  let start = self.position()
  self.advance() |> ignore
  let buffer = StringBuilder()
  while true {
    match self.advance() {
      Some('"') => break
      Some('\\') => buffer.write_char(self.lex_unicode_escape(start))
      Some('\n') | None =>
        raise InvalidLiteral(start, "unterminated string literal")
      Some(char) => buffer.write_char(char)
    }
  }
  buffer.to_string()
}

///|
/// Read a `b'x'` byte literal.
fn MonLexer::lex_byte_char(self : MonLexer) -> Byte raise MonError {
  let start = self.position()
  self.advance() |> ignore
  self.advance() |> ignore
  let value = self.lex_byte(start)
  self.expect_quote(start)
  value
}

///|
/// Read a `b"..."` byte string.
fn MonLexer::lex_byte_string(self : MonLexer) -> Bytes raise MonError {
  let start = self.position()
  self.advance() |> ignore
  self.advance() |> ignore
  let bytes = []
  while true {
    match self.advance() {
      Some('"') => break
      Some('\\') => bytes.push(self.lex_byte_escape(start))
      Some('\n') | None =>
        raise InvalidLiteral(start, "unterminated byte string literal")
      Some(char) => bytes.push(plain_byte(char, start))
    }
  }
  Bytes::from_array(bytes)
}

///|
fn MonLexer::lex_byte(
  self : MonLexer,
  start : MonPosition,
) -> Byte raise MonError {
  match self.advance() {
    Some('\\') => self.lex_byte_escape(start)
    Some('\'') | Some('"') | Some('\n') | None =>
      raise InvalidLiteral(start, "a byte literal holds one byte")
    Some(char) => plain_byte(char, start)
  }
}

///|
fn plain_byte(char : Char, start : MonPosition) -> Byte raise MonError {
  let code = char.to_int()
  if code > 0xff {
    raise InvalidLiteral(
      start, "a byte literal holds one byte, so its text must be ASCII",
    )
  }
  code.to_byte()
}

///|
/// Read a byte escape. Byte literals share MoonBit's `\x..` form and the
/// ASCII escapes, and they reject `\u{...}` because a byte is not a scalar
/// value.
fn MonLexer::lex_byte_escape(
  self : MonLexer,
  start : MonPosition,
) -> Byte raise MonError {
  match self.advance() {
    Some('n') => b'\n'
    Some('r') => b'\r'
    Some('t') => b'\t'
    Some('b') => b'\x08'
    Some('f') => b'\x0c'
    Some('\\') => b'\\'
    Some('\'') => b'\''
    Some('"') => b'"'
    Some('/') => b'/'
    Some('x') => {
      let value = self.lex_hex_value(start, 2, false)
      value.to_byte()
    }
    Some(_) => raise InvalidEscape(start)
    None => raise UnexpectedEof(self.position())
  }
}

///|
/// Read the escape that follows a backslash inside a character or string
/// literal.
fn MonLexer::lex_unicode_escape(
  self : MonLexer,
  start : MonPosition,
) -> Char raise MonError {
  match self.advance() {
    Some('n') => '\n'
    Some('r') => '\r'
    Some('t') => '\t'
    Some('b') => '\u{8}'
    Some('f') => '\u{c}'
    Some('\\') => '\\'
    Some('\'') => '\''
    Some('"') => '"'
    Some('/') => '/'
    Some('u') => {
      let value = match self.peek() {
        Some('{') => {
          self.advance() |> ignore
          let value = self.lex_hex_value(start, MAX_UNICODE_DIGITS, true)
          match self.peek() {
            Some('}') => self.advance() |> ignore
            _ => raise InvalidEscape(start)
          }
          value
        }
        _ => self.lex_hex_value(start, 4, false)
      }
      if value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff) {
        raise InvalidEscape(start)
      }
      match value.to_char() {
        Some(char) => char
        None => raise InvalidEscape(start)
      }
    }
    Some(_) => raise InvalidEscape(start)
    None => raise UnexpectedEof(self.position())
  }
}

///|
/// Read at most `limit` hex digits.
///
/// `braced` allows a variable number of digits and stops at `}`; otherwise
/// exactly `limit` digits are required.
fn MonLexer::lex_hex_value(
  self : MonLexer,
  start : MonPosition,
  limit : Int32,
  braced : Bool,
) -> Int32 raise MonError {
  let mut value = 0
  let mut digits = 0
  while true {
    let digit = match self.peek() {
      Some(char) if char.is_ascii_digit() => char.to_int() - '0'.to_int()
      Some(char) if char.to_int() >= 'a'.to_int() &&
        char.to_int() <= 'f'.to_int() => char.to_int() - 'a'.to_int() + 10
      Some(char) if char.to_int() >= 'A'.to_int() &&
        char.to_int() <= 'F'.to_int() => char.to_int() - 'A'.to_int() + 10
      _ => break
    }
    if digits == limit {
      if braced {
        raise InvalidEscape(start)
      } else {
        break
      }
    }
    value = (value << 4) | digit
    digits = digits + 1
    self.advance() |> ignore
  }
  if digits == 0 {
    raise InvalidEscape(start)
  }
  if !braced && digits != limit {
    raise InvalidEscape(start)
  }
  value
}

///|
/// Read a `#|` multiline string.
///
/// The literal continues while the following lines start with `#|` after
/// their indentation. The indentation and the `#|` are dropped and the rest of
/// each line is kept verbatim, so the lines are joined with `\n` without a
/// trailing newline — the same text MoonBit produces for the same source.
fn MonLexer::lex_multiline_string(self : MonLexer) -> String {
  let buffer = StringBuilder()
  let mut first = true
  while true {
    self.advance() |> ignore
    self.advance() |> ignore
    if !first {
      buffer.write_char('\n')
    }
    first = false
    while true {
      match self.peek() {
        Some('\n') | None => break
        Some('\r') if self.peek_at(1) == Some('\n') => self.advance() |> ignore
        Some(char) => {
          buffer.write_char(char)
          self.advance() |> ignore
        }
      }
    }
    let saved_offset = self.offset
    let saved_line = self.line
    let saved_column = self.column
    match self.peek() {
      Some('\n') => {
        self.advance() |> ignore
        while self.peek() == Some(' ') || self.peek() == Some('\t') {
          self.advance() |> ignore
        }
        if self.peek() == Some('#') && self.peek_at(1) == Some('|') {
          continue
        }
        self.offset = saved_offset
        self.line = saved_line
        self.column = saved_column
        break
      }
      _ => break
    }
  }
  buffer.to_string()
}

///|
/// Read a numeric literal. The caller guarantees that a `-` is followed by a
/// digit and that a non-negative literal starts with a digit.
fn MonLexer::lex_number(self : MonLexer) -> MonNumber raise MonError {
  let start = self.position()
  let buffer = StringBuilder()
  let mut negative = false
  if self.peek() == Some('-') {
    negative = true
    buffer.write_char('-')
    self.advance() |> ignore
  }
  let mut radix = 10
  if self.peek() == Some('0') {
    match self.peek_at(1) {
      Some('x') | Some('X') => {
        radix = 16
        buffer.write_string("0x")
        self.advance() |> ignore
        self.advance() |> ignore
      }
      Some('o') | Some('O') => {
        radix = 8
        buffer.write_string("0o")
        self.advance() |> ignore
        self.advance() |> ignore
      }
      Some('b') | Some('B') => {
        radix = 2
        buffer.write_string("0b")
        self.advance() |> ignore
        self.advance() |> ignore
      }
      _ => ()
    }
  }
  let digits = self.lex_digits(buffer, radix, start)
  if digits == 0 {
    raise InvalidNumber(start, buffer.to_string())
  }
  let mut is_float = false
  if radix == 10 && self.peek() == Some('.') {
    match self.peek_at(1) {
      Some(char) if char.is_ascii_digit() => {
        is_float = true
        buffer.write_char('.')
        self.advance() |> ignore
        let _ = self.lex_digits(buffer, 10, start)
      }
      _ => ()
    }
  }
  if radix == 10 && self.exponent_follows() {
    if !is_float {
      raise InvalidLiteral(
        start, "exponent notation needs a fractional part, as in `1.0e10`",
      )
    }
    let marker = match self.peek() {
      Some(char) => char
      None => 'e'
    }
    buffer.write_char(marker)
    self.advance() |> ignore
    match self.peek() {
      Some('+') | Some('-') => {
        buffer.write_char(
          match self.peek() {
            Some(char) => char
            None => '+'
          },
        )
        self.advance() |> ignore
      }
      _ => ()
    }
    let _ = self.lex_digits(buffer, 10, start)
  }
  let suffix = self.lex_number_suffix()
  let numeric = buffer.to_string()
  if is_float {
    if suffix != "" {
      raise InvalidNumber(start, numeric + suffix)
    }
    let value = @string.parse_double(numeric) catch {
      _ => raise InvalidNumber(start, numeric)
    }
    return MonNumber::Double(value)
  }
  let spelling = numeric + suffix
  match suffix {
    "" => {
      let value = @string.parse_int64(numeric, base=0) catch {
        _ => raise InvalidNumber(start, spelling)
      }
      if value > INT_MAX || value < INT_MIN {
        raise InvalidNumber(start, spelling)
      }
      MonNumber::Int(value.to_int())
    }
    "L" => {
      let value = @string.parse_int64(numeric, base=0) catch {
        _ => raise InvalidNumber(start, spelling)
      }
      MonNumber::Int64(value)
    }
    "U" => {
      if negative {
        raise InvalidNumber(start, spelling)
      }
      let value = @string.parse_uint64(numeric, base=0) catch {
        _ => raise InvalidNumber(start, spelling)
      }
      if value > UINT_MAX {
        raise InvalidNumber(start, spelling)
      }
      MonNumber::UInt(value.to_uint())
    }
    _ => {
      if negative {
        raise InvalidNumber(start, spelling)
      }
      let value = @string.parse_uint64(numeric, base=0) catch {
        _ => raise InvalidNumber(start, spelling)
      }
      MonNumber::UInt64(value)
    }
  }
}

///|
/// Read digits of `radix`, allowing `_` between digits.
fn MonLexer::lex_digits(
  self : MonLexer,
  buffer : StringBuilder,
  radix : Int32,
  start : MonPosition,
) -> Int32 raise MonError {
  let mut digits = 0
  while true {
    match self.peek() {
      Some(char) if is_digit_of(char, radix) => {
        buffer.write_char(char)
        digits = digits + 1
        self.advance() |> ignore
      }
      Some('_') =>
        if digits == 0 {
          raise InvalidNumber(
            start, "a digit separator needs digits on both sides",
          )
        } else {
          match self.peek_at(1) {
            Some(char) if is_digit_of(char, radix) => self.advance() |> ignore
            _ =>
              raise InvalidNumber(
                start, "a digit separator needs digits on both sides",
              )
          }
        }
      _ => break
    }
  }
  digits
}

///|
fn MonLexer::exponent_follows(self : MonLexer) -> Bool {
  let sign = match self.peek() {
    Some('e') | Some('E') => 1
    _ => 0
  }
  if sign == 0 {
    return false
  }
  match self.peek_at(1) {
    Some(char) if char.is_ascii_digit() => true
    Some('+') | Some('-') =>
      match self.peek_at(2) {
        Some(char) => char.is_ascii_digit()
        None => false
      }
    _ => false
  }
}

///|
fn MonLexer::lex_number_suffix(self : MonLexer) -> String raise MonError {
  let suffix = match self.peek() {
    Some('U') =>
      if self.peek_at(1) == Some('L') {
        self.advance() |> ignore
        "UL"
      } else {
        "U"
      }
    Some('L') => "L"
    _ => ""
  }
  if suffix != "" {
    self.advance() |> ignore
    match self.peek() {
      Some(char) if is_name_continue(char) =>
        raise InvalidLiteral(
          self.position(),
          "an integer literal has the suffix `" + suffix + "`",
        )
      _ => ()
    }
  }
  suffix
}
