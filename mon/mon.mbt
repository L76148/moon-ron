///|
/// Parse one MON document into a dynamically typed value.
///
/// The parser accepts comments, every MoonBit scalar literal form, sequences,
/// tuples, maps, field maps, records, constructors, and ranges. The optional
/// `max_nesting_depth` applies to containers and constructor arguments.
pub fn parse(
  source : StringView,
  max_nesting_depth~ : Int32 = 128,
) -> MonValue raise MonError {
  if max_nesting_depth < 0 {
    raise DepthLimitExceeded(max_nesting_depth)
  }
  let parser = MonParser::new(source, max_nesting_depth)
  let value = parser.parse_value(0)
  match parser.current().token {
    Eof => value
    _ =>
      raise Expected(
        parser.current().position,
        "the end of the document, found " + token_label(parser.current().token),
      )
  }
}

///|
/// Parse one MON document and report whether it is valid.
pub fn valid(source : StringView) -> Bool {
  try {
    parse(source) |> ignore
    true
  } catch {
    _ => false
  }
}
