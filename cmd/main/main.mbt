///|
fn main raise {
  let value = @ron.parse("Point(x: 1, y: 2, tags: [\"parser\", \"ron\"])")
  println(value.to_repr())
}
