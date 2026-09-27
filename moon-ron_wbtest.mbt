///|
test "splits enum paths" {
  assert_eq(split_path("Color::Rgb"), Some(("Color", "Rgb")))
  assert_eq(split_path("Color"), None)
}
