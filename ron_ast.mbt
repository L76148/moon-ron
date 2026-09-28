///|
/// A numeric value in a RON document.
pub(all) enum RonNumber {
  Signed(Int64)
  Unsigned(UInt64)
  Float(Double)
  Infinity
  NegativeInfinity
  NaN
} derive(Eq, Debug)

///|
/// A possibly open-ended RON range.
pub(all) struct RonRange {
  start : RonValue?
  end : RonValue?
  inclusive : Bool
} derive(Eq, Debug)

///|
pub fn RonRange::new(
  start? : RonValue,
  end? : RonValue,
  inclusive? : Bool = false,
) -> RonRange {
  { start, end, inclusive, }
}

///|
/// A dynamically typed RON value.
pub(all) enum RonValue {
  Unit
  Bool(Bool)
  Number(RonNumber)
  Char(Char)
  String(String)
  Bytes(Bytes)
  Byte(Byte)
  Option(RonValue?)
  Sequence(Array[RonValue])
  Tuple(Array[RonValue])
  Map(Array[(RonValue, RonValue)])
  Struct(String, Array[(String, RonValue)])
  TupleStruct(String, Array[RonValue])
  Enum(String, String, Array[(String, RonValue)])
  EnumTuple(String, String, Array[RonValue])
  Range(RonRange)
  Identifier(String)
} derive(Eq, Debug)
