///|
/// Trait for values that can be decoded from a `RonValue`.
pub(open) trait FromRon {
  fn from_ron(RonValue, RonPath) -> Self raise RonDecodeError
}

///|
/// Trait for values that can be encoded as a `RonValue`.
pub(open) trait ToRon {
  fn to_ron(Self) -> RonValue
}

///|
/// Decode one RON document into a typed value.
pub fn[T : FromRon] decode(
  source : StringView,
  max_nesting_depth? : Int = 128,
) -> T raise RonDecodeError {
  let value = parse(source, max_nesting_depth~) catch {
    error => raise Syntax(error)
  }
  FromRon::from_ron(value, Root)
}

///|
/// Decode an already parsed RON value.
pub fn[T : FromRon] from_value(value : RonValue) -> T raise RonDecodeError {
  FromRon::from_ron(value, Root)
}

///|
/// Encode a typed value as a `RonValue`.
pub fn[T : ToRon] to_value(value : T) -> RonValue {
  ToRon::to_ron(value)
}

///|
/// Encode a typed value as canonical RON text.
pub fn[T : ToRon] encode(value : T) -> String {
  to_string(ToRon::to_ron(value))
}

///|
/// Return the display name of a dynamic RON value.
pub fn value_type_name(value : RonValue) -> String {
  match value {
    Unit => "unit"
    Bool(_) => "bool"
    Number(_) => "number"
    Char(_) => "char"
    String(_) => "string"
    Bytes(_) => "bytes"
    Byte(_) => "byte"
    Option(_) => "option"
    Sequence(_) => "sequence"
    Tuple(_) | TupleStruct(_, _) => "tuple"
    Map(_) => "map"
    Struct(_, _) => "struct"
    Enum(_, _, _) | EnumTuple(_, _, _) => "enum"
    Identifier(_) => "identifier"
  }
}

///|
pub fn struct_fields(
  value : RonValue,
  path : RonPath,
) -> Array[(String, RonValue)] raise RonDecodeError {
  match value {
    Struct(_, fields) => fields
    _ => raise TypeMismatch(path, "struct", value_type_name(value))
  }
}

///|
pub fn tuple_fields(
  value : RonValue,
  path : RonPath,
) -> Array[RonValue] raise RonDecodeError {
  match value {
    Tuple(values) | TupleStruct(_, values) => values
    _ => raise TypeMismatch(path, "tuple", value_type_name(value))
  }
}

///|
pub fn field_value(
  fields : Array[(String, RonValue)],
  name : String,
  path : RonPath,
) -> RonValue raise RonDecodeError {
  for i = 0; i < fields.length(); i = i + 1 {
    let (field_name, value) = fields[i]
    if field_name == name {
      return value
    }
  }
  raise MissingField(path, name)
}

///|
pub fn[T : FromRon] field(
  fields : Array[(String, RonValue)],
  name : String,
  path : RonPath,
) -> T raise RonDecodeError {
  FromRon::from_ron(field_value(fields, name, path), path.add_key(name))
}

///|
pub fn[T : FromRon] positional(
  values : Array[RonValue],
  index : Int,
  path : RonPath,
) -> T raise RonDecodeError {
  match values.get(index) {
    Some(value) => FromRon::from_ron(value, path.add_index(index))
    None => raise UnexpectedTupleLength(path, index + 1, values.length())
  }
}
