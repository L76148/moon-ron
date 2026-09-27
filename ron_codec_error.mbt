///|
/// A path from a decoded root value to the value that caused an error.
pub(all) enum RonPath {
  Root
  Key(String, RonPath)
  Index(Int, RonPath)
  Variant(String, RonPath)
} derive(Eq, Debug)

///|
/// Errors raised by typed RON decoding.
pub(all) suberror RonDecodeError {
  Syntax(RonError)
  TypeMismatch(RonPath, String, String)
  MissingField(RonPath, String)
  UnexpectedTupleLength(RonPath, Int, Int)
  UnknownVariant(RonPath, String)
  InvalidValue(RonPath, String)
} derive(Eq, Debug)

///|
pub fn RonPath::root() -> RonPath {
  Root
}

///|
pub fn RonPath::add_key(self : RonPath, key : String) -> RonPath {
  Key(key, self)
}

///|
pub fn RonPath::add_index(self : RonPath, index : Int) -> RonPath {
  Index(index, self)
}

///|
pub fn RonPath::add_variant(self : RonPath, variant : String) -> RonPath {
  Variant(variant, self)
}

///|
pub fn RonPath::to_string(self : RonPath) -> String {
  match self {
    Root => "$"
    Key(key, parent) => parent.to_string() + "." + key
    Index(index, parent) => parent.to_string() + "[" + index.to_string() + "]"
    Variant(variant, parent) => parent.to_string() + "::" + variant
  }
}
