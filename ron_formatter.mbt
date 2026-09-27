///|
/// Serialize a RON value using deterministic multiline formatting.
///
/// `indent` is the number of spaces added for each nesting level. Negative
/// values are treated as zero. Empty containers remain on one line.
pub fn to_string_pretty(value : RonValue, indent? : Int = 2) -> String {
  let buffer = StringBuilder()
  write_pretty_value(buffer, value, 0, indent.max(0))
  buffer.to_string()
}

///|
fn write_pretty_value(
  buffer : StringBuilder,
  value : RonValue,
  level : Int,
  indent : Int,
) -> Unit {
  match value {
    Unit
    | Bool(_)
    | Number(_)
    | Char(_)
    | String(_)
    | Bytes(_)
    | Byte(_)
    | Identifier(_) => write_value(buffer, value)
    Option(None) => buffer.write_string("None")
    Option(Some(value)) => {
      buffer.write_string("Some(")
      write_pretty_value(buffer, value, level, indent)
      buffer.write_char(')')
    }
    Sequence(values) =>
      write_pretty_values(buffer, values, level, indent, '[', ']')
    Tuple(values) =>
      write_pretty_values(buffer, values, level, indent, '(', ')')
    Map(entries) => write_pretty_map(buffer, entries, level, indent)
    Struct(name, fields) =>
      write_pretty_fields(buffer, name, fields, level, indent)
    TupleStruct(name, values) =>
      write_pretty_named_values(buffer, name, values, level, indent)
    Enum(owner, variant, fields) =>
      write_pretty_fields(buffer, owner + "::" + variant, fields, level, indent)
    EnumTuple(owner, variant, values) =>
      write_pretty_named_values(
        buffer,
        owner + "::" + variant,
        values,
        level,
        indent,
      )
  }
}

///|
fn write_pretty_values(
  buffer : StringBuilder,
  values : Array[RonValue],
  level : Int,
  indent : Int,
  open : Char,
  close : Char,
) -> Unit {
  buffer.write_char(open)
  if values.length() == 0 {
    buffer.write_char(close)
    return
  }
  buffer.write_char('\n')
  for i = 0; i < values.length(); i = i + 1 {
    write_indent(buffer, level + 1, indent)
    write_pretty_value(buffer, values[i], level + 1, indent)
    buffer.write_string(",\n")
  }
  write_indent(buffer, level, indent)
  buffer.write_char(close)
}

///|
fn write_pretty_named_values(
  buffer : StringBuilder,
  name : String,
  values : Array[RonValue],
  level : Int,
  indent : Int,
) -> Unit {
  buffer.write_string(name)
  if values.length() == 0 {
    return
  }
  write_pretty_values(buffer, values, level, indent, '(', ')')
}

///|
fn write_pretty_map(
  buffer : StringBuilder,
  entries : Array[(RonValue, RonValue)],
  level : Int,
  indent : Int,
) -> Unit {
  buffer.write_char('{')
  if entries.length() == 0 {
    buffer.write_char('}')
    return
  }
  buffer.write_char('\n')
  for i = 0; i < entries.length(); i = i + 1 {
    let (key, value) = entries[i]
    write_indent(buffer, level + 1, indent)
    write_pretty_value(buffer, key, level + 1, indent)
    buffer.write_string(": ")
    write_pretty_value(buffer, value, level + 1, indent)
    buffer.write_string(",\n")
  }
  write_indent(buffer, level, indent)
  buffer.write_char('}')
}

///|
fn write_pretty_fields(
  buffer : StringBuilder,
  name : String,
  fields : Array[(String, RonValue)],
  level : Int,
  indent : Int,
) -> Unit {
  buffer.write_string(name)
  if fields.length() == 0 {
    return
  }
  buffer.write_string("(\n")
  for i = 0; i < fields.length(); i = i + 1 {
    let (name, value) = fields[i]
    write_indent(buffer, level + 1, indent)
    buffer.write_string(name)
    buffer.write_string(": ")
    write_pretty_value(buffer, value, level + 1, indent)
    buffer.write_string(",\n")
  }
  write_indent(buffer, level, indent)
  buffer.write_char(')')
}

///|
fn write_indent(buffer : StringBuilder, level : Int, indent : Int) -> Unit {
  let count = level * indent
  for i = 0; i < count; i = i + 1 {
    buffer.write_char(' ')
  }
}
