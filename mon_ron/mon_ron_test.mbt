///|
test "converts MON scalars to RON" {
  assert_eq(@mon_ron.to_ron(@mon.parse("()")), @ron.RonValue::Unit)
  assert_eq(@mon_ron.to_ron(@mon.parse("true")), @ron.RonValue::Bool(true))
  assert_eq(
    @mon_ron.to_ron(@mon.parse("42")),
    @ron.RonValue::Number(Signed(42L)),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("9000000000L")),
    @ron.RonValue::Number(Signed(9000000000L)),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("4294967295U")),
    @ron.RonValue::Number(Unsigned(4294967295UL)),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("3.5")),
    @ron.RonValue::Number(Float(3.5)),
  )
  assert_eq(@mon_ron.to_ron(@mon.parse("'A'")), @ron.RonValue::Char('A'))
  assert_eq(@mon_ron.to_ron(@mon.parse("\"hi\"")), @ron.RonValue::String("hi"))
  assert_eq(
    @mon_ron.to_ron(@mon.parse("b\"\\x0f\"")),
    @ron.RonValue::Bytes(b"\x0f"),
  )
  assert_eq(@mon_ron.to_ron(@mon.parse("b'A'")), @ron.RonValue::Byte(b'A'))
}

///|
test "converts MON containers and constructors to RON" {
  assert_eq(
    @mon_ron.to_ron(@mon.parse("Some(1)")),
    @ron.RonValue::Option(Some(@ron.RonValue::Number(Signed(1L)))),
  )
  assert_eq(@mon_ron.to_ron(@mon.parse("None")), @ron.RonValue::Option(None))
  assert_eq(
    @mon_ron.to_ron(@mon.parse("Point(1, 2)")),
    @ron.RonValue::TupleStruct("Point", [
      @ron.RonValue::Number(Signed(1L)),
      @ron.RonValue::Number(Signed(2L)),
    ]),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("Point { x: 1 }")),
    @ron.RonValue::Struct("Point", [("x", @ron.RonValue::Number(Signed(1L)))]),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("Color::Red")),
    @ron.RonValue::Enum("Color", "Red", []),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("Color::Rgb(1)")),
    @ron.RonValue::EnumTuple("Color", "Rgb", [@ron.RonValue::Number(Signed(1L))]),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("{ retry: true }")),
    @ron.RonValue::Map([
      (@ron.RonValue::Identifier("retry"), @ron.RonValue::Bool(true)),
    ]),
  )
  assert_eq(
    @mon_ron.to_ron(@mon.parse("1..=10")),
    @ron.RonValue::Range({
      start: Some(@ron.RonValue::Number(Signed(1L))),
      end: Some(@ron.RonValue::Number(Signed(10L))),
      inclusive: true,
    }),
  )
}

///|
test "converts RON values to MON" {
  assert_eq(
    @mon_ron.from_ron(
      @ron.RonValue::Struct("", [("x", @ron.RonValue::Bool(true))]),
    ),
    @mon.parse("{ x: true }"),
  )
  assert_eq(
    @mon_ron.from_ron(
      @ron.RonValue::Map([
        (@ron.RonValue::Identifier("retry"), @ron.RonValue::Bool(true)),
      ]),
    ),
    @mon.parse("{ retry: true }"),
  )
  assert_eq(
    @mon_ron.from_ron(
      @ron.RonValue::Map([
        (@ron.RonValue::String("cpu"), @ron.RonValue::Number(Signed(4L))),
      ]),
    ),
    @mon.parse("{ \"cpu\": 4 }"),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Enum("Color", "Red", [])),
    @mon.parse("Color::Red"),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Struct("Point", [])),
    @mon.parse("Point"),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Option(Some(@ron.RonValue::Unit))),
    @mon.parse("Some(())"),
  )
}

///|
/// RON keeps one number type and MON spells widths with suffixes, so the
/// narrowest MON type that holds the value is used.
test "narrows RON numbers to the MON spelling that holds them" {
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Number(Signed(42L))),
    @mon.MonValue::Number(@mon.MonNumber::Int(42)),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Number(Signed(9000000000L))),
    @mon.MonValue::Number(@mon.MonNumber::Int64(9000000000L)),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Number(Unsigned(4294967295UL))),
    @mon.MonValue::Number(@mon.MonNumber::UInt(4294967295U)),
  )
  assert_eq(
    @mon_ron.from_ron(@ron.RonValue::Number(Unsigned(18446744073709551615UL))),
    @mon.MonValue::Number(@mon.MonNumber::UInt64(18446744073709551615UL)),
  )
}

///|
/// Documents that survive both notations: MON value to RON value to RON text
/// and back, then to a MON value again.
fn bridging_documents() -> Array[String] {
  [
    "()", "true", "'\\u{4E2D}'", "\"line\\nbreak\"", "Some(Point { x: 1, y: 2 })",
    "None", "[1, 2, 3]", "(1, \"a\")", "{ \"cpu\": 4 }", "{ retry: true, debug: false }",
    "Color::Red", "Protocol::Queue(Backlog { depth: 100 })", "9000000000L", "18446744073709551615UL",
    "1.25e-3", "b\"\\x00\\xff\"", "1..=10", "..10", "1..", "..",
  ]
}

///|
test "round-trips documents through RON text" {
  for document in bridging_documents() {
    let value = @mon.parse(document)
    let ron_source = @ron.to_string(@mon_ron.to_ron(value))
    assert_eq(@mon_ron.from_ron(@ron.parse(ron_source)), value)
  }
}

///|
test "refuses the RON shapes MON cannot spell" {
  try {
    @mon_ron.from_ron(@ron.parse("foo")) |> ignore
    fail("expected an identifier error")
  } catch {
    @mon_ron.UnrepresentableIdentifier(name) => assert_eq(name, "foo")
    _ => fail("expected UnrepresentableIdentifier")
  }
  try {
    @mon_ron.from_ron(@ron.parse("inf")) |> ignore
    fail("expected a number error")
  } catch {
    @mon_ron.UnrepresentableNumber(_) => ()
    _ => fail("expected UnrepresentableNumber")
  }
  try {
    @mon_ron.to_ron(@mon.parse("Some(1, 2)")) |> ignore
    fail("expected an option error")
  } catch {
    @mon_ron.InvalidOption(count) => assert_eq(count, 2)
    _ => fail("expected InvalidOption")
  }
}

///|
test "describes conversion errors" {
  assert_eq(
    @mon_ron.MonConvertError::message(@mon_ron.InvalidOption(0)),
    "`Some` takes exactly one value, but 0 were given",
  )
  assert_true(
    @mon_ron.MonConvertError::message(@mon_ron.UnrepresentableIdentifier("foo")).contains(
      "foo",
    ),
  )
}
