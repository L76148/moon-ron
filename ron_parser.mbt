///|
priv struct RonParser {
  source : Array[Char]
  mut offset : Int
  max_nesting_depth : Int
}

///|
fn RonParser::new(source : StringView, max_nesting_depth : Int) -> RonParser {
  { source: source.to_array(), offset: 0, max_nesting_depth, }
}

///|
fn RonParser::position(self : RonParser) -> RonPosition {
  let mut line = 1
  let mut column = 0
  for i = 0; i < self.offset && i < self.source.length(); i = i + 1 {
    if self.source[i] == '\n' {
      line = line + 1
      column = 0
    } else {
      column = column + 1
    }
  }
  { index: self.offset, line, column, }
}

///|
fn RonParser::error_char(self : RonParser, char : Char) -> RonError {
  UnexpectedChar(self.position(), char)
}

///|
fn RonParser::error_eof(self : RonParser) -> RonError {
  UnexpectedEof(self.position())
}

///|
fn RonParser::error_escape(self : RonParser) -> RonError {
  InvalidEscape(self.position())
}

///|
fn RonParser::error_number(self : RonParser, token : String) -> RonError {
  InvalidNumber(self.position(), token)
}

///|
fn RonParser::error_value(self : RonParser, message : String) -> RonError {
  InvalidValue(self.position(), message)
}

///|
fn RonParser::peek(self : RonParser) -> Char? {
  self.source.get(self.offset)
}

///|
fn RonParser::peek_at(self : RonParser, distance : Int) -> Char? {
  self.source.get(self.offset + distance)
}

///|
fn RonParser::advance(self : RonParser) -> Char? {
  let char = self.peek()
  match char {
    Some(_) => self.offset = self.offset + 1
    None => ()
  }
  char
}

///|
fn RonParser::expect(self : RonParser, expected : Char) -> Unit raise RonError {
  match self.advance() {
    Some(char) if char == expected => ()
    Some(char) => raise self.error_char(char)
    None => raise self.error_eof()
  }
}

///|
fn RonParser::skip_trivia(self : RonParser) -> Unit raise RonError {
  while self.offset < self.source.length() {
    let char = self.source[self.offset]
    if char.is_whitespace() {
      self.offset = self.offset + 1
      continue
    }
    if char == '/' {
      match self.peek_at(1) {
        Some('/') => {
          self.offset = self.offset + 2
          while self.offset < self.source.length() &&
                self.source[self.offset] != '\n' {
            self.offset = self.offset + 1
          }
          continue
        }
        Some('*') => {
          self.offset = self.offset + 2
          self.skip_block_comment()
          continue
        }
        _ => ()
      }
    }
    break
  }
}

///|
fn RonParser::skip_block_comment(self : RonParser) -> Unit raise RonError {
  let mut nesting = 1
  while nesting > 0 {
    if self.offset >= self.source.length() {
      raise self.error_eof()
    }
    let char = self.source[self.offset]
    if char == '#' {
      self.offset = self.offset + 1
      continue
    }
    if char == '/' && self.peek_at(1) == Some('*') {
      nesting = nesting + 1
      self.offset = self.offset + 2
      continue
    }
    if char == '*' && self.peek_at(1) == Some('/') {
      nesting = nesting - 1
      self.offset = self.offset + 2
      continue
    }
    self.offset = self.offset + 1
  }
}

///|
fn is_identifier_start(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char == '_'
}

///|
fn is_identifier_continue(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
}

///|
fn is_number_start(char : Char) -> Bool {
  char.is_ascii_digit() || char == '-' || char == '+'
}

///|
fn RonParser::try_identifier(self : RonParser) -> String? {
  match self.peek() {
    Some(char) if is_identifier_start(char) => {
      let buffer = StringBuilder()
      buffer.write_char(char)
      self.offset = self.offset + 1
      while self.offset < self.source.length() &&
            is_identifier_continue(self.source[self.offset]) {
        buffer.write_char(self.source[self.offset])
        self.offset = self.offset + 1
      }
      Some(buffer.to_string())
    }
    _ => None
  }
}

///|
fn RonParser::parse_identifier(self : RonParser) -> String raise RonError {
  match self.try_identifier() {
    Some(name) => name
    None =>
      match self.peek() {
        Some(char) => raise self.error_char(char)
        None => raise self.error_eof()
      }
  }
}

///|
fn RonParser::parse_path(self : RonParser) -> String raise RonError {
  let buffer = StringBuilder()
  buffer.write_string(self.parse_identifier())
  while self.peek() == Some(':') && self.peek_at(1) == Some(':') {
    self.offset = self.offset + 2
    buffer.write_string("::")
    buffer.write_string(self.parse_identifier())
  }
  buffer.to_string()
}

///|
fn split_path(path : String) -> (String, String)? {
  match path.rev_find("::") {
    Some(index) => {
      let owner = path.unsafe_substring(start=0, end=index)
      let variant = path.unsafe_substring(start=index + 2, end=path.length())
      Some((owner, variant))
    }
    None => None
  }
}

///|
fn is_type_name(path : String) -> Bool {
  match path.get_char(0) {
    Some(char) => char.is_ascii_uppercase()
    None => false
  }
}

///|
fn RonParser::parse_value(
  self : RonParser,
  depth : Int,
) -> RonValue raise RonError {
  if depth > self.max_nesting_depth {
    raise DepthLimitExceeded(self.max_nesting_depth)
  }
  self.skip_trivia()
  match self.peek() {
    Some('(') => self.parse_tuple(depth)
    Some('[') => self.parse_sequence(depth)
    Some('{') => self.parse_map(depth)
    Some('"') => RonValue::String(self.parse_string_literal())
    Some('\'') => RonValue::Char(self.parse_char_literal())
    Some('b') =>
      match self.peek_at(1) {
        Some('"') => RonValue::Bytes(self.parse_byte_string())
        Some('r') => RonValue::Bytes(self.parse_raw_byte_string())
        Some('\'') => RonValue::Byte(self.parse_byte_char())
        _ => self.parse_identifier_value(depth)
      }
    Some('r') =>
      match self.peek_at(1) {
        Some('"') | Some('#') => RonValue::String(self.parse_raw_string())
        _ => self.parse_identifier_value(depth)
      }
    Some(char) if is_number_start(char) => self.parse_number()
    Some(char) if is_identifier_start(char) =>
      self.parse_identifier_value(depth)
    Some(char) => raise self.error_char(char)
    None => raise self.error_eof()
  }
}

///|
fn RonParser::parse_identifier_value(
  self : RonParser,
  depth : Int,
) -> RonValue raise RonError {
  let path = self.parse_path()
  self.skip_trivia()
  if self.peek() == Some('(') {
    let (fields, values) = self.parse_payload(depth)
    if path == "Some" {
      if fields.length() == 0 && values.length() == 1 {
        return RonValue::Option(Some(values[0]))
      }
      raise self.error_value("Some expects exactly one positional value")
    }
    match split_path(path) {
      Some((owner, variant)) =>
        if fields.length() == 0 && values.length() == 0 {
          RonValue::Enum(owner, variant, [])
        } else if fields.length() == 0 {
          RonValue::EnumTuple(owner, variant, values)
        } else {
          RonValue::Enum(owner, variant, fields)
        }
      None =>
        if fields.length() == 0 && values.length() == 0 {
          RonValue::Struct(path, [])
        } else if fields.length() == 0 {
          RonValue::TupleStruct(path, values)
        } else {
          RonValue::Struct(path, fields)
        }
    }
  } else {
    match path {
      "true" => RonValue::Bool(true)
      "false" => RonValue::Bool(false)
      "None" => RonValue::Option(None)
      "NaN" | "nan" => RonValue::Number(NaN)
      "inf" | "Infinity" | "infinity" => RonValue::Number(Infinity)
      _ =>
        match split_path(path) {
          Some((owner, variant)) => RonValue::Enum(owner, variant, [])
          None if is_type_name(path) => RonValue::Struct(path, [])
          None => RonValue::Identifier(path)
        }
    }
  }
}

///|
fn RonParser::parse_comma_or_end(
  self : RonParser,
  end : Char,
) -> Bool raise RonError {
  self.skip_trivia()
  match self.peek() {
    Some(char) if char == ',' => {
      self.offset = self.offset + 1
      self.skip_trivia()
      if self.peek() == Some(end) {
        self.offset = self.offset + 1
        true
      } else {
        false
      }
    }
    Some(char) if char == end => {
      self.offset = self.offset + 1
      true
    }
    Some(char) => raise self.error_char(char)
    None => raise self.error_eof()
  }
}

///|
fn RonParser::parse_tuple(
  self : RonParser,
  depth : Int,
) -> RonValue raise RonError {
  self.expect('(')
  self.skip_trivia()
  if self.peek() == Some(')') {
    self.offset = self.offset + 1
    return RonValue::Unit
  }
  if self.looks_like_named_field() {
    let fields = []
    while true {
      let name = self.parse_identifier()
      self.skip_trivia()
      self.expect(':')
      fields.push((name, self.parse_value(depth + 1)))
      if self.parse_comma_or_end(')') {
        break
      }
    }
    return RonValue::Struct("", fields)
  }
  let values = []
  while true {
    values.push(self.parse_value(depth + 1))
    if self.parse_comma_or_end(')') {
      break
    }
  }
  RonValue::Tuple(values)
}

///|
fn RonParser::parse_sequence(
  self : RonParser,
  depth : Int,
) -> RonValue raise RonError {
  self.expect('[')
  self.skip_trivia()
  let values = []
  if self.peek() == Some(']') {
    self.offset = self.offset + 1
    return RonValue::Sequence(values)
  }
  while true {
    values.push(self.parse_value(depth + 1))
    if self.parse_comma_or_end(']') {
      break
    }
  }
  RonValue::Sequence(values)
}

///|
fn RonParser::parse_map(
  self : RonParser,
  depth : Int,
) -> RonValue raise RonError {
  self.expect('{')
  self.skip_trivia()
  let entries = []
  if self.peek() == Some('}') {
    self.offset = self.offset + 1
    return RonValue::Map(entries)
  }
  while true {
    let key = self.parse_value(depth + 1)
    self.skip_trivia()
    self.expect(':')
    let value = self.parse_value(depth + 1)
    entries.push((key, value))
    if self.parse_comma_or_end('}') {
      break
    }
  }
  RonValue::Map(entries)
}

///|
fn RonParser::looks_like_named_field(self : RonParser) -> Bool {
  let saved = self.offset
  let result = try {
    self.try_identifier() |> ignore
    self.skip_trivia()
    self.peek() == Some(':')
  } catch {
    _ => false
  }
  self.offset = saved
  result
}

///|
fn RonParser::parse_payload(
  self : RonParser,
  depth : Int,
) -> (Array[(String, RonValue)], Array[RonValue]) raise RonError {
  self.expect('(')
  self.skip_trivia()
  let fields = []
  let values = []
  if self.peek() == Some(')') {
    self.offset = self.offset + 1
    return (fields, values)
  }
  if self.looks_like_named_field() {
    while true {
      let name = self.parse_identifier()
      self.skip_trivia()
      self.expect(':')
      fields.push((name, self.parse_value(depth + 1)))
      if self.parse_comma_or_end(')') {
        break
      }
    }
  } else {
    while true {
      values.push(self.parse_value(depth + 1))
      if self.parse_comma_or_end(')') {
        break
      }
    }
  }
  (fields, values)
}

///|
fn RonParser::parse_escape(self : RonParser) -> Char raise RonError {
  match self.advance() {
    Some('n') => '\n'
    Some('r') => '\r'
    Some('t') => '\t'
    Some('0') => '\u{0}'
    Some('\\') => '\\'
    Some('"') => '"'
    Some('\'') => '\''
    Some('/') => '/'
    Some('x') => {
      let value = self.parse_hex_digits(2)
      if value > 0xff {
        raise self.error_escape()
      }
      value.unsafe_to_char()
    }
    Some('u') => {
      self.expect('{')
      let value = self.parse_variable_hex_digits()
      self.expect('}')
      if value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff) {
        raise self.error_escape()
      }
      value.unsafe_to_char()
    }
    Some(_) => raise self.error_escape()
    None => raise self.error_eof()
  }
}

///|
fn RonParser::parse_hex_digits(
  self : RonParser,
  count : Int,
) -> Int raise RonError {
  let mut value = 0
  for i = 0; i < count; i = i + 1 {
    let digit = match self.advance() {
      Some('0'..='9' as char) => char.to_int() - '0'.to_int()
      Some('a'..='f' as char) => char.to_int() - 'a'.to_int() + 10
      Some('A'..='F' as char) => char.to_int() - 'A'.to_int() + 10
      Some(_) => raise self.error_escape()
      None => raise self.error_eof()
    }
    value = (value << 4) | digit
  }
  value
}

///|
fn RonParser::parse_variable_hex_digits(self : RonParser) -> Int raise RonError {
  let mut value = 0
  let mut digits = 0
  while self.peek() != Some('}') {
    if digits == 6 {
      raise self.error_escape()
    }
    let digit = match self.advance() {
      Some('0'..='9' as char) => char.to_int() - '0'.to_int()
      Some('a'..='f' as char) => char.to_int() - 'a'.to_int() + 10
      Some('A'..='F' as char) => char.to_int() - 'A'.to_int() + 10
      Some(_) => raise self.error_escape()
      None => raise self.error_eof()
    }
    value = (value << 4) | digit
    digits = digits + 1
  }
  if digits == 0 {
    raise self.error_escape()
  }
  value
}

///|
fn RonParser::parse_string_literal(self : RonParser) -> String raise RonError {
  self.expect('"')
  let buffer = StringBuilder()
  while true {
    match self.advance() {
      Some('"') => return buffer.to_string()
      Some('\\') => buffer.write_char(self.parse_escape())
      Some(char) if char.to_int() < 0x20 => raise self.error_char(char)
      Some(char) => buffer.write_char(char)
      None => raise self.error_eof()
    }
  }
  abort("unreachable")
}

///|
fn RonParser::parse_char_literal(self : RonParser) -> Char raise RonError {
  self.expect('\'')
  let char = match self.advance() {
    Some('\\') => self.parse_escape()
    Some('\'') => raise self.error_escape()
    Some(char) if char.to_int() < 0x20 => raise self.error_char(char)
    Some(char) => char
    None => raise self.error_eof()
  }
  self.expect('\'')
  char
}

///|
fn RonParser::parse_byte_escape(self : RonParser) -> Byte raise RonError {
  match self.advance() {
    Some('n') => '\n'.to_int().to_byte()
    Some('r') => '\r'.to_int().to_byte()
    Some('t') => '\t'.to_int().to_byte()
    Some('0') => Byte::default()
    Some('\\') => '\\'.to_int().to_byte()
    Some('"') => '"'.to_int().to_byte()
    Some('\'') => '\''.to_int().to_byte()
    Some('/') => '/'.to_int().to_byte()
    Some('x') => self.parse_hex_digits(2).to_byte()
    Some(_) => raise self.error_escape()
    None => raise self.error_eof()
  }
}

///|
fn RonParser::parse_byte_string(self : RonParser) -> Bytes raise RonError {
  self.expect('b')
  self.expect('"')
  let bytes = []
  while true {
    match self.advance() {
      Some('"') => return Bytes::from_array(bytes)
      Some('\\') => bytes.push(self.parse_byte_escape())
      Some(char) if char.to_int() <= 0x7f => bytes.push(char.to_int().to_byte())
      Some(char) => raise self.error_char(char)
      None => raise self.error_eof()
    }
  }
  abort("unreachable")
}

///|
fn RonParser::parse_byte_char(self : RonParser) -> Byte raise RonError {
  self.expect('b')
  self.expect('\'')
  let byte = match self.advance() {
    Some('\\') => self.parse_byte_escape()
    Some(char) if char.to_int() <= 0x7f => char.to_int().to_byte()
    Some(char) => raise self.error_char(char)
    None => raise self.error_eof()
  }
  self.expect('\'')
  byte
}

///|
fn RonParser::parse_raw_string(self : RonParser) -> String raise RonError {
  self.expect('r')
  let hashes = self.count_raw_hashes()
  self.expect('"')
  let buffer = StringBuilder()
  while true {
    match self.advance() {
      Some('"') if self.consume_hash_suffix(hashes) => return buffer.to_string()
      Some(char) => buffer.write_char(char)
      None => raise self.error_eof()
    }
  }
  abort("unreachable")
}

///|
fn RonParser::parse_raw_byte_string(self : RonParser) -> Bytes raise RonError {
  self.expect('b')
  self.expect('r')
  let hashes = self.count_raw_hashes()
  self.expect('"')
  let bytes = []
  while true {
    match self.advance() {
      Some('"') if self.consume_hash_suffix(hashes) =>
        return Bytes::from_array(bytes)
      Some(char) if char.to_int() <= 0x7f => bytes.push(char.to_int().to_byte())
      Some(char) => raise self.error_char(char)
      None => raise self.error_eof()
    }
  }
  abort("unreachable")
}

///|
fn RonParser::count_raw_hashes(self : RonParser) -> Int {
  let mut count = 0
  while self.peek() == Some('#') {
    count = count + 1
    self.offset = self.offset + 1
  }
  count
}

///|
fn RonParser::consume_hash_suffix(self : RonParser, count : Int) -> Bool {
  if count == 0 {
    return true
  }
  for i = 0; i < count; i = i + 1 {
    if self.peek_at(i) != Some('#') {
      return false
    }
  }
  self.offset = self.offset + count
  true
}

///|
fn is_number_char(char : Char) -> Bool {
  char.is_ascii_alphabetic() ||
  char.is_ascii_digit() ||
  char == '_' ||
  char == '.' ||
  char == '+' ||
  char == '-'
}

///|
fn RonParser::parse_number(self : RonParser) -> RonValue raise RonError {
  let start = self.offset
  let buffer = StringBuilder()
  while self.offset < self.source.length() &&
        is_number_char(self.source[self.offset]) {
    buffer.write_char(self.source[self.offset])
    self.offset = self.offset + 1
  }
  let token = buffer.to_string()
  let lower = token.to_lower()
  if token.length() == 0 {
    raise self.error_eof()
  }
  if lower == "inf" ||
    lower == "+inf" ||
    lower == "infinity" ||
    lower == "+infinity" {
    return RonValue::Number(Infinity)
  }
  if lower == "-inf" || lower == "-infinity" {
    return RonValue::Number(NegativeInfinity)
  }
  if lower == "nan" || lower == "+nan" || lower == "-nan" {
    return RonValue::Number(NaN)
  }
  if token.contains(".") || lower.contains("e") {
    return RonValue::Number(Float(@string.parse_double(token))) catch {
      _ => {
        self.offset = start + token.length()
        raise self.error_number(token)
      }
    }
  }
  try {
    if token.has_prefix("-") {
      RonValue::Number(Signed(@string.parse_int64(token, base=0)))
    } else {
      let value = @string.parse_uint64(token, base=0)
      if value <= 0x7fffffffffffffffUL {
        RonValue::Number(Signed(value.reinterpret_as_int64()))
      } else {
        RonValue::Number(Unsigned(value))
      }
    }
  } catch {
    _ => {
      self.offset = start + token.length()
      raise self.error_number(token)
    }
  }
}
