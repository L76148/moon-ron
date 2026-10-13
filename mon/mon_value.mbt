///|
/// The numeric values a MON document can spell.
///
/// The literal spelling carries the width, exactly as in MoonBit: `1` is
/// `Int`, `1L` is `Int64`, `1U` is `UInt`, `1UL` is `UInt64`, and a literal
/// with a fractional part or an exponent is `Double`.
pub(all) enum MonNumber {
  Int(Int)
  Int64(Int64)
  UInt(UInt)
  UInt64(UInt64)
  Double(Double)
} derive(Eq, Debug)

///|
/// A possibly open-ended range such as `1..10`, `1..=10`, `..10`, or `1..`.
///
/// Ranges are the one place where MON goes beyond MoonBit expression syntax.
/// MoonBit accepts `..<` and `..=` only inside `for` loops, so a MON document
/// spells ranged data with `..` and `..=` and records whether the upper bound
/// is inclusive.
pub(all) struct MonRange {
  start : MonValue?
  end : MonValue?
  inclusive : Bool
} derive(Eq, Debug)

///|
pub fn MonRange::new(
  start? : MonValue,
  end? : MonValue,
  inclusive? : Bool = false,
) -> MonRange {
  { start, end, inclusive, }
}

///|
/// A value read from a MON document.
///
/// Every variant has a MoonBit literal spelling except `Range`: `Unit` is
/// `()`, `Sequence` is `[a, b]`, `Tuple` is `(a, b)`, `Map` is
/// `{ "key": value }`, `Fields` is `{ field: value }`, `Record` is
/// `Name { field: value }`, and `TupleVariant` is `Name(...)` or
/// `Enum::Name(...)`. `Some(1)`, `None`, and `Ok(1)` are ordinary variants
/// because that is what they are in MoonBit.
pub(all) enum MonValue {
  /// `()`
  Unit
  /// `true` or `false`
  Bool(Bool)
  Number(MonNumber)
  /// `'x'`
  Char(Char)
  /// `"text"`
  String(String)
  /// `b"bytes"`
  Bytes(Bytes)
  /// `b'x'`
  Byte(Byte)
  /// `[a, b]`
  Sequence(Array[MonValue])
  /// `(a, b)`; one element is the element itself and `()` is `Unit`
  Tuple(Array[MonValue])
  /// `{ "key": value }`
  Map(Array[(MonValue, MonValue)])
  /// `{ field: value }`
  Fields(Array[(String, MonValue)])
  /// `Name { field: value }`
  Record(String, Array[(String, MonValue)])
  /// `Name(...)` and `Enum::Name(...)`
  TupleVariant(String, Array[MonValue])
  /// `Name` and `Enum::Name`
  Variant(String)
  Range(MonRange)
} derive(Eq, Debug)

///|
/// The shape of the value, for tools and diagnostics.
pub fn MonValue::kind(self : MonValue) -> String {
  match self {
    Unit => "unit"
    Bool(_) => "bool"
    Number(_) => "number"
    Char(_) => "char"
    String(_) => "string"
    Bytes(_) => "bytes"
    Byte(_) => "byte"
    Sequence(_) => "sequence"
    Tuple(_) => "tuple"
    Map(_) => "map"
    Fields(_) => "fields"
    Record(_, _) => "record"
    TupleVariant(_, _) => "variant"
    Variant(_) => "variant"
    Range(_) => "range"
  }
}

///|
/// The number of children a container holds, or `None` for a scalar.
pub fn MonValue::length(self : MonValue) -> Int? {
  match self {
    Sequence(values) => Some(values.length())
    Tuple(values) => Some(values.length())
    Map(entries) => Some(entries.length())
    Fields(fields) => Some(fields.length())
    Record(_, fields) => Some(fields.length())
    TupleVariant(_, values) => Some(values.length())
    _ => None
  }
}

///|
/// Look up a field by name.
///
/// `Fields` and `Record` values answer directly; every other value answers
/// `None`.
pub fn MonValue::field(self : MonValue, name : String) -> MonValue? {
  let fields : Array[(String, MonValue)] = match self {
    Fields(fields) => fields
    Record(_, fields) => fields
    _ => []
  }
  for i = 0; i < fields.length(); i = i + 1 {
    let (key, value) = fields[i]
    if key == name {
      return Some(value)
    }
  }
  None
}

///|
/// The name of a `Record`, `TupleVariant`, or `Variant`, and `None` for every
/// other value.
pub fn MonValue::variant_name(self : MonValue) -> String? {
  match self {
    Record(name, _) => Some(name)
    TupleVariant(name, _) => Some(name)
    Variant(name) => Some(name)
    _ => None
  }
}

///|
/// Explicit promotions for the derived traits, which keeps the generated
/// interface complete and the build warning free.
pub extend MonNumber with Eq::{not_equal, equal}

///|
pub extend MonNumber with @debug.Debug::{to_repr}

///|
pub extend MonRange with Eq::{not_equal, equal}

///|
pub extend MonRange with @debug.Debug::{to_repr}

///|
pub extend MonValue with Eq::{not_equal, equal}

///|
pub extend MonValue with @debug.Debug::{to_repr}
