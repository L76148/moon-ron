///|
test "checks valid RON" {
  check_source("(x: 1)")
}

///|
test "formats RON" {
  assert_eq(
    format_source("(x:1,y:[2,3])"),
    (
      #|(
      #|  x: 1,
      #|  y: [
      #|    2,
      #|    3,
      #|  ],
      #|)
    ),
  )
}

///|
test "compacts RON and preserves extension headers" {
  assert_eq(
    compact_source("#![enable(implicit_some)]\nConfig(count: 5)"),
    "#![enable(implicit_some)]\nConfig(count: 5)",
  )
}

///|
test "reports invalid RON" {
  try {
    check_source("[1,")
    fail("expected a parse error")
  } catch {
    Parse(_, _) => ()
    _ => fail("expected Parse")
  }
}
