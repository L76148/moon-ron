///|
test "parses closed and open ranges" {
  assert_eq(
    @moon-ron.parse("1..5"),
    @moon-ron.RonValue::Range({
      start: Some(@moon-ron.RonValue::Number(Signed(1L))),
      end: Some(@moon-ron.RonValue::Number(Signed(5L))),
      inclusive: false,
    }),
  )
  assert_eq(
    @moon-ron.parse("1..=5"),
    @moon-ron.RonValue::Range({
      start: Some(@moon-ron.RonValue::Number(Signed(1L))),
      end: Some(@moon-ron.RonValue::Number(Signed(5L))),
      inclusive: true,
    }),
  )
  assert_eq(
    @moon-ron.parse("..5"),
    @moon-ron.RonValue::Range({
      start: None,
      end: Some(@moon-ron.RonValue::Number(Signed(5L))),
      inclusive: false,
    }),
  )
  assert_eq(
    @moon-ron.parse("1.."),
    @moon-ron.RonValue::Range({
      start: Some(@moon-ron.RonValue::Number(Signed(1L))),
      end: None,
      inclusive: false,
    }),
  )
  assert_eq(
    @moon-ron.parse(".."),
    @moon-ron.RonValue::Range({ start: None, end: None, inclusive: false, }),
  )
}

///|
test "parses range bounds with decimal values" {
  assert_eq(
    @moon-ron.parse("-2.1..=7.3"),
    @moon-ron.RonValue::Range({
      start: Some(@moon-ron.RonValue::Number(Float(-2.1))),
      end: Some(@moon-ron.RonValue::Number(Float(7.3))),
      inclusive: true,
    }),
  )
  assert_eq(
    @moon-ron.parse("..=10.5"),
    @moon-ron.RonValue::Range({
      start: None,
      end: Some(@moon-ron.RonValue::Number(Float(10.5))),
      inclusive: true,
    }),
  )
}

///|
test "serializes and formats ranges" {
  let values = ["..", "..5", "1..", "1..5", "..=5", "1..=5"]
  for source in values {
    let value = @moon-ron.parse(source)
    assert_eq(@moon-ron.to_string(value), source)
    assert_eq(@moon-ron.to_string_pretty(value), source)
  }
}

///|
test "round-trips typed RON ranges" {
  let range : @moon-ron.RonRange = @moon-ron.decode("1..=5")
  assert_eq(@moon-ron.encode(range), "1..=5")
}
