///|
fn[T] decode_type_error(
  path : RonPath,
  expected : String,
  value : RonValue,
) -> T raise RonDecodeError {
  raise TypeMismatch(path, expected, value_type_name(value))
}

///|
fn as_number(
  value : RonValue,
  path : RonPath,
  expected : String,
) -> RonNumber raise RonDecodeError {
  match value {
    Number(number) => number
    _ => decode_type_error(path, expected, value)
  }
}

///|
pub impl ToRon for Unit with fn to_ron(_, _) {
  Unit
}

///|
pub impl FromRon for Unit with fn from_ron(value, path, _) {
  match value {
    Unit => ()
    _ => decode_type_error(path, "unit", value)
  }
}

///|
pub impl ToRon for Bool with fn to_ron(self, _) {
  Bool(self)
}

///|
pub impl FromRon for Bool with fn from_ron(value, path, _) {
  match value {
    Bool(value) => value
    _ => decode_type_error(path, "bool", value)
  }
}

///|
pub impl ToRon for Byte with fn to_ron(self, _) {
  Number(Signed(self.to_int64()))
}

///|
pub impl FromRon for Byte with fn from_ron(value, path, _) {
  match as_number(value, path, "Byte") {
    Signed(value) if value >= 0L && value <= 255L => value.to_int().to_byte()
    Unsigned(value) if value <= 255UL => value.to_int().to_byte()
    _ => raise InvalidValue(path, "byte out of range")
  }
}

///|
pub impl ToRon for Int with fn to_ron(self, _) {
  Number(Signed(self.to_int64()))
}

///|
pub impl FromRon for Int with fn from_ron(value, path, _) {
  match as_number(value, path, "Int") {
    Signed(value) if value >= -2147483648L && value <= 2147483647L =>
      value.to_int()
    Unsigned(value) if value <= 2147483647UL => value.to_int()
    _ => raise InvalidValue(path, "Int out of range")
  }
}

///|
pub impl ToRon for Int64 with fn to_ron(self, _) {
  Number(Signed(self))
}

///|
pub impl FromRon for Int64 with fn from_ron(value, path, _) {
  match as_number(value, path, "Int64") {
    Signed(value) => value
    Unsigned(value) if value <= 0x7fffffffffffffffUL =>
      value.reinterpret_as_int64()
    _ => raise InvalidValue(path, "Int64 out of range")
  }
}

///|
pub impl ToRon for UInt with fn to_ron(self, _) {
  Number(Unsigned(self.to_uint64()))
}

///|
pub impl FromRon for UInt with fn from_ron(value, path, _) {
  match as_number(value, path, "UInt") {
    Signed(value) if value >= 0L && value <= 4294967295L =>
      value.to_int().reinterpret_as_uint()
    Unsigned(value) if value <= 4294967295UL =>
      value.to_int().reinterpret_as_uint()
    _ => raise InvalidValue(path, "UInt out of range")
  }
}

///|
pub impl ToRon for UInt64 with fn to_ron(self, _) {
  Number(Unsigned(self))
}

///|
pub impl FromRon for UInt64 with fn from_ron(value, path, _) {
  match as_number(value, path, "UInt64") {
    Signed(value) if value >= 0L => value.reinterpret_as_uint64()
    Unsigned(value) => value
    _ => raise InvalidValue(path, "UInt64 out of range")
  }
}

///|
pub impl ToRon for Int16 with fn to_ron(self, _) {
  Number(Signed(self.to_int64()))
}

///|
pub impl FromRon for Int16 with fn from_ron(value, path, _) {
  match as_number(value, path, "Int16") {
    Signed(value) if value >= -32768L && value <= 32767L =>
      Int16::from_int(value.to_int())
    Unsigned(value) if value <= 32767UL => Int16::from_int(value.to_int())
    _ => raise InvalidValue(path, "Int16 out of range")
  }
}

///|
pub impl ToRon for UInt16 with fn to_ron(self, _) {
  Number(Unsigned(self.to_uint64()))
}

///|
pub impl FromRon for UInt16 with fn from_ron(value, path, _) {
  match as_number(value, path, "UInt16") {
    Signed(value) if value >= 0L && value <= 65535L =>
      value.to_int().to_uint16()
    Unsigned(value) if value <= 65535UL => value.to_int().to_uint16()
    _ => raise InvalidValue(path, "UInt16 out of range")
  }
}

///|
pub impl ToRon for Double with fn to_ron(self, _) {
  if self.is_nan() {
    Number(NaN)
  } else if self.is_pos_inf() {
    Number(Infinity)
  } else if self.is_neg_inf() {
    Number(NegativeInfinity)
  } else {
    Number(Float(self))
  }
}

///|
pub impl FromRon for Double with fn from_ron(value, path, _) {
  match as_number(value, path, "Double") {
    Signed(value) => value.to_double()
    Unsigned(value) => value.to_double()
    Float(value) => value
    Infinity => @double.infinity
    NegativeInfinity => @double.neg_infinity
    NaN => @double.not_a_number
  }
}

///|
pub impl ToRon for Float with fn to_ron(self, _) {
  if self.is_nan() {
    Number(NaN)
  } else if self.is_pos_inf() {
    Number(Infinity)
  } else if self.is_neg_inf() {
    Number(NegativeInfinity)
  } else {
    Number(Float(self.to_double()))
  }
}

///|
pub impl FromRon for Float with fn from_ron(value, path, _) {
  match as_number(value, path, "Float") {
    Signed(value) => Float::from_int64(value)
    Unsigned(value) => Float::from_uint64(value)
    Float(value) => Float::from_double(value)
    Infinity => @float.infinity
    NegativeInfinity => @float.neg_infinity
    NaN => @float.not_a_number
  }
}

///|
pub impl ToRon for Char with fn to_ron(self, _) {
  Char(self)
}

///|
pub impl FromRon for Char with fn from_ron(value, path, _) {
  match value {
    Char(value) => value
    _ => decode_type_error(path, "char", value)
  }
}

///|
pub impl ToRon for String with fn to_ron(self, _) {
  String(self)
}

///|
pub impl FromRon for String with fn from_ron(value, path, _) {
  match value {
    String(value) => value
    _ => decode_type_error(path, "string", value)
  }
}

///|
pub impl ToRon for Bytes with fn to_ron(self, _) {
  Bytes(self)
}

///|
pub impl FromRon for Bytes with fn from_ron(value, path, _) {
  match value {
    Bytes(value) => value
    _ => decode_type_error(path, "bytes", value)
  }
}

///|
pub impl ToRon for RonValue with fn to_ron(self, _) {
  self
}

///|
pub impl FromRon for RonValue with fn from_ron(value, _, _) {
  value
}

///|
pub impl ToRon for RonRange with fn to_ron(self, _) {
  Range(self)
}

///|
pub impl FromRon for RonRange with fn from_ron(value, path, _) {
  match value {
    Range(range) => range
    _ => decode_type_error(path, "range", value)
  }
}

///|
pub impl[T : ToRon] ToRon for T? with fn to_ron(self, options) {
  match self {
    None => Option(None)
    Some(value) =>
      if options.extensions.implicit_some {
        ToRon::to_ron(value, options)
      } else {
        Option(Some(ToRon::to_ron(value, options)))
      }
  }
}

///|
pub impl[T : FromRon] FromRon for T? with fn from_ron(value, path, options) {
  match value {
    Option(None) => None
    Option(Some(value)) =>
      Some(FromRon::from_ron(value, path.add_variant("Some"), options))
    _ if options.extensions.implicit_some =>
      Some(FromRon::from_ron(value, path.add_variant("Some"), options))
    _ => decode_type_error(path, "option", value)
  }
}

///|
pub impl[T : ToRon] ToRon for Array[T] with fn to_ron(self, options) {
  Sequence(self.map(value => ToRon::to_ron(value, options)))
}

///|
pub impl[T : FromRon] FromRon for Array[T] with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    Sequence(values) => {
      let result = []
      for i = 0; i < values.length(); i = i + 1 {
        result.push(FromRon::from_ron(values[i], path.add_index(i), options))
      }
      result
    }
    _ => decode_type_error(path, "sequence", value)
  }
}

///|
pub impl[T : ToRon] ToRon for FixedArray[T] with fn to_ron(self, options) {
  Sequence(
    Array::from_fixed_array(self.map(value => ToRon::to_ron(value, options))),
  )
}

///|
pub impl[T : FromRon] FromRon for FixedArray[T] with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    Sequence(values) => {
      let result = []
      for i = 0; i < values.length(); i = i + 1 {
        result.push(FromRon::from_ron(values[i], path.add_index(i), options))
      }
      FixedArray::from_array(result)
    }
    _ => decode_type_error(path, "fixed array", value)
  }
}

///|
pub impl[T : ToRon] ToRon for ArrayView[T] with fn to_ron(self, options) {
  Sequence(self.to_owned().map(value => ToRon::to_ron(value, options)))
}

///|
pub impl[V : ToRon] ToRon for Map[String, V] with fn to_ron(self, options) {
  let entries = self.to_array()
  entries.sort_by((left, right) => left.0.compare(right.0))
  Map(entries.map(entry => (String(entry.0), ToRon::to_ron(entry.1, options))))
}

///|
pub impl[V : FromRon] FromRon for Map[String, V] with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    Map(entries) => {
      let result : Map[String, V] = Map([])
      for i = 0; i < entries.length(); i = i + 1 {
        let (key, value) = entries[i]
        let key = match key {
          String(key) | Identifier(key) => key
          _ =>
            raise TypeMismatch(
              path.add_index(i),
              "string key",
              value_type_name(key),
            )
        }
        result[key] = FromRon::from_ron(value, path.add_key(key), options)
      }
      result
    }
    _ => decode_type_error(path, "map", value)
  }
}

///|
pub impl[Ok : ToRon, Err : ToRon] ToRon for Result[Ok, Err] with fn to_ron(
  self,
  options,
) {
  match self {
    Ok(value) => TupleStruct("Ok", [ToRon::to_ron(value, options)])
    Err(error) => TupleStruct("Err", [ToRon::to_ron(error, options)])
  }
}

///|
pub impl[Ok : FromRon, Err : FromRon] FromRon for Result[Ok, Err] with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    TupleStruct("Ok", values) if values.length() == 1 =>
      Ok(FromRon::from_ron(values[0], path.add_variant("Ok"), options))
    TupleStruct("Err", values) if values.length() == 1 =>
      Err(FromRon::from_ron(values[0], path.add_variant("Err"), options))
    EnumTuple(_, "Ok", values) if values.length() == 1 =>
      Ok(FromRon::from_ron(values[0], path.add_variant("Ok"), options))
    EnumTuple(_, "Err", values) if values.length() == 1 =>
      Err(FromRon::from_ron(values[0], path.add_variant("Err"), options))
    _ => raise InvalidValue(path, "expected Result variant Ok or Err")
  }
}

///|
pub impl[A : ToRon, B : ToRon] ToRon for (A, B) with fn to_ron(self, options) {
  Tuple([ToRon::to_ron(self.0, options), ToRon::to_ron(self.1, options)])
}

///|
pub impl[A : FromRon, B : FromRon] FromRon for (A, B) with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    Tuple(values) if values.length() == 2 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 2, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[A : ToRon, B : ToRon, C : ToRon] ToRon for (A, B, C) with fn to_ron(
  self,
  options,
) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
  ])
}

///|
pub impl[A : FromRon, B : FromRon, C : FromRon] FromRon for (A, B, C) with fn from_ron(
  value,
  path,
  options,
) {
  match value {
    Tuple(values) if values.length() == 3 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 3, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[A : ToRon, B : ToRon, C : ToRon, D : ToRon] ToRon for (A, B, C, D) with fn to_ron(
  self,
  options,
) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
    ToRon::to_ron(self.3, options),
  ])
}

///|
pub impl[A : FromRon, B : FromRon, C : FromRon, D : FromRon] FromRon for (
  A,
  B,
  C,
  D,
) with fn from_ron(value, path, options) {
  match value {
    Tuple(values) if values.length() == 4 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
        FromRon::from_ron(values[3], path.add_index(3), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 4, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[A : ToRon, B : ToRon, C : ToRon, D : ToRon, E : ToRon] ToRon for (
  A,
  B,
  C,
  D,
  E,
) with fn to_ron(self, options) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
    ToRon::to_ron(self.3, options),
    ToRon::to_ron(self.4, options),
  ])
}

///|
pub impl[A : FromRon, B : FromRon, C : FromRon, D : FromRon, E : FromRon] FromRon for (
  A,
  B,
  C,
  D,
  E,
) with fn from_ron(value, path, options) {
  match value {
    Tuple(values) if values.length() == 5 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
        FromRon::from_ron(values[3], path.add_index(3), options),
        FromRon::from_ron(values[4], path.add_index(4), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 5, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[A : ToRon, B : ToRon, C : ToRon, D : ToRon, E : ToRon, F : ToRon] ToRon for (
  A,
  B,
  C,
  D,
  E,
  F,
) with fn to_ron(self, options) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
    ToRon::to_ron(self.3, options),
    ToRon::to_ron(self.4, options),
    ToRon::to_ron(self.5, options),
  ])
}

///|
pub impl[
  A : FromRon,
  B : FromRon,
  C : FromRon,
  D : FromRon,
  E : FromRon,
  F : FromRon,
] FromRon for (A, B, C, D, E, F) with fn from_ron(value, path, options) {
  match value {
    Tuple(values) if values.length() == 6 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
        FromRon::from_ron(values[3], path.add_index(3), options),
        FromRon::from_ron(values[4], path.add_index(4), options),
        FromRon::from_ron(values[5], path.add_index(5), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 6, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[
  A : ToRon,
  B : ToRon,
  C : ToRon,
  D : ToRon,
  E : ToRon,
  F : ToRon,
  G : ToRon,
] ToRon for (A, B, C, D, E, F, G) with fn to_ron(self, options) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
    ToRon::to_ron(self.3, options),
    ToRon::to_ron(self.4, options),
    ToRon::to_ron(self.5, options),
    ToRon::to_ron(self.6, options),
  ])
}

///|
pub impl[
  A : FromRon,
  B : FromRon,
  C : FromRon,
  D : FromRon,
  E : FromRon,
  F : FromRon,
  G : FromRon,
] FromRon for (A, B, C, D, E, F, G) with fn from_ron(value, path, options) {
  match value {
    Tuple(values) if values.length() == 7 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
        FromRon::from_ron(values[3], path.add_index(3), options),
        FromRon::from_ron(values[4], path.add_index(4), options),
        FromRon::from_ron(values[5], path.add_index(5), options),
        FromRon::from_ron(values[6], path.add_index(6), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 7, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}

///|
pub impl[
  A : ToRon,
  B : ToRon,
  C : ToRon,
  D : ToRon,
  E : ToRon,
  F : ToRon,
  G : ToRon,
  H : ToRon,
] ToRon for (A, B, C, D, E, F, G, H) with fn to_ron(self, options) {
  Tuple([
    ToRon::to_ron(self.0, options),
    ToRon::to_ron(self.1, options),
    ToRon::to_ron(self.2, options),
    ToRon::to_ron(self.3, options),
    ToRon::to_ron(self.4, options),
    ToRon::to_ron(self.5, options),
    ToRon::to_ron(self.6, options),
    ToRon::to_ron(self.7, options),
  ])
}

///|
pub impl[
  A : FromRon,
  B : FromRon,
  C : FromRon,
  D : FromRon,
  E : FromRon,
  F : FromRon,
  G : FromRon,
  H : FromRon,
] FromRon for (A, B, C, D, E, F, G, H) with fn from_ron(value, path, options) {
  match value {
    Tuple(values) if values.length() == 8 =>
      (
        FromRon::from_ron(values[0], path.add_index(0), options),
        FromRon::from_ron(values[1], path.add_index(1), options),
        FromRon::from_ron(values[2], path.add_index(2), options),
        FromRon::from_ron(values[3], path.add_index(3), options),
        FromRon::from_ron(values[4], path.add_index(4), options),
        FromRon::from_ron(values[5], path.add_index(5), options),
        FromRon::from_ron(values[6], path.add_index(6), options),
        FromRon::from_ron(values[7], path.add_index(7), options),
      )
    Tuple(values) => raise UnexpectedTupleLength(path, 8, values.length())
    _ => decode_type_error(path, "tuple", value)
  }
}
