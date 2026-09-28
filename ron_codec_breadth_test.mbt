///|
test "converts Int16 and UInt16" {
  let signed : Int16 = @moon-ron.decode("-123")
  assert_eq(signed, Int16::from_int(-123))
  assert_eq(@moon-ron.encode(signed), "-123")

  let unsigned : UInt16 = @moon-ron.decode("65535")
  assert_eq(unsigned, (65535 : Int).to_uint16())
  assert_eq(@moon-ron.encode(unsigned), "65535")

  try {
    let _ : UInt16 = @moon-ron.decode("65536")
    fail("expected an overflow")
  } catch {
    _ => ()
  }
}

///|
test "converts fixed arrays and array views" {
  let fixed : FixedArray[Int] = @moon-ron.decode("[1, 2, 3]")
  assert_eq(fixed, FixedArray::from_array([1, 2, 3]))
  assert_eq(@moon-ron.encode(fixed), "[1, 2, 3]")

  let view = fixed[:]
  assert_eq(@moon-ron.encode(view), "[1, 2, 3]")
}

///|
test "converts Result values" {
  let ok : Result[Int, String] = Ok(42)
  assert_eq(@moon-ron.encode(ok), "Ok(42)")
  let decoded_ok : Result[Int, String] = @moon-ron.decode("Ok(42)")
  assert_eq(decoded_ok, Ok(42))

  let error : Result[Int, String] = Err("bad")
  assert_eq(@moon-ron.encode(error), "Err(\"bad\")")
  let decoded_error : Result[Int, String] = @moon-ron.decode("Err(\"bad\")")
  assert_eq(decoded_error, Err("bad"))
}

///|
test "converts tuples up to eight values" {
  let tuple4 : (Int, Int, Int, Int) = @moon-ron.decode("(1, 2, 3, 4)")
  assert_eq(tuple4, (1, 2, 3, 4))
  let tuple5 : (Int, Int, Int, Int, Int) = @moon-ron.decode("(1, 2, 3, 4, 5)")
  assert_eq(tuple5, (1, 2, 3, 4, 5))
  let tuple6 : (Int, Int, Int, Int, Int, Int) = @moon-ron.decode(
    "(1, 2, 3, 4, 5, 6)",
  )
  assert_eq(tuple6, (1, 2, 3, 4, 5, 6))
  let tuple7 : (Int, Int, Int, Int, Int, Int, Int) = @moon-ron.decode(
    "(1, 2, 3, 4, 5, 6, 7)",
  )
  assert_eq(tuple7, (1, 2, 3, 4, 5, 6, 7))
  let tuple8 : (Int, Int, Int, Int, Int, Int, Int, Int) = @moon-ron.decode(
    "(1, 2, 3, 4, 5, 6, 7, 8)",
  )
  assert_eq(tuple8, (1, 2, 3, 4, 5, 6, 7, 8))
}
