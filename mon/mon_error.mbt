///|
/// A source position measured in Unicode scalar values.
pub(all) struct MonPosition {
  index : Int
  line : Int
  column : Int
} derive(Eq, Debug)

///|
/// Errors raised while reading a MON document.
pub(all) suberror MonError {
  UnexpectedChar(MonPosition, Char)
  UnexpectedEof(MonPosition)
  /// `Expected(position, description)` reports a token the grammar needs.
  Expected(MonPosition, String)
  InvalidEscape(MonPosition)
  InvalidNumber(MonPosition, String)
  InvalidLiteral(MonPosition, String)
  DepthLimitExceeded(Int)
} derive(Eq, Debug)

///|
/// `derive(Eq)` promotes the trait methods to methods of the type. Declaring
/// the promotion keeps the interface explicit and warning free.
pub extend MonPosition with Eq::{not_equal, equal}

///|
pub extend MonPosition with @debug.Debug::{to_repr}

///|
pub extend MonError with Eq::{not_equal, equal}

///|
pub extend MonError with @debug.Debug::{to_repr}
