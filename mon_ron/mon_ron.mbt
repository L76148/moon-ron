///|
/// Errors raised while converting between MON and RON values.
///
/// The two notations share one data model, and three shapes belong to only one
/// of them: RON spells bare identifiers, infinities, and NaN, while MON has no
/// free variables and no literal for a non-finite double.
pub(all) suberror MonConvertError {
  /// RON has bare identifiers; MON has no free variables.
  UnrepresentableIdentifier(String)
  /// RON spells infinities and NaN; MoonBit has no literal for them.
  UnrepresentableNumber(String)
  /// `Some` takes exactly one positional value.
  InvalidOption(Int32)
} derive(Eq, Debug)

///|
pub extend MonConvertError with Eq::{not_equal, equal}

///|
pub extend MonConvertError with @debug.Debug::{to_repr}

///|
/// The message of a conversion error.
pub fn MonConvertError::message(self : MonConvertError) -> String {
  match self {
    UnrepresentableIdentifier(name) =>
      "MON has no free variables, so the identifier `" +
      name +
      "` has no MON value"
    UnrepresentableNumber(name) =>
      "MON has no literal for " + name + ", because MoonBit has none"
    InvalidOption(count) =>
      "`Some` takes exactly one value, but " + count.to_string() + " were given"
  }
}

///|
/// Convert a MON value into the RON value that holds the same data.
///
/// MON and RON share a data model, so the conversion is lossless except for
/// the shapes only one notation spells:
///
/// - `Fields` becomes a RON map with identifier keys, which is the shape RON's
///   reader produces for `{ field: value }`.
/// - `Some(value)` and `None` become a RON `Option`, because that is what RON
///   reads those spellings as.
/// - `Name { field: value }` and `Name(value)` become a RON struct and tuple
///   struct, and a qualified name becomes a RON enum.
///
/// The result is a `RonValue` rather than a bare `ToRon` implementation
/// because `Some` with the wrong number of values has to be reported, and the
/// `ToRon` trait cannot raise.
pub fn to_ron(value : @mon.MonValue) -> @ron.RonValue raise MonConvertError {
  match value {
    Unit => @ron.RonValue::Unit
    Bool(value) => @ron.RonValue::Bool(value)
    Number(value) => @ron.RonValue::Number(to_ron_number(value))
    Char(value) => @ron.RonValue::Char(value)
    String(value) => @ron.RonValue::String(value)
    Bytes(value) => @ron.RonValue::Bytes(value)
    Byte(value) => @ron.RonValue::Byte(value)
    Sequence(values) => @ron.RonValue::Sequence(to_ron_values(values))
    Tuple(values) => @ron.RonValue::Tuple(to_ron_values(values))
    Map(entries) => @ron.RonValue::Map(to_ron_entries(entries))
    Fields(fields) => @ron.RonValue::Map(to_ron_fields_as_identifiers(fields))
    Record(name, fields) => to_ron_record(name, fields)
    TupleVariant(name, values) => to_ron_variant(name, values)
    Variant(name) => to_ron_variant(name, [])
    Range(range) =>
      @ron.RonValue::Range({
        start: to_ron_optional(range.start),
        end: to_ron_optional(range.end),
        inclusive: range.inclusive,
      })
  }
}

///|
/// Convert a RON value into the MON value that holds the same data.
///
/// This is the inverse of `to_ron` for everything a MON document can hold. It
/// refuses the RON shapes MON cannot spell: a bare identifier, and a double
/// that is an infinity or a NaN.
pub fn from_ron(value : @ron.RonValue) -> @mon.MonValue raise MonConvertError {
  match value {
    Unit => @mon.MonValue::Unit
    Bool(value) => @mon.MonValue::Bool(value)
    Number(value) => @mon.MonValue::Number(from_ron_number(value))
    Char(value) => @mon.MonValue::Char(value)
    String(value) => @mon.MonValue::String(value)
    Bytes(value) => @mon.MonValue::Bytes(value)
    Byte(value) => @mon.MonValue::Byte(value)
    Option(value) =>
      match value {
        Some(value) => @mon.MonValue::TupleVariant("Some", [from_ron(value)])
        None => @mon.MonValue::Variant("None")
      }
    Sequence(values) => @mon.MonValue::Sequence(from_ron_values(values))
    Tuple(values) => @mon.MonValue::Tuple(from_ron_values(values))
    Map(entries) => from_ron_map(entries)
    Struct(name, fields) =>
      if name.length() == 0 {
        @mon.MonValue::Fields(from_ron_fields(fields))
      } else if fields.length() == 0 {
        @mon.MonValue::Variant(name)
      } else {
        @mon.MonValue::Record(name, from_ron_fields(fields))
      }
    TupleStruct(name, values) =>
      @mon.MonValue::TupleVariant(name, from_ron_values(values))
    Enum(owner, variant, fields) =>
      if fields.length() == 0 {
        @mon.MonValue::Variant(owner + "::" + variant)
      } else {
        @mon.MonValue::Record(owner + "::" + variant, from_ron_fields(fields))
      }
    EnumTuple(owner, variant, values) =>
      @mon.MonValue::TupleVariant(
        owner + "::" + variant,
        from_ron_values(values),
      )
    Range(range) =>
      @mon.MonValue::Range({
        start: from_ron_optional(range.start),
        end: from_ron_optional(range.end),
        inclusive: range.inclusive,
      })
    Identifier(name) => raise UnrepresentableIdentifier(name)
  }
}

///|
fn to_ron_number(number : @mon.MonNumber) -> @ron.RonNumber {
  match number {
    Int(value) => @ron.RonNumber::Signed(value.to_int64())
    Int64(value) => @ron.RonNumber::Signed(value)
    UInt(value) => @ron.RonNumber::Unsigned(value.to_uint64())
    UInt64(value) => @ron.RonNumber::Unsigned(value)
    Double(value) => @ron.RonNumber::Float(value)
  }
}

///|
/// MON spells a wide number with a suffix, RON keeps it as one number, so the
/// narrowest MON type that holds the value is used.
fn from_ron_number(
  number : @ron.RonNumber,
) -> @mon.MonNumber raise MonConvertError {
  match number {
    Signed(value) =>
      if value >= -2147483648L && value <= 2147483647L {
        @mon.MonNumber::Int(value.to_int())
      } else {
        @mon.MonNumber::Int64(value)
      }
    Unsigned(value) =>
      if value <= 4294967295UL {
        @mon.MonNumber::UInt(value.to_uint())
      } else {
        @mon.MonNumber::UInt64(value)
      }
    Float(value) =>
      if value.is_nan() || value.is_inf() {
        raise UnrepresentableNumber(value.to_string())
      } else {
        @mon.MonNumber::Double(value)
      }
    Infinity => raise UnrepresentableNumber("Infinity")
    NegativeInfinity => raise UnrepresentableNumber("-Infinity")
    NaN => raise UnrepresentableNumber("NaN")
  }
}

///|
fn to_ron_record(
  name : String,
  fields : Array[(String, @mon.MonValue)],
) -> @ron.RonValue raise MonConvertError {
  match split_path(name) {
    Some((owner, variant)) =>
      @ron.RonValue::Enum(owner, variant, to_ron_fields(fields))
    None => @ron.RonValue::Struct(name, to_ron_fields(fields))
  }
}

///|
fn to_ron_variant(
  name : String,
  values : Array[@mon.MonValue],
) -> @ron.RonValue raise MonConvertError {
  if name == "None" && values.length() == 0 {
    return @ron.RonValue::Option(None)
  }
  if name == "Some" {
    if values.length() == 1 {
      return @ron.RonValue::Option(Some(to_ron(values[0])))
    }
    raise InvalidOption(values.length())
  }
  match split_path(name) {
    Some((owner, variant)) =>
      if values.length() == 0 {
        @ron.RonValue::Enum(owner, variant, [])
      } else {
        @ron.RonValue::EnumTuple(owner, variant, to_ron_values(values))
      }
    None =>
      if values.length() == 0 {
        @ron.RonValue::Struct(name, [])
      } else {
        @ron.RonValue::TupleStruct(name, to_ron_values(values))
      }
  }
}

///|
fn to_ron_values(
  values : Array[@mon.MonValue],
) -> Array[@ron.RonValue] raise MonConvertError {
  let converted = []
  for value in values {
    converted.push(to_ron(value))
  }
  converted
}

///|
fn to_ron_fields(
  fields : Array[(String, @mon.MonValue)],
) -> Array[(String, @ron.RonValue)] raise MonConvertError {
  let converted = []
  for field in fields {
    let (name, value) = field
    converted.push((name, to_ron(value)))
  }
  converted
}

///|
/// A MON field map is a RON map with identifier keys, which is the shape RON's
/// reader gives `{ field: value }`.
fn to_ron_fields_as_identifiers(
  fields : Array[(String, @mon.MonValue)],
) -> Array[(@ron.RonValue, @ron.RonValue)] raise MonConvertError {
  let converted = []
  for field in fields {
    let (name, value) = field
    converted.push((@ron.RonValue::Identifier(name), to_ron(value)))
  }
  converted
}

///|
fn to_ron_entries(
  entries : Array[(@mon.MonValue, @mon.MonValue)],
) -> Array[(@ron.RonValue, @ron.RonValue)] raise MonConvertError {
  let converted = []
  for entry in entries {
    let (key, value) = entry
    converted.push((to_ron(key), to_ron(value)))
  }
  converted
}

///|
fn to_ron_optional(
  value : @mon.MonValue?,
) -> @ron.RonValue? raise MonConvertError {
  match value {
    Some(value) => Some(to_ron(value))
    None => None
  }
}

///|
fn from_ron_values(
  values : Array[@ron.RonValue],
) -> Array[@mon.MonValue] raise MonConvertError {
  let converted = []
  for value in values {
    converted.push(from_ron(value))
  }
  converted
}

///|
fn from_ron_fields(
  fields : Array[(String, @ron.RonValue)],
) -> Array[(String, @mon.MonValue)] raise MonConvertError {
  let converted = []
  for field in fields {
    let (name, value) = field
    converted.push((name, from_ron(value)))
  }
  converted
}

///|
/// A RON map whose keys are all identifiers is a MON field map; any other map
/// stays a map.
fn from_ron_map(
  entries : Array[(@ron.RonValue, @ron.RonValue)],
) -> @mon.MonValue raise MonConvertError {
  let fields = []
  let mut only_fields = entries.length() > 0
  for entry in entries {
    let (key, value) = entry
    match key {
      Identifier(name) => fields.push((name, from_ron(value)))
      _ => only_fields = false
    }
  }
  if only_fields {
    return @mon.MonValue::Fields(fields)
  }
  let converted = []
  for entry in entries {
    let (key, value) = entry
    converted.push((from_ron(key), from_ron(value)))
  }
  @mon.MonValue::Map(converted)
}

///|
fn from_ron_optional(
  value : @ron.RonValue?,
) -> @mon.MonValue? raise MonConvertError {
  match value {
    Some(value) => Some(from_ron(value))
    None => None
  }
}

///|
/// Split `Owner::Variant` into its two halves.
fn split_path(path : String) -> (String, String)? {
  match path.rev_find("::") {
    Some(index) =>
      Some(
        (
          path.unsafe_substring(start=0, end=index),
          path.unsafe_substring(start=index + 2, end=path.length()),
        ),
      )
    None => None
  }
}
