///|
priv struct Meters(Int) derive(Eq, Debug)

///|
impl @moon-ron.ToRon for Meters with fn to_ron(self, options) {
  if options.extensions.unwrap_newtypes {
    @moon-ron.ToRon::to_ron(self.0, options)
  } else {
    @moon-ron.RonValue::Tuple([@moon-ron.ToRon::to_ron(self.0, options)])
  }
}

///|
impl @moon-ron.FromRon for Meters with fn from_ron(value, path, options) {
  Meters(@moon-ron.newtype(value, path, options))
}

///|
priv enum Wrapped {
  Number(Int)
} derive(Eq, Debug)

///|
impl @moon-ron.ToRon for Wrapped with fn to_ron(self, options) {
  match self {
    Number(value) =>
      @moon-ron.RonValue::TupleStruct("Number", [
        @moon-ron.ToRon::to_ron(value, options),
      ])
  }
}

///|
impl @moon-ron.FromRon for Wrapped with fn from_ron(value, path, options) {
  Number(@moon-ron.variant_newtype(value, "Number", path, options))
}

///|
test "parses document extension attributes" {
  let document = @moon-ron.parse_document(
    "#![enable(implicit_some, unwrap_newtypes)]\n(1)",
  )
  assert_true(document.extensions.implicit_some)
  assert_true(document.extensions.unwrap_newtypes)
  assert_false(document.extensions.explicit_struct_names)
  assert_eq(
    document.value,
    @moon-ron.RonValue::Tuple([@moon-ron.RonValue::Number(Signed(1L))]),
  )
}

///|
test "ignores compatibility attributes" {
  let document = @moon-ron.parse_document(
    (
      #|#![type = "example::Config"]
      #|#![schema = "./config.schema.ron"]
      #|42
    ),
  )
  assert_eq(document.value, @moon-ron.RonValue::Number(Signed(42L)))
}

///|
test "rejects unknown attributes and extensions" {
  assert_false(@moon-ron.valid("#![unknown]\n42"))
  assert_false(@moon-ron.valid("#![enable(unknown_extension)]\n42"))
}

///|
test "applies implicit_some during typed decoding" {
  let value : Int? = @moon-ron.decode("#![enable(implicit_some)]\n42")
  assert_eq(value, Some(42))
  let explicit : Int? = @moon-ron.decode("Some(7)")
  assert_eq(explicit, Some(7))
  let options = @moon-ron.RonOptions::default().with_extension({
    ..@moon-ron.RonExtensions::empty(),
    implicit_some: true,
  })
  assert_eq(
    @moon-ron.encode_with_options(value, options~),
    "#![enable(implicit_some)]\n42",
  )
}

///|
test "applies unwrap_newtypes during typed decoding" {
  let wrapped : Meters = @moon-ron.decode("(5)")
  assert_eq(wrapped, Meters(5))
  let unwrapped : Meters = @moon-ron.decode("#![enable(unwrap_newtypes)]\n5")
  assert_eq(unwrapped, Meters(5))
  let options = @moon-ron.RonOptions::default().with_extension({
    ..@moon-ron.RonExtensions::empty(),
    unwrap_newtypes: true,
  })
  assert_eq(
    @moon-ron.encode_with_options(unwrapped, options~),
    "#![enable(unwrap_newtypes)]\n5",
  )
}

///|
test "applies explicit_struct_names during typed decoding" {
  let anonymous : Point = @moon-ron.decode("(x: 1, y: 2)")
  assert_eq(anonymous, { x: 1, y: 2, })
  let named : Point = @moon-ron.decode("Point(x: 1, y: 2)")
  assert_eq(named, { x: 1, y: 2, })
  let options = @moon-ron.RonOptions::default().with_extension({
    ..@moon-ron.RonExtensions::empty(),
    explicit_struct_names: true,
  })
  try {
    let _ : Point = @moon-ron.decode_with_options("(x: 1, y: 2)", options~)
    fail("expected explicit struct name error")
  } catch {
    _ => ()
  }
}

///|
test "applies unwrap_variant_newtypes during typed decoding" {
  assert_eq(@moon-ron.encode(Number(3)), "Number(3)")
  let value : Wrapped = @moon-ron.decode("Number(9)")
  assert_eq(value, Number(9))
  let options = @moon-ron.RonOptions::default().with_extension({
    ..@moon-ron.RonExtensions::empty(),
    unwrap_variant_newtypes: true,
  })
  let value : Wrapped = @moon-ron.decode_with_options("Number(10)", options~)
  assert_eq(value, Number(10))
}
