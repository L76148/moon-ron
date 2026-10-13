///|
/// A source position measured in Unicode scalar values.
pub(all) struct RonPosition {
  index : Int32
  line : Int32
  column : Int32
} derive(Eq, Debug)

///|
/// Errors raised while parsing RON source.
pub(all) suberror RonError {
  UnexpectedChar(RonPosition, Char)
  UnexpectedEof(RonPosition)
  InvalidEscape(RonPosition)
  InvalidNumber(RonPosition, String)
  InvalidValue(RonPosition, String)
  UnknownExtension(RonPosition, String)
  UnknownAttribute(RonPosition, String)
  InvalidAttribute(RonPosition, String)
  DepthLimitExceeded(Int32)
} derive(Eq, Debug)
