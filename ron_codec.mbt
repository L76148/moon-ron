///|
/// Trait for values that can be decoded from a `RonValue`.
pub(open) trait FromRon {
  fn from_ron(RonValue, RonPath, RonOptions) -> Self raise RonDecodeError
}

///|
/// Trait for values that can be encoded as a `RonValue`.
pub(open) trait ToRon {
  fn to_ron(Self, RonOptions) -> RonValue
}

///|
/// Decode one RON document into a typed value.
pub fn[T : FromRon] decode(
  source : StringView,
  max_nesting_depth? : Int = 128,
) -> T raise RonDecodeError {
  decode_with_options(
    source,
    options=RonOptions::default().with_max_nesting_depth(max_nesting_depth),
  )
}

///|
/// Decode one RON document using explicit extension and depth options.
pub fn[T : FromRon] decode_with_options(
  source : StringView,
  options? : RonOptions = RonOptions::default(),
) -> T raise RonDecodeError {
  let document = parse_document(source, options~) catch {
    error => raise Syntax(error)
  }
  let resolved = options.with_extensions(document.extensions)
  FromRon::from_ron(document.value, Root, resolved)
}

///|
/// Decode an already parsed RON value.
pub fn[T : FromRon] from_value(value : RonValue) -> T raise RonDecodeError {
  from_value_with_options(value, RonOptions::default())
}

///|
/// Decode an already parsed RON value using explicit options.
pub fn[T : FromRon] from_value_with_options(
  value : RonValue,
  options : RonOptions,
) -> T raise RonDecodeError {
  FromRon::from_ron(value, Root, options)
}

///|
/// Encode a typed value as a `RonValue`.
pub fn[T : ToRon] to_value(value : T) -> RonValue {
  to_value_with_options(value, RonOptions::default())
}

///|
/// Encode a typed value as a `RonValue` using explicit options.
pub fn[T : ToRon] to_value_with_options(
  value : T,
  options : RonOptions,
) -> RonValue {
  ToRon::to_ron(value, options)
}

///|
/// Encode a typed value as canonical RON text.
pub fn[T : ToRon] encode(value : T) -> String {
  encode_with_options(value, options=RonOptions::default())
}

///|
/// Encode a typed value with an optional RON extension header.
pub fn[T : ToRon] encode_with_options(
  value : T,
  options? : RonOptions = RonOptions::default(),
) -> String {
  let body = to_string(ToRon::to_ron(value, options))
  let attribute = options.extensions.to_attribute()
  if attribute.length() == 0 {
    body
  } else {
    attribute + "\n" + body
  }
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
  options : RonOptions,
) -> T raise RonDecodeError {
  FromRon::from_ron(
    field_value(fields, name, path),
    path.add_key(name),
    options,
  )
}

///|
pub fn[T : FromRon] positional(
  values : Array[RonValue],
  index : Int,
  path : RonPath,
  options : RonOptions,
) -> T raise RonDecodeError {
  match values.get(index) {
    Some(value) => FromRon::from_ron(value, path.add_index(index), options)
    None => raise UnexpectedTupleLength(path, index + 1, values.length())
  }
}

///|
/// Decode a newtype payload, honoring `unwrap_newtypes`.
pub fn[T : FromRon] newtype(
  value : RonValue,
  path : RonPath,
  options : RonOptions,
) -> T raise RonDecodeError {
  let inner = match value {
    Tuple(values) if values.length() == 1 => values[0]
    _ if options.extensions.unwrap_newtypes => value
    _ => raise TypeMismatch(path, "newtype tuple", value_type_name(value))
  }
  FromRon::from_ron(inner, path, options)
}

///|
/// Decode an enum newtype payload, honoring `unwrap_variant_newtypes`.
pub fn[T : FromRon] variant_newtype(
  value : RonValue,
  variant : String,
  path : RonPath,
  options : RonOptions,
) -> T raise RonDecodeError {
  if options.extensions.unwrap_variant_newtypes {
    match value {
      Struct(name, fields) if name == variant =>
        FromRon::from_ron(Struct("", fields), path, options)
      TupleStruct(name, values) if name == variant && values.length() == 1 =>
        FromRon::from_ron(values[0], path, options)
      EnumTuple(_, name, values) if name == variant && values.length() == 1 =>
        FromRon::from_ron(values[0], path, options)
      _ =>
        raise TypeMismatch(
          path,
          "unwrapped variant " + variant,
          value_type_name(value),
        )
    }
  } else {
    match value {
      TupleStruct(name, values) if name == variant && values.length() == 1 =>
        FromRon::from_ron(values[0], path, options)
      EnumTuple(_, name, values) if name == variant && values.length() == 1 =>
        FromRon::from_ron(values[0], path, options)
      Tuple(values) if values.length() == 1 =>
        FromRon::from_ron(values[0], path, options)
      _ =>
        raise TypeMismatch(
          path,
          "variant " + variant + " with one payload",
          value_type_name(value),
        )
    }
  }
}

///|
/// Require a named struct when `explicit_struct_names` is enabled.
pub fn require_struct_name(
  value : RonValue,
  expected : String,
  path : RonPath,
  options : RonOptions,
) -> Unit raise RonDecodeError {
  match value {
    Struct(name, _) if name == expected => ()
    Struct("", _) if !options.extensions.explicit_struct_names => ()
    Struct("", _) if options.extensions.explicit_struct_names =>
      raise InvalidValue(path, "expected explicit struct name \{expected}")
    Struct(name, _) =>
      raise InvalidValue(path, "expected struct \{expected}, found \{name}")
    _ => raise TypeMismatch(path, "struct " + expected, value_type_name(value))
  }
}
