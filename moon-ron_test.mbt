///|
test "parses scalar values" {
  assert_eq(@moon-ron.parse("42"), @moon-ron.RonValue::Number(Signed(42L)))
  assert_eq(
    @moon-ron.parse("18446744073709551615"),
    @moon-ron.RonValue::Number(Unsigned(18446744073709551615UL)),
  )
  assert_eq(@moon-ron.parse("3.5"), @moon-ron.RonValue::Number(Float(3.5)))
  assert_eq(@moon-ron.parse("true"), @moon-ron.RonValue::Bool(true))
  assert_eq(@moon-ron.parse("false"), @moon-ron.RonValue::Bool(false))
  assert_eq(@moon-ron.parse("'A'"), @moon-ron.RonValue::Char('A'))
  assert_eq(@moon-ron.parse("\"hello\""), @moon-ron.RonValue::String("hello"))
}

///|
test "parses integer spellings" {
  assert_eq(
    @moon-ron.parse("-9223372036854775808"),
    @moon-ron.RonValue::Number(Signed(-9223372036854775808L)),
  )
  assert_eq(
    @moon-ron.parse("0xff_ff"),
    @moon-ron.RonValue::Number(Signed(65535L)),
  )
  assert_eq(@moon-ron.parse("0o755"), @moon-ron.RonValue::Number(Signed(493L)))
  assert_eq(
    @moon-ron.parse("0b1010_0101"),
    @moon-ron.RonValue::Number(Signed(165L)),
  )
}

///|
test "parses floating point spellings" {
  assert_eq(@moon-ron.parse("1.25e2"), @moon-ron.RonValue::Number(Float(125.0)))
  assert_eq(@moon-ron.parse("inf"), @moon-ron.RonValue::Number(Infinity))
  assert_eq(
    @moon-ron.parse("-inf"),
    @moon-ron.RonValue::Number(NegativeInfinity),
  )
  assert_true(
    match @moon-ron.parse("NaN") {
      @moon-ron.RonValue::Number(nan) => nan == NaN
      _ => false
    },
  )
}

///|
test "parses escaped strings and chars" {
  assert_eq(
    @moon-ron.parse("\"\\n\\t\\x41\\u{1f600}\""),
    @moon-ron.RonValue::String("\n\tA\u{1f600}"),
  )
  assert_eq(@moon-ron.parse("'\\x7f'"), @moon-ron.RonValue::Char('\u{7f}'))
}

///|
test "parses byte values" {
  assert_eq(
    @moon-ron.parse("b\"A\\x00\\xff\""),
    @moon-ron.RonValue::Bytes(
      Bytes::from_array([
        (65 : Int).to_byte(),
        Byte::default(),
        (255 : Int).to_byte(),
      ]),
    ),
  )
  assert_eq(
    @moon-ron.parse("b'Z'"),
    @moon-ron.RonValue::Byte((90 : Int).to_byte()),
  )
  assert_eq(
    @moon-ron.parse("br#\"raw\\bytes\"#"),
    @moon-ron.RonValue::Bytes(
      Bytes::from_array([
        (114 : Int).to_byte(),
        (97 : Int).to_byte(),
        (119 : Int).to_byte(),
        (92 : Int).to_byte(),
        (98 : Int).to_byte(),
        (121 : Int).to_byte(),
        (116 : Int).to_byte(),
        (101 : Int).to_byte(),
        (115 : Int).to_byte(),
      ]),
    ),
  )
}

///|
test "parses comments and raw strings" {
  let source =
    #|/* outer /* nested */ comment */
    #|r#"a "quoted" value"# // trailing comment
  assert_eq(
    @moon-ron.parse(source),
    @moon-ron.RonValue::String("a \"quoted\" value"),
  )
}

///|
test "parses containers and trailing commas" {
  assert_eq(
    @moon-ron.parse("[1, 2, 3,]"),
    @moon-ron.RonValue::Sequence([
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::Number(Signed(2L)),
      @moon-ron.RonValue::Number(Signed(3L)),
    ]),
  )
  assert_eq(
    @moon-ron.parse("(1, \"two\",)"),
    @moon-ron.RonValue::Tuple([
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::String("two"),
    ]),
  )
  assert_eq(@moon-ron.parse("()"), @moon-ron.RonValue::Unit)
}

///|
test "parses maps and named values" {
  assert_eq(
    @moon-ron.parse("{ \"a\": 1, 2: true }"),
    @moon-ron.RonValue::Map([
      (@moon-ron.RonValue::String("a"), @moon-ron.RonValue::Number(Signed(1L))),
      (@moon-ron.RonValue::Number(Signed(2L)), @moon-ron.RonValue::Bool(true)),
    ]),
  )
  assert_eq(
    @moon-ron.parse("Point(x: 1, y: 2)"),
    @moon-ron.RonValue::Struct("Point", [
      ("x", @moon-ron.RonValue::Number(Signed(1L))),
      ("y", @moon-ron.RonValue::Number(Signed(2L))),
    ]),
  )
  assert_eq(
    @moon-ron.parse("Point(1, 2)"),
    @moon-ron.RonValue::TupleStruct("Point", [
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::Number(Signed(2L)),
    ]),
  )
}

///|
test "parses options and enums" {
  assert_eq(@moon-ron.parse("None"), @moon-ron.RonValue::Option(None))
  assert_eq(
    @moon-ron.parse("Some(42)"),
    @moon-ron.RonValue::Option(Some(@moon-ron.RonValue::Number(Signed(42L)))),
  )
  assert_eq(
    @moon-ron.parse("Color::Red"),
    @moon-ron.RonValue::Identifier("Color::Red"),
  )
  assert_eq(
    @moon-ron.parse("Color::Rgb(255, 0, 0)"),
    @moon-ron.RonValue::EnumTuple("Color", "Rgb", [
      @moon-ron.RonValue::Number(Signed(255L)),
      @moon-ron.RonValue::Number(Signed(0L)),
      @moon-ron.RonValue::Number(Signed(0L)),
    ]),
  )
}

///|
test "rejects malformed input" {
  assert_false(@moon-ron.valid("[1, 2"))
  assert_false(@moon-ron.valid("\"\\q\""))
  assert_false(@moon-ron.valid("0x"))
  assert_false(@moon-ron.valid("/* unterminated"))
  assert_false(@moon-ron.valid("\"\\u{d800}\""))
  assert_false(@moon-ron.valid("Some(1, 2)"))
}

///|
test "enforces nesting depth" {
  try {
    @moon-ron.parse("[[[[0]]]]", max_nesting_depth=2) |> ignore
    fail("expected a depth error")
  } catch {
    @moon-ron.DepthLimitExceeded(limit) => assert_eq(limit, 2)
    _ => fail("expected DepthLimitExceeded")
  }
}
