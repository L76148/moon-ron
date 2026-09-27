///|
test "splits enum paths" {
  assert_eq(split_path("Color::Rgb"), Some(("Color", "Rgb")))
  assert_eq(split_path("Color"), None)
}

///|
test "detects type names" {
  assert_true(is_type_name("Color"))
  assert_false(is_type_name("color"))
  assert_false(is_type_name(""))
}
