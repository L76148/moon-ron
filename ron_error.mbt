///|
/// A source position measured in Unicode scalar values.
pub(all) struct RonPosition {
  index : Int
  line : Int
  column : Int
} derive(Eq, Debug)

///|
/// Errors raised while parsing RON source.
pub(all) suberror RonError {
  UnexpectedChar(RonPosition, Char)
  UnexpectedEof(RonPosition)
  InvalidEscape(RonPosition)
  InvalidNumber(RonPosition, String)
  InvalidValue(RonPosition, String)
  DepthLimitExceeded(Int)
} derive(Eq, Debug)
