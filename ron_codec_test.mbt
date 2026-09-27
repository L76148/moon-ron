///|
priv struct Point {
  x : Int
  y : Int
} derive(Eq, Debug)

///|
impl @moon-ron.ToRon for Point with fn to_ron(self, options) {
  @moon-ron.RonValue::Struct("Point", [
    ("x", @moon-ron.ToRon::to_ron(self.x, options)),
    ("y", @moon-ron.ToRon::to_ron(self.y, options)),
  ])
}

///|
impl @moon-ron.FromRon for Point with fn from_ron(value, path, options) {
  @moon-ron.require_struct_name(value, "Point", path, options)
  let fields = @moon-ron.struct_fields(value, path)
  {
    x: @moon-ron.field(fields, "x", path, options),
    y: @moon-ron.field(fields, "y", path, options),
  }
}

///|
priv enum Shape {
  Dot
  Circle(Double)
} derive(Eq, Debug)

///|
impl @moon-ron.ToRon for Shape with fn to_ron(self, options) {
  match self {
    Dot => @moon-ron.RonValue::Enum("Shape", "Dot", [])
    Circle(radius) =>
      @moon-ron.RonValue::EnumTuple("Shape", "Circle", [
        @moon-ron.ToRon::to_ron(radius, options),
      ])
  }
}

///|
impl @moon-ron.FromRon for Shape with fn from_ron(value, path, options) {
  match value {
    @moon-ron.RonValue::Enum("Shape", "Dot", _) => Dot
    @moon-ron.RonValue::EnumTuple("Shape", "Circle", values) =>
      Circle(@moon-ron.positional(values, 0, path, options))
    _ => raise @moon-ron.UnknownVariant(path, @moon-ron.value_type_name(value))
  }
}

///|
test "decodes primitive and container types" {
  let int : Int = @moon-ron.decode("42")
  assert_eq(int, 42)
  let int64 : Int64 = @moon-ron.decode("-9223372036854775808")
  assert_eq(int64, -9223372036854775808L)
  let uint64 : UInt64 = @moon-ron.decode("18446744073709551615")
  assert_eq(uint64, 18446744073709551615UL)
  let flag : Bool = @moon-ron.decode("true")
  assert_eq(flag, true)
  let values : Array[Int] = @moon-ron.decode("[1, 2, 3]")
  assert_eq(values, [1, 2, 3])
  let maybe : String? = @moon-ron.decode("Some(\"ok\")")
  assert_eq(maybe, Some("ok"))
  let pair : (Int, String) = @moon-ron.decode("(1, \"one\")")
  assert_eq(pair, (1, "one"))
  let map : Map[String, Int] = @moon-ron.decode("{foo: 1, bar: 2}")
  assert_eq(map["foo"], 1)
  assert_eq(map["bar"], 2)
}

///|
test "encodes primitive and container types" {
  assert_eq(@moon-ron.encode([1, 2, 3]), "[1, 2, 3]")
  assert_eq(@moon-ron.encode(Some("ok")), "Some(\"ok\")")
  assert_eq(@moon-ron.encode((1, "one")), "(1, \"one\")")
}

///|
test "round-trips custom structs and enums" {
  let point : Point = { x: 1, y: 2, }
  assert_eq(@moon-ron.encode(point), "Point(x: 1, y: 2)")
  let decoded : Point = @moon-ron.decode(@moon-ron.encode(point))
  assert_eq(decoded, point)

  assert_eq(@moon-ron.encode(Dot), "Shape::Dot")
  assert_eq(@moon-ron.encode(Circle(1.5)), "Shape::Circle(1.5)")
  let circle : Shape = @moon-ron.decode("Shape::Circle(2.0)")
  assert_eq(circle, Circle(2.0))
}

///|
test "reports typed decode errors with paths" {
  try {
    let _ : Point = @moon-ron.decode("Point(x: 1)")
    fail("expected a missing field")
  } catch {
    @moon-ron.MissingField(path, name) => {
      assert_eq(path.to_string(), "$")
      assert_eq(name, "y")
    }
    _ => fail("expected MissingField")
  }
  try {
    let _ : Point = @moon-ron.decode("Point(x: 1, y: \"bad\")")
    fail("expected a type mismatch")
  } catch {
    @moon-ron.TypeMismatch(path, expected, actual) => {
      assert_eq(path.to_string(), "$.y")
      assert_eq(expected, "Int")
      assert_eq(actual, "string")
    }
    _ => fail("expected TypeMismatch")
  }
  try {
    let _ : (Int, Int) = @moon-ron.decode("(1, 2, 3)")
    fail("expected a tuple length error")
  } catch {
    @moon-ron.UnexpectedTupleLength(path, expected, actual) => {
      assert_eq(path, @moon-ron.RonPath::Root)
      assert_eq(expected, 2)
      assert_eq(actual, 3)
    }
    _ => fail("expected UnexpectedTupleLength")
  }
  try {
    let _ : Point = @moon-ron.decode("Point(x: 1,")
    fail("expected a syntax error")
  } catch {
    @moon-ron.Syntax(_) => ()
    _ => fail("expected Syntax")
  }
}
