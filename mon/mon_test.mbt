///|
test "parses scalar values" {
  assert_eq(@mon.parse("42"), @mon.MonValue::Number(@mon.MonNumber::Int(42)))
  assert_eq(@mon.parse("-7"), @mon.MonValue::Number(@mon.MonNumber::Int(-7)))
  assert_eq(@mon.parse("0x2A"), @mon.MonValue::Number(@mon.MonNumber::Int(42)))
  assert_eq(@mon.parse("0o52"), @mon.MonValue::Number(@mon.MonNumber::Int(42)))
  assert_eq(
    @mon.parse("0b101010"),
    @mon.MonValue::Number(@mon.MonNumber::Int(42)),
  )
  assert_eq(@mon.parse("true"), @mon.MonValue::Bool(true))
  assert_eq(@mon.parse("false"), @mon.MonValue::Bool(false))
  assert_eq(@mon.parse("'A'"), @mon.MonValue::Char('A'))
  assert_eq(@mon.parse("\"hi\""), @mon.MonValue::String("hi"))
  assert_eq(@mon.parse("()"), @mon.MonValue::Unit)
}

///|
test "parses suffixed numbers with the MoonBit widths" {
  assert_eq(
    @mon.parse("9_000_000_000L"),
    @mon.MonValue::Number(@mon.MonNumber::Int64(9000000000L)),
  )
  assert_eq(
    @mon.parse("4294967295U"),
    @mon.MonValue::Number(@mon.MonNumber::UInt(4294967295U)),
  )
  assert_eq(
    @mon.parse("18446744073709551615UL"),
    @mon.MonValue::Number(@mon.MonNumber::UInt64(18446744073709551615UL)),
  )
  assert_eq(
    @mon.parse("3.5"),
    @mon.MonValue::Number(@mon.MonNumber::Double(3.5)),
  )
  assert_eq(
    @mon.parse("1.25e-3"),
    @mon.MonValue::Number(@mon.MonNumber::Double(0.00125)),
  )
}

///|
test "tolerates a byte order mark" {
  assert_eq(
    @mon.parse("\u{FEFF}42"),
    @mon.MonValue::Number(@mon.MonNumber::Int(42)),
  )
}

///|
test "parses MoonBit escapes" {
  assert_eq(@mon.parse("'\\n'"), @mon.MonValue::Char('\n'))
  assert_eq(@mon.parse("'\\u{4E2D}'"), @mon.MonValue::Char('\u{4E2D}'))
  assert_eq(@mon.parse("\"\\u{4E2D}\""), @mon.MonValue::String("\u{4E2D}"))
  assert_eq(@mon.parse("\"\\u0041\""), @mon.MonValue::String("A"))
  assert_eq(@mon.parse("\"a\\tb\""), @mon.MonValue::String("a\tb"))
  assert_eq(@mon.parse("b\"\\x0f\""), @mon.MonValue::Bytes(b"\x0f"))
  assert_eq(@mon.parse("b\"\\x00\\x41A\""), @mon.MonValue::Bytes(b"\x00\x41A"))
  assert_eq(@mon.parse("b'\\x41'"), @mon.MonValue::Byte(b'A'))
}

///|
test "parses multiline strings" {
  assert_eq(
    @mon.parse("#|first\n#|second\n"),
    @mon.MonValue::String("first\nsecond"),
  )
  assert_eq(
    @mon.parse("#|first\n#|\n#|third\n"),
    @mon.MonValue::String("first\n\nthird"),
  )
  assert_eq(@mon.parse("#|  kept\n"), @mon.MonValue::String("  kept"))
  assert_eq(
    @mon.parse("(\n  #|inside\n  #|parens\n)"),
    @mon.MonValue::String("inside\nparens"),
  )
  assert_eq(
    @mon.parse("#|first\r\n#|second\r\n"),
    @mon.MonValue::String("first\nsecond"),
  )
}

///|
test "parses containers" {
  assert_eq(
    @mon.parse("[1, 2, 3]"),
    @mon.MonValue::Sequence([
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::Number(@mon.MonNumber::Int(2)),
      @mon.MonValue::Number(@mon.MonNumber::Int(3)),
    ]),
  )
  assert_eq(
    @mon.parse("[1, 2,]"),
    @mon.MonValue::Sequence([
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::Number(@mon.MonNumber::Int(2)),
    ]),
  )
  assert_eq(
    @mon.parse("(1, \"a\")"),
    @mon.MonValue::Tuple([
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::String("a"),
    ]),
  )
  assert_eq(@mon.parse("(1)"), @mon.MonValue::Number(@mon.MonNumber::Int(1)))
  assert_eq(
    @mon.parse("[\n  1,\n  [2, 3],\n]"),
    @mon.MonValue::Sequence([
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::Sequence([
        @mon.MonValue::Number(@mon.MonNumber::Int(2)),
        @mon.MonValue::Number(@mon.MonNumber::Int(3)),
      ]),
    ]),
  )
}

///|
test "separates maps from field maps" {
  assert_eq(
    @mon.parse("{\"a\": 1}"),
    @mon.MonValue::Map([
      (
        @mon.MonValue::String("a"),
        @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      ),
    ]),
  )
  assert_eq(
    @mon.parse("{ a: 1 }"),
    @mon.MonValue::Fields([("a", @mon.MonValue::Number(@mon.MonNumber::Int(1)))]),
  )
  assert_eq(@mon.parse("{}"), @mon.MonValue::Map([]))
}

///|
test "parses constructors" {
  assert_eq(
    @mon.parse("Some(1)"),
    @mon.MonValue::TupleVariant("Some", [
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
    ]),
  )
  assert_eq(@mon.parse("None"), @mon.MonValue::Variant("None"))
  assert_eq(@mon.parse("Color::Red"), @mon.MonValue::Variant("Color::Red"))
  assert_eq(
    @mon.parse("Point(1, 2)"),
    @mon.MonValue::TupleVariant("Point", [
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::Number(@mon.MonNumber::Int(2)),
    ]),
  )
  assert_eq(
    @mon.parse("Point { x: 1, y: 2 }"),
    @mon.MonValue::Record("Point", [
      ("x", @mon.MonValue::Number(@mon.MonNumber::Int(1))),
      ("y", @mon.MonValue::Number(@mon.MonNumber::Int(2))),
    ]),
  )
  assert_eq(
    @mon.parse("Queue(Backlog { depth: 8 })"),
    @mon.MonValue::TupleVariant("Queue", [
      @mon.MonValue::Record("Backlog", [
        ("depth", @mon.MonValue::Number(@mon.MonNumber::Int(8))),
      ]),
    ]),
  )
}

///|
test "parses ranges" {
  assert_eq(
    @mon.parse("1..10"),
    @mon.MonValue::Range(
      @mon.MonRange::new(
        start=@mon.MonValue::Number(@mon.MonNumber::Int(1)),
        end=@mon.MonValue::Number(@mon.MonNumber::Int(10)),
      ),
    ),
  )
  assert_eq(
    @mon.parse("1..=10"),
    @mon.MonValue::Range(
      @mon.MonRange::new(
        start=@mon.MonValue::Number(@mon.MonNumber::Int(1)),
        end=@mon.MonValue::Number(@mon.MonNumber::Int(10)),
        inclusive=true,
      ),
    ),
  )
  assert_eq(
    @mon.parse("..10"),
    @mon.MonValue::Range(
      @mon.MonRange::new(end=@mon.MonValue::Number(@mon.MonNumber::Int(10))),
    ),
  )
  assert_eq(
    @mon.parse("1.."),
    @mon.MonValue::Range(
      @mon.MonRange::new(start=@mon.MonValue::Number(@mon.MonNumber::Int(1))),
    ),
  )
}

///|
test "skips comments" {
  assert_eq(
    @mon.parse("// leading\n42 // trailing\n"),
    @mon.MonValue::Number(@mon.MonNumber::Int(42)),
  )
  assert_eq(
    @mon.parse("[\n  1, // one\n  2,\n]"),
    @mon.MonValue::Sequence([
      @mon.MonValue::Number(@mon.MonNumber::Int(1)),
      @mon.MonValue::Number(@mon.MonNumber::Int(2)),
    ]),
  )
}

///|
test "exposes accessors" {
  let value = @mon.parse("Config { name: \"mon\", ports: [1, 2] }")
  assert_eq(value.kind(), "record")
  assert_eq(value.variant_name(), Some("Config"))
  assert_eq(value.length(), Some(2))
  assert_eq(value.field("name"), Some(@mon.MonValue::String("mon")))
  assert_eq(value.field("missing"), None)
  let ports = value.field("ports") |> Option::unwrap
  assert_eq(ports.length(), Some(2))
  assert_eq(@mon.parse("1").length(), None)
}

///|
test "reports invalid documents" {
  let invalid = [
    "", "\"", "'\\0'", "\"\\0\"", "\"\\v\"", "1e10", "1l", "1_", "1Lx", "/* block */ 1",
    "value", "Color::red", "{ x: }", "(1", "[1, 2", "Point { 1 }", "1..2..3", "1..=..2",
    "0x",
  ]
  for source in invalid {
    assert_false(@mon.valid(source))
  }
}

///|
test "accepts the forms the grammar allows" {
  let valid = [
    "()", "[]", "{}", "None", "Point {}", "1..", "..2", "..", "b\"\"", "1_000", "0xFF_FF",
    "[Some(1), None, Ok(2)]",
  ]
  for source in valid {
    assert_true(@mon.valid(source))
  }
}

///|
test "reports error positions" {
  let source = "[\n  1,\n  @\n]"
  let error : @mon.MonError = try {
    @mon.parse(source) |> ignore
    fail("expected parse error")
  } catch {
    @mon.UnexpectedChar(_, _) as error => error
    _ => fail("expected UnexpectedChar")
  }
  assert_eq(
    @mon.render_error(source, error),
    (
      #|error: unexpected character '@' at line 3, column 3
      #|  |
      #|3 |   @
      #|  |   ^
    ),
  )
}

///|
test "reports the token the grammar wanted" {
  let source = "{ x: }"
  let error : @mon.MonError = try {
    @mon.parse(source) |> ignore
    fail("expected parse error")
  } catch {
    @mon.Expected(_, _) as error => error
    _ => fail("expected Expected")
  }
  assert_eq(
    @mon.render_error(source, error),
    (
      #|error: expected a value, found `}` at line 1, column 6
      #|  |
      #|1 | { x: }
      #|  |      ^
    ),
  )
}

///|
test "limits nesting depth" {
  assert_true(@mon.valid("[[1]]"))
  assert_eq(
    @mon.parse("[[1]]", max_nesting_depth=2),
    @mon.MonValue::Sequence([
      @mon.MonValue::Sequence([@mon.MonValue::Number(@mon.MonNumber::Int(1))]),
    ]),
  )
  try {
    @mon.parse("[[[1]]]", max_nesting_depth=2) |> ignore
    fail("expected a depth limit error")
  } catch {
    @mon.DepthLimitExceeded(limit) => assert_eq(limit, 2)
    _ => fail("expected DepthLimitExceeded")
  }
}
