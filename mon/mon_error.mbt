///|
/// A source position measured in Unicode scalar values.
pub(all) struct MonPosition {
  index : Int32
  line : Int32
  column : Int32
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
  DepthLimitExceeded(Int32)
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
