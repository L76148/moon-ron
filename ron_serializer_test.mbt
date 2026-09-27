///|
fn roundtrip(value : @moon-ron.RonValue) -> Unit raise {
  assert_eq(@moon-ron.parse(@moon-ron.to_string(value)), value)
}

///|
test "serializes scalar values" {
  assert_eq(@moon-ron.to_string(@moon-ron.RonValue::Bool(true)), "true")
  assert_eq(
    @moon-ron.to_string(@moon-ron.RonValue::Number(Signed(-42L))),
    "-42",
  )
  assert_eq(
    @moon-ron.to_string(
      @moon-ron.RonValue::Number(Unsigned(18446744073709551615UL)),
    ),
    "18446744073709551615",
  )
  assert_eq(@moon-ron.to_string(@moon-ron.RonValue::Number(Float(1.0))), "1.0")
  assert_eq(@moon-ron.to_string(@moon-ron.RonValue::Number(Infinity)), "inf")
  assert_eq(
    @moon-ron.to_string(@moon-ron.RonValue::Number(NegativeInfinity)),
    "-inf",
  )
  assert_eq(@moon-ron.to_string(@moon-ron.RonValue::Number(NaN)), "NaN")
}

///|
test "escapes text and bytes" {
  assert_eq(
    @moon-ron.to_string(@moon-ron.RonValue::String("a\n\"b\\c\u{7f}")),
    "\"a\\n\\\"b\\\\c\\u{7f}\"",
  )
  assert_eq(@moon-ron.to_string(@moon-ron.RonValue::Char('\'')), "'\\''")
  assert_eq(
    @moon-ron.to_string(
      @moon-ron.RonValue::Bytes(
        Bytes::from_array([
          (65 : Int).to_byte(),
          Byte::default(),
          (255 : Int).to_byte(),
        ]),
      ),
    ),
    "b\"A\\x00\\xff\"",
  )
  assert_eq(
    @moon-ron.to_string(@moon-ron.RonValue::Byte((39 : Int).to_byte())),
    "b'\\''",
  )
}

///|
test "serializes structured values" {
  let value = @moon-ron.RonValue::Struct("Point", [
    ("x", @moon-ron.RonValue::Number(Signed(1L))),
    ("y", @moon-ron.RonValue::Number(Signed(2L))),
    (
      "tags",
      @moon-ron.RonValue::Sequence([
        @moon-ron.RonValue::String("parser"),
        @moon-ron.RonValue::String("ron"),
      ]),
    ),
  ])
  assert_eq(
    @moon-ron.to_string(value),
    "Point(x: 1, y: 2, tags: [\"parser\", \"ron\"])",
  )
  assert_eq(
    @moon-ron.to_string(
      @moon-ron.RonValue::Map([
        (
          @moon-ron.RonValue::Identifier("foo"),
          @moon-ron.RonValue::Number(Signed(1L)),
        ),
      ]),
    ),
    "{foo: 1}",
  )
  assert_eq(
    @moon-ron.to_string(
      @moon-ron.RonValue::Struct("", [
        ("x", @moon-ron.RonValue::Number(Signed(1L))),
      ]),
    ),
    "(x: 1)",
  )
  assert_eq(
    @moon-ron.to_string(
      @moon-ron.RonValue::EnumTuple("Color", "Rgb", [
        @moon-ron.RonValue::Number(Signed(255L)),
        @moon-ron.RonValue::Number(Signed(0L)),
        @moon-ron.RonValue::Number(Signed(0L)),
      ]),
    ),
    "Color::Rgb(255, 0, 0)",
  )
}

///|
test "round-trips canonical values" {
  let values = [
    @moon-ron.RonValue::Unit,
    @moon-ron.RonValue::Bool(false),
    @moon-ron.RonValue::Number(Signed(-9223372036854775808L)),
    @moon-ron.RonValue::Number(Float(-0.5)),
    @moon-ron.RonValue::Char('\n'),
    @moon-ron.RonValue::String("\u{1f600} and \"quotes\""),
    @moon-ron.RonValue::Bytes(
      Bytes::from_array([
        (0 : Int).to_byte(),
        (127 : Int).to_byte(),
        (255 : Int).to_byte(),
      ]),
    ),
    @moon-ron.RonValue::Byte((10 : Int).to_byte()),
    @moon-ron.RonValue::Option(None),
    @moon-ron.RonValue::Option(Some(@moon-ron.RonValue::Number(Signed(1L)))),
    @moon-ron.RonValue::Sequence([]),
    @moon-ron.RonValue::Tuple([
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::Number(Signed(2L)),
    ]),
    @moon-ron.RonValue::Map([]),
    @moon-ron.RonValue::Struct("Empty", []),
    @moon-ron.RonValue::TupleStruct("Pair", [
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::Number(Signed(2L)),
    ]),
    @moon-ron.RonValue::Enum("Status", "Ready", []),
    @moon-ron.RonValue::EnumTuple("Color", "Rgb", [
      @moon-ron.RonValue::Number(Signed(1L)),
    ]),
    @moon-ron.RonValue::Enum("Color", "Blue", []),
  ]
  for value in values {
    roundtrip(value)
  }
}
