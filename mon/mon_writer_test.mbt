///|
test "writes scalars in canonical form" {
  assert_eq(
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::Int(42))),
    "42",
  )
  assert_eq(
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::Int(-7))),
    "-7",
  )
  assert_eq(
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::Int64(9000000000L))),
    "9000000000L",
  )
  assert_eq(
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::UInt(4294967295U))),
    "4294967295U",
  )
  assert_eq(
    @mon.to_string(
      @mon.MonValue::Number(@mon.MonNumber::UInt64(18446744073709551615UL)),
    ),
    "18446744073709551615UL",
  )
  assert_eq(
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::Double(3.5))),
    "3.5",
  )
  assert_eq(@mon.to_string(@mon.MonValue::Unit), "()")
  assert_eq(@mon.to_string(@mon.MonValue::Bool(false)), "false")
  assert_eq(@mon.to_string(@mon.MonValue::Char('\'')), "'\\''")
  assert_eq(@mon.to_string(@mon.MonValue::String("a\tb")), "\"a\\tb\"")
  assert_eq(
    @mon.to_string(@mon.MonValue::String("line\nbreak")),
    "\"line\\nbreak\"",
  )
  assert_eq(@mon.to_string(@mon.MonValue::Byte(b'A')), "b'A'")
  assert_eq(
    @mon.to_string(@mon.MonValue::Bytes(b"\x00\xff")),
    "b\"\\x00\\xff\"",
  )
}

///|
/// An integral double has to keep a fractional part, and a printed exponent
/// has to gain one, or the text reads back as an `Int`.
test "writes doubles that read back as doubles" {
  let doubles : Array[Double] = [3.0, -1.0, 1.0e-7, 1.0e300, 0.5]
  for value in doubles {
    let text = @mon.to_string(
      @mon.MonValue::Number(@mon.MonNumber::Double(value)),
    )
    assert_eq(
      @mon.parse(text),
      @mon.MonValue::Number(@mon.MonNumber::Double(value)),
    )
  }
}

///|
test "writes containers, fields, and constructors" {
  let value = @mon.MonValue::Record("Config", [
    ("name", @mon.MonValue::String("mon")),
    (
      "ports",
      @mon.MonValue::Sequence([@mon.MonValue::Number(@mon.MonNumber::Int(8080))]),
    ),
  ])
  assert_eq(@mon.to_string(value), "Config { name: \"mon\", ports: [8080] }")
  assert_eq(@mon.to_string(@mon.MonValue::Map([])), "{}")
  assert_eq(
    @mon.to_string(
      @mon.MonValue::Fields([("retry", @mon.MonValue::Bool(true))]),
    ),
    "{ retry: true }",
  )
  assert_eq(
    @mon.to_string(
      @mon.MonValue::TupleVariant("Some", [@mon.MonValue::Variant("None")]),
    ),
    "Some(None)",
  )
  assert_eq(
    @mon.to_string(
      @mon.MonValue::Range(
        @mon.MonRange::new(
          start=@mon.MonValue::Number(@mon.MonNumber::Int(1)),
          end=@mon.MonValue::Number(@mon.MonNumber::Int(10)),
          inclusive=true,
        ),
      ),
    ),
    "1..=10",
  )
  assert_eq(
    @mon.to_string(
      @mon.MonValue::Range(@mon.MonRange::new(end=@mon.MonValue::Unit)),
    ),
    "..()",
  )
}

///|
/// MoonBit has no one-element tuple, so the compact form adds the comma that
/// keeps `(1,)` a tuple.
test "writes one-element tuples with a trailing comma" {
  let value = @mon.MonValue::Tuple([
    @mon.MonValue::Number(@mon.MonNumber::Int(1)),
  ])
  let text = @mon.to_string(value)
  assert_eq(text, "(1,)")
  assert_eq(@mon.parse(text), value)
}

///|
test "pretty-prints nested values" {
  let value = @mon.parse(
    "Service { name: \"api\", protocol: Protocol::Queue(Backlog { depth: 8 }), window: 5.. }",
  )
  assert_eq(
    @mon.to_string_pretty(value),
    (
      #|Service {
      #|  name: "api",
      #|  protocol: Protocol::Queue(
      #|    Backlog {
      #|      depth: 8,
      #|    },
      #|  ),
      #|  window: 5..,
      #|}
    ),
  )
}

///|
test "pretty-prints with a custom indent and keeps empty containers compact" {
  let value = @mon.parse("[[], {}]")
  assert_eq(
    @mon.to_string_pretty(value, indent=4),
    (
      #|[
      #|    [],
      #|    {},
      #|]
    ),
  )
}

///|
/// Documents that cover every shape the writer has to reproduce.
fn round_trip_documents() -> Array[String] {
  [
    "()", "true", "'\\u{4E2D}'", "\"line\\nbreak\"", "#|first\n#|second\n", "Some(Point { x: 1, y: 2 })",
    "[1, 2, 3]", "(1, \"a\", [2])", "{ \"cpu\": 4, \"memory\": 1024U }", "{ retry: true, debug: false }",
    "Color::Red", "Protocol::Queue(Backlog { depth: 100 })", "9_000_000_000L", "18446744073709551615UL",
    "1.25e-3", "b\"\\x00\\xff\"", "1..10", "1..=10", "..10", "1..", "..",
  ]
}

///|
test "round-trips every shape it writes" {
  for document in round_trip_documents() {
    let value = @mon.parse(document)
    assert_eq(@mon.parse(@mon.to_string(value)), value)
    assert_eq(@mon.parse(@mon.to_string_pretty(value)), value)
  }
}

///|
test "refuses values the grammar cannot spell" {
  try {
    @mon.to_string(@mon.MonValue::Tuple([])) |> ignore
    fail("expected an unrepresentable value")
  } catch {
    @mon.UnrepresentableValue(_) => ()
    _ => fail("expected UnrepresentableValue")
  }
  try {
    @mon.to_string(@mon.MonValue::Number(@mon.MonNumber::Double(1.0e310)))
    |> ignore
    fail("expected an unrepresentable number")
  } catch {
    @mon.UnrepresentableNumber(_) => ()
    _ => fail("expected UnrepresentableNumber")
  }
  try {
    @mon.to_string(@mon.MonValue::Variant("lower")) |> ignore
    fail("expected an invalid name")
  } catch {
    @mon.InvalidName(_) => ()
    _ => fail("expected InvalidName")
  }
  try {
    @mon.to_string(@mon.MonValue::Fields([("Upper", @mon.MonValue::Unit)]))
    |> ignore
    fail("expected an invalid field name")
  } catch {
    @mon.InvalidName(_) => ()
    _ => fail("expected InvalidName")
  }
}

///|
test "renders writer errors" {
  assert_eq(
    @mon.render_write_error(@mon.InvalidName("lower")),
    "error: `lower` is not a MON name",
  )
  assert_eq(
    @mon.render_write_error(
      @mon.UnrepresentableValue("a tuple needs at least one element"),
    ),
    "error: a tuple needs at least one element",
  )
}
