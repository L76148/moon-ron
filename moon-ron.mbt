///|
/// Parse one RON document into a dynamically typed value.
///
/// The parser accepts comments, all RON scalar forms, sequences, tuples,
/// maps, named structs, tuple structs, and enum variants. The optional
/// `max_nesting_depth` applies to containers and typed payloads.
pub fn parse(
  source : StringView,
  max_nesting_depth? : Int = 128,
) -> RonValue raise RonError {
  if max_nesting_depth < 0 {
    raise DepthLimitExceeded(max_nesting_depth)
  }
  let parser = RonParser::new(source, max_nesting_depth)
  let value = parser.parse_value(0)
  parser.skip_trivia()
  if parser.offset != parser.source.length() {
    let position = parser.position()
    raise UnexpectedChar(position, parser.source[parser.offset])
  }
  value
}

///|
/// Parse one RON document and return `false` when parsing fails.
pub fn valid(source : StringView) -> Bool {
  try {
    parse(source) |> ignore
    true
  } catch {
    _ => false
  }
}
