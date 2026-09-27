///|
test "pretty-prints structured values" {
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
    @moon-ron.to_string_pretty(value),
    (
      #|Point(
      #|  x: 1,
      #|  y: 2,
      #|  tags: [
      #|    "parser",
      #|    "ron",
      #|  ],
      #|)
    ),
  )
}

///|
test "pretty-prints maps and custom indentation" {
  let value = @moon-ron.RonValue::Map([
    (
      @moon-ron.RonValue::Identifier("foo"),
      @moon-ron.RonValue::Number(Signed(1L)),
    ),
    (
      @moon-ron.RonValue::Identifier("bar"),
      @moon-ron.RonValue::Sequence([
        @moon-ron.RonValue::Number(Signed(2L)),
        @moon-ron.RonValue::Number(Signed(3L)),
      ]),
    ),
  ])
  assert_eq(
    @moon-ron.to_string_pretty(value, indent=4),
    (
      #|{
      #|    foo: 1,
      #|    bar: [
      #|        2,
      #|        3,
      #|    ],
      #|}
    ),
  )
}

///|
test "pretty printer keeps empty values compact" {
  assert_eq(@moon-ron.to_string_pretty(@moon-ron.RonValue::Sequence([])), "[]")
  assert_eq(@moon-ron.to_string_pretty(@moon-ron.RonValue::Tuple([])), "()")
  assert_eq(@moon-ron.to_string_pretty(@moon-ron.RonValue::Map([])), "{}")
  assert_eq(
    @moon-ron.to_string_pretty(@moon-ron.RonValue::Struct("Empty", [])),
    "Empty",
  )
  assert_eq(
    @moon-ron.to_string_pretty(@moon-ron.RonValue::Enum("Shape", "Dot", [])),
    "Shape::Dot",
  )
}

///|
test "pretty output parses back to the same value" {
  let values = [
    @moon-ron.RonValue::Unit,
    @moon-ron.RonValue::Sequence([
      @moon-ron.RonValue::Number(Signed(1L)),
      @moon-ron.RonValue::Tuple([
        @moon-ron.RonValue::String("nested"),
        @moon-ron.RonValue::Bool(true),
      ]),
    ]),
    @moon-ron.RonValue::Option(
      Some(
        @moon-ron.RonValue::Sequence([
          @moon-ron.RonValue::Number(Signed(1L)),
          @moon-ron.RonValue::Number(Signed(2L)),
        ]),
      ),
    ),
    @moon-ron.RonValue::Struct("Point", [
      ("x", @moon-ron.RonValue::Number(Signed(1L))),
      ("y", @moon-ron.RonValue::Number(Signed(2L))),
    ]),
    @moon-ron.RonValue::EnumTuple("Shape", "Circle", [
      @moon-ron.RonValue::Number(Float(1.5)),
    ]),
  ]
  for value in values {
    assert_eq(@moon-ron.parse(@moon-ron.to_string_pretty(value)), value)
  }
}
