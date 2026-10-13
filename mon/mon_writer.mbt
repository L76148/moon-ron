///|
/// Errors raised while writing a MON document.
///
/// The writer refuses exactly the values the grammar cannot spell, so
/// everything it does write is text that `parse` reads back as an equal value.
pub(all) suberror MonWriteError {
  /// A number with no MoonBit literal spelling, such as an infinity.
  UnrepresentableNumber(MonNumber)
  /// A value the grammar cannot express, such as a tuple with no elements.
  UnrepresentableValue(String)
  /// A name that is not a MON name.
  InvalidName(String)
} derive(Eq, Debug)

///|
pub extend MonWriteError with Eq::{not_equal, equal}

///|
pub extend MonWriteError with @debug.Debug::{to_repr}

///|
/// Write a MON document in canonical compact form.
pub fn to_string(value : MonValue) -> String raise MonWriteError {
  let writer = MonWriter::{ buffer: StringBuilder(), indent: 0, pretty: false, }
  writer.write(value, 0)
  writer.text()
}

///|
/// Write a MON document with deterministic multiline formatting.
///
/// `indent` is the number of spaces added for each nesting level. Negative
/// values are treated as zero, and empty containers stay on one line.
pub fn to_string_pretty(
  value : MonValue,
  indent~ : Int32 = 2,
) -> String raise MonWriteError {
  let writer = MonWriter::{
    buffer: StringBuilder(),
    indent: indent.max(0),
    pretty: true,
  }
  writer.write(value, 0)
  writer.text()
}

///|
priv struct MonWriter {
  buffer : StringBuilder
  indent : Int32
  pretty : Bool
}

///|
fn MonWriter::text(self : MonWriter) -> String {
  self.buffer.to_string()
}

///|
fn MonWriter::write(
  self : MonWriter,
  value : MonValue,
  level : Int32,
) -> Unit raise MonWriteError {
  match value {
    Unit => self.buffer.write_string("()")
    Bool(value) =>
      self.buffer.write_string(if value { "true" } else { "false" })
    Number(value) => self.write_number(value)
    Char(value) => self.write_char(value)
    String(value) => self.write_string(value)
    Bytes(value) => self.write_bytes(value)
    Byte(value) => self.write_byte(value)
    Sequence(values) => self.write_items(values, level, '[', ']')
    Tuple(values) => self.write_tuple(values, level)
    Map(entries) => self.write_map(entries, level)
    Fields(fields) => self.write_fields(fields, level)
    Record(name, fields) => {
      self.write_name(name)
      self.buffer.write_char(' ')
      self.write_fields(fields, level)
    }
    TupleVariant(name, values) => {
      self.write_name(name)
      self.write_items(values, level, '(', ')')
    }
    Variant(name) => self.write_name(name)
    Range(range) => self.write_range(range, level)
  }
}

///|
/// Write a comma-separated container between `open` and `close`.
fn MonWriter::write_items(
  self : MonWriter,
  values : Array[MonValue],
  level : Int32,
  open : Char,
  close : Char,
) -> Unit raise MonWriteError {
  self.buffer.write_char(open)
  if values.length() == 0 {
    self.buffer.write_char(close)
    return
  }
  if !self.pretty {
    for i = 0; i < values.length(); i = i + 1 {
      if i > 0 {
        self.buffer.write_string(", ")
      }
      self.write(values[i], level)
    }
    self.buffer.write_char(close)
    return
  }
  for i = 0; i < values.length(); i = i + 1 {
    self.write_indent(level + 1)
    self.write(values[i], level + 1)
    self.buffer.write_char(',')
  }
  self.write_indent(level)
  self.buffer.write_char(close)
}

///|
/// Write a tuple. MoonBit has no one-element tuple, so the compact form keeps
/// the trailing comma that makes `(1,)` read back as a tuple instead of `1`.
fn MonWriter::write_tuple(
  self : MonWriter,
  values : Array[MonValue],
  level : Int32,
) -> Unit raise MonWriteError {
  if values.length() == 0 {
    raise UnrepresentableValue("a tuple needs at least one element")
  }
  if values.length() == 1 && !self.pretty {
    self.buffer.write_char('(')
    self.write(values[0], level)
    self.buffer.write_string(",)")
    return
  }
  self.write_items(values, level, '(', ')')
}

///|
fn MonWriter::write_fields(
  self : MonWriter,
  fields : Array[(String, MonValue)],
  level : Int32,
) -> Unit raise MonWriteError {
  if fields.length() == 0 {
    self.buffer.write_string("{}")
    return
  }
  if !self.pretty {
    self.buffer.write_string("{ ")
    for i = 0; i < fields.length(); i = i + 1 {
      if i > 0 {
        self.buffer.write_string(", ")
      }
      let (name, value) = fields[i]
      self.write_field_name(name)
      self.buffer.write_string(": ")
      self.write(value, level)
    }
    self.buffer.write_string(" }")
    return
  }
  self.buffer.write_char('{')
  for i = 0; i < fields.length(); i = i + 1 {
    self.write_indent(level + 1)
    let (name, value) = fields[i]
    self.write_field_name(name)
    self.buffer.write_string(": ")
    self.write(value, level + 1)
    self.buffer.write_char(',')
  }
  self.write_indent(level)
  self.buffer.write_char('}')
}

///|
fn MonWriter::write_map(
  self : MonWriter,
  entries : Array[(MonValue, MonValue)],
  level : Int32,
) -> Unit raise MonWriteError {
  if entries.length() == 0 {
    self.buffer.write_string("{}")
    return
  }
  if !self.pretty {
    self.buffer.write_string("{ ")
    for i = 0; i < entries.length(); i = i + 1 {
      if i > 0 {
        self.buffer.write_string(", ")
      }
      let (key, value) = entries[i]
      self.write(key, level)
      self.buffer.write_string(": ")
      self.write(value, level)
    }
    self.buffer.write_string(" }")
    return
  }
  self.buffer.write_char('{')
  for i = 0; i < entries.length(); i = i + 1 {
    self.write_indent(level + 1)
    let (key, value) = entries[i]
    self.write(key, level + 1)
    self.buffer.write_string(": ")
    self.write(value, level + 1)
    self.buffer.write_char(',')
  }
  self.write_indent(level)
  self.buffer.write_char('}')
}

///|
fn MonWriter::write_range(
  self : MonWriter,
  range : MonRange,
  level : Int32,
) -> Unit raise MonWriteError {
  match range.start {
    Some(value) => self.write(value, level)
    None => ()
  }
  self.buffer.write_string(if range.inclusive { "..=" } else { ".." })
  match range.end {
    Some(value) => self.write(value, level)
    None => ()
  }
}

///|
fn MonWriter::write_number(
  self : MonWriter,
  number : MonNumber,
) -> Unit raise MonWriteError {
  match number {
    Int(value) => self.buffer.write_string(value.to_string())
    Int64(value) => self.buffer.write_string(value.to_string() + "L")
    UInt(value) => self.buffer.write_string(value.to_string() + "U")
    UInt64(value) => self.buffer.write_string(value.to_string() + "UL")
    Double(value) => self.buffer.write_string(double_literal(value))
  }
}

///|
/// Write a double so that it reads back as a `Double`.
///
/// MoonBit prints `3.0` as `3` and `1.0e-7` as `1e-7`, and neither reads back
/// as a double, so the decimal point is restored. Infinities and NaN have no
/// MoonBit literal at all and are refused.
fn double_literal(value : Double) -> String raise MonWriteError {
  if value.is_nan() || value.is_inf() {
    raise UnrepresentableNumber(Double(value))
  }
  let text = value.to_string()
  if text.contains(".") {
    return text
  }
  match exponent_index(text) {
    Some(index) =>
      text.unsafe_substring(start=0, end=index) +
      ".0" +
      text.unsafe_substring(start=index, end=text.length())
    None => text + ".0"
  }
}

///|
/// The index of the exponent marker in a printed double, when it has one.
fn exponent_index(text : String) -> Int32? {
  match text.find("e") {
    Some(index) => Some(index)
    None => text.find("E")
  }
}

///|
fn MonWriter::write_char(self : MonWriter, value : Char) -> Unit {
  self.buffer.write_char('\'')
  self.write_quoted_char(value, '\'')
  self.buffer.write_char('\'')
}

///|
fn MonWriter::write_string(self : MonWriter, value : String) -> Unit {
  self.buffer.write_char('"')
  for char in value {
    self.write_quoted_char(char, '"')
  }
  self.buffer.write_char('"')
}

///|
/// Write one character of a character or string literal, escaping whatever
/// MoonBit requires.
fn MonWriter::write_quoted_char(
  self : MonWriter,
  value : Char,
  quote : Char,
) -> Unit {
  if value == quote || value == '\\' {
    self.buffer.write_char('\\')
    self.buffer.write_char(value)
    return
  }
  match value {
    '\n' => self.buffer.write_string("\\n")
    '\r' => self.buffer.write_string("\\r")
    '\t' => self.buffer.write_string("\\t")
    '\u{8}' => self.buffer.write_string("\\b")
    '\u{c}' => self.buffer.write_string("\\f")
    _ =>
      if value.to_int() < 0x20 || value.to_int() == 0x7f {
        self.buffer.write_string("\\u{")
        self.write_hex(value.to_int())
        self.buffer.write_char('}')
      } else {
        self.buffer.write_char(value)
      }
  }
}

///|
fn MonWriter::write_byte(self : MonWriter, value : Byte) -> Unit {
  self.buffer.write_char('b')
  self.buffer.write_char('\'')
  self.write_byte_item(value, '\'')
  self.buffer.write_char('\'')
}

///|
fn MonWriter::write_bytes(self : MonWriter, value : Bytes) -> Unit {
  self.buffer.write_char('b')
  self.buffer.write_char('"')
  for i = 0; i < value.length(); i = i + 1 {
    self.write_byte_item(value[i], '"')
  }
  self.buffer.write_char('"')
}

///|
/// Write one byte inside a byte literal. Printable ASCII stays readable and
/// everything else uses the two-digit `\x..` escape that MoonBit reads.
fn MonWriter::write_byte_item(
  self : MonWriter,
  value : Byte,
  quote : Char,
) -> Unit {
  let code = value.to_int()
  if code < 0x20 ||
    code > 0x7e ||
    code == quote.to_int() ||
    code == '\\'.to_int() {
    self.buffer.write_string("\\x")
    self.write_hex_byte(value)
  } else {
    self.buffer.write_char(char_of(code))
  }
}

///|
fn MonWriter::write_hex(self : MonWriter, value : Int32) -> Unit {
  let mut shift = 20
  let mut started = false
  while shift >= 0 {
    let digit = (value >> shift) & 0xf
    if digit != 0 || started || shift == 0 {
      self.buffer.write_char(hex_digit(digit))
      started = true
    }
    shift = shift - 4
  }
}

///|
fn MonWriter::write_hex_byte(self : MonWriter, value : Byte) -> Unit {
  let code = value.to_int()
  self.buffer.write_char(hex_digit((code >> 4) & 0xf))
  self.buffer.write_char(hex_digit(code & 0xf))
}

///|
fn hex_digit(digit : Int32) -> Char {
  let code = if digit < 10 {
    '0'.to_int() + digit
  } else {
    'a'.to_int() + digit - 10
  }
  char_of(code)
}

///|
fn char_of(code : Int32) -> Char {
  match code.to_char() {
    Some(char) => char
    None => '?'
  }
}

///|
fn MonWriter::write_indent(self : MonWriter, level : Int32) -> Unit {
  self.buffer.write_char('\n')
  for i = 0; i < level * self.indent; i = i + 1 {
    self.buffer.write_char(' ')
  }
}

///|
/// Write a constructor path such as `Point` or `Color::Red`.
fn MonWriter::write_name(
  self : MonWriter,
  name : String,
) -> Unit raise MonWriteError {
  if !valid_path(name) {
    raise InvalidName(name)
  }
  self.buffer.write_string(name)
}

///|
/// Write a field name such as `x` or `max_depth`.
fn MonWriter::write_field_name(
  self : MonWriter,
  name : String,
) -> Unit raise MonWriteError {
  if !valid_field_name(name) {
    raise InvalidName(name)
  }
  self.buffer.write_string(name)
}

///|
fn valid_path(name : String) -> Bool {
  let mut segments = 0
  for segment in name.split("::") {
    if !valid_name(segment, true) {
      return false
    }
    segments = segments + 1
  }
  segments > 0
}

///|
fn valid_field_name(name : String) -> Bool {
  valid_name(name, false)
}

///|
fn valid_name(name : StringView, uppercase : Bool) -> Bool {
  let length = name.length()
  if length == 0 {
    return false
  }
  for i = 0; i < length; i = i + 1 {
    match name.get_char(i) {
      None => return false
      Some(char) =>
        if i == 0 {
          let starts = if uppercase {
            char.is_ascii_uppercase()
          } else {
            !char.is_ascii_uppercase() && is_name_start(char)
          }
          if !starts {
            return false
          }
        } else if !is_name_continue(char) {
          return false
        }
    }
  }
  true
}
