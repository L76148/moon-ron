///|
test "generates MoonBit source for records and variants" {
  let value = @mon.parse("Config { name: \"mon\", protocol: Protocol::Https }")
  assert_eq(
    @mon.to_moonbit_source(value, name="config"),
    (
      #|let config = Config::{
      #|  name: "mon",
      #|  protocol: Protocol::Https,
      #|}
    ),
  )
}

///|
test "generates MoonBit source for maps, lists, and scalars" {
  let value = @mon.parse("[{ \"cpu\": 4 }, Some(1), b\"\\x0f\"]")
  assert_eq(
    @mon.to_moonbit_source(value),
    (
      #|let value = [
      #|  {
      #|    "cpu": 4,
      #|  },
      #|  Some(
      #|    1,
      #|  ),
      #|  b"\x0f",
      #|]
    ),
  )
}

///|
test "refuses ranges in generated source" {
  let value = @mon.parse("Config { window: 1..10 }")
  try {
    @mon.to_moonbit_source(value) |> ignore
    fail("expected a refusal")
  } catch {
    @mon.UnrepresentableValue(_) => ()
    _ => fail("expected UnrepresentableValue")
  }
}

///|
test "refuses a binding name that is not a name" {
  try {
    @mon.to_moonbit_source(@mon.MonValue::Unit, name="Upper") |> ignore
    fail("expected a refusal")
  } catch {
    @mon.InvalidName(name) => assert_eq(name, "Upper")
    _ => fail("expected InvalidName")
  }
}
