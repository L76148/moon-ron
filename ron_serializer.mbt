///|
/// Serialize a RON value using the parser's canonical compact syntax.
///
/// The result is valid input for `parse` whenever names and identifiers in
/// the value satisfy the RON identifier grammar. Floating-point values that
/// would otherwise look like integers keep a `.0` suffix.
pub fn to_string(value : RonValue) -> String {
  let buffer = StringBuilder()
  write_value(buffer, value)
  buffer.to_string()
}

///|
fn write_value(buffer : StringBuilder, value : RonValue) -> Unit {
  match value {
    Unit => buffer.write_string("()")
    Bool(value) => buffer.write_string(if value { "true" } else { "false" })
    Number(value) => write_number(buffer, value)
    Char(value) => write_char(buffer, value)
    String(value) => write_string(buffer, value)
    Bytes(value) => write_byte_string(buffer, value)
    Byte(value) => write_byte_char(buffer, value)
    Option(value) =>
      match value {
        Some(value) => {
          buffer.write_string("Some(")
          write_value(buffer, value)
          buffer.write_char(')')
        }
        None => buffer.write_string("None")
      }
    Sequence(values) => {
      buffer.write_char('[')
      write_values(buffer, values)
      buffer.write_char(']')
    }
    Tuple(values) => {
      buffer.write_char('(')
      write_values(buffer, values)
      buffer.write_char(')')
    }
    Map(entries) => {
      buffer.write_char('{')
      for i = 0; i < entries.length(); i = i + 1 {
        if i > 0 {
          buffer.write_string(", ")
        }
        let (key, value) = entries[i]
        write_value(buffer, key)
        buffer.write_string(": ")
        write_value(buffer, value)
      }
      buffer.write_char('}')
    }
    Struct(name, fields) => {
      buffer.write_string(name)
      if fields.length() > 0 {
        buffer.write_char('(')
        write_fields(buffer, fields)
        buffer.write_char(')')
      }
    }
    TupleStruct(name, values) => {
      buffer.write_string(name)
      buffer.write_char('(')
      write_values(buffer, values)
      buffer.write_char(')')
    }
    Enum(owner, variant, fields) => {
      buffer.write_string(owner)
      buffer.write_string("::")
      buffer.write_string(variant)
      if fields.length() > 0 {
        buffer.write_char('(')
        write_fields(buffer, fields)
        buffer.write_char(')')
      }
    }
    EnumTuple(owner, variant, values) => {
      buffer.write_string(owner)
      buffer.write_string("::")
      buffer.write_string(variant)
      buffer.write_char('(')
      write_values(buffer, values)
      buffer.write_char(')')
    }
    Identifier(name) => buffer.write_string(name)
  }
}

///|
fn write_values(buffer : StringBuilder, values : Array[RonValue]) -> Unit {
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      buffer.write_string(", ")
    }
    write_value(buffer, values[i])
  }
}

///|
fn write_fields(
  buffer : StringBuilder,
  fields : Array[(String, RonValue)],
) -> Unit {
  for i = 0; i < fields.length(); i = i + 1 {
    if i > 0 {
      buffer.write_string(", ")
    }
    let (name, value) = fields[i]
    buffer.write_string(name)
    buffer.write_string(": ")
    write_value(buffer, value)
  }
}

///|
fn write_number(buffer : StringBuilder, value : RonNumber) -> Unit {
  match value {
    Signed(value) => buffer.write_string(value.to_string())
    Unsigned(value) => buffer.write_string(value.to_string())
    Float(value) => write_float(buffer, value)
    Infinity => buffer.write_string("inf")
    NegativeInfinity => buffer.write_string("-inf")
    NaN => buffer.write_string("NaN")
  }
}

///|
fn write_float(buffer : StringBuilder, value : Double) -> Unit {
  let text = value.to_string()
  buffer.write_string(text)
  if !text.contains(".") && !text.contains("e") && !text.contains("E") {
    buffer.write_string(".0")
  }
}

///|
fn write_string(buffer : StringBuilder, value : String) -> Unit {
  buffer.write_char('"')
  for char in value {
    write_escaped_char(buffer, char, '"')
  }
  buffer.write_char('"')
}

///|
fn write_char(buffer : StringBuilder, value : Char) -> Unit {
  buffer.write_char('\'')
  write_escaped_char(buffer, value, '\'')
  buffer.write_char('\'')
}

///|
fn write_escaped_char(
  buffer : StringBuilder,
  value : Char,
  quote : Char,
) -> Unit {
  match value {
    '\n' => buffer.write_string("\\n")
    '\r' => buffer.write_string("\\r")
    '\t' => buffer.write_string("\\t")
    '\u{0}' => buffer.write_string("\\0")
    '\\' => buffer.write_string("\\\\")
    value if value == quote => {
      buffer.write_char('\\')
      buffer.write_char(value)
    }
    value => {
      let code = value.to_int()
      if code < 0x20 || code == 0x7f {
        buffer.write_string("\\u{")
        buffer.write_string(code.to_string(radix=16))
        buffer.write_char('}')
      } else {
        buffer.write_char(value)
      }
    }
  }
}

///|
fn write_byte_string(buffer : StringBuilder, value : Bytes) -> Unit {
  buffer.write_string("b\"")
  for i = 0; i < value.length(); i = i + 1 {
    write_escaped_byte(buffer, value[i], '"')
  }
  buffer.write_char('"')
}

///|
fn write_byte_char(buffer : StringBuilder, value : Byte) -> Unit {
  buffer.write_string("b'")
  write_escaped_byte(buffer, value, '\'')
  buffer.write_char('\'')
}

///|
fn write_escaped_byte(
  buffer : StringBuilder,
  value : Byte,
  quote : Char,
) -> Unit {
  match value.to_int() {
    value if value == quote.to_int() => {
      buffer.write_char('\\')
      buffer.write_char(quote)
    }
    10 => buffer.write_string("\\n")
    13 => buffer.write_string("\\r")
    9 => buffer.write_string("\\t")
    92 => buffer.write_string("\\\\")
    value if value >= 0x20 && value <= 0x7e =>
      buffer.write_char(value.unsafe_to_char())
    value => {
      buffer.write_string("\\x")
      buffer.write_char(hex_digit(value >> 4))
      buffer.write_char(hex_digit(value & 0xf))
    }
  }
}

///|
fn hex_digit(value : Int) -> Char {
  if value < 10 {
    ('0'.to_int() + value).unsafe_to_char()
  } else {
    ('a'.to_int() + value - 10).unsafe_to_char()
  }
}
