///|
priv struct Point {
  x : Int
  y : Int
}

///|
impl @ron.ToRon for Point with fn to_ron(self, options) {
  @ron.RonValue::Struct("Point", [
    ("x", @ron.ToRon::to_ron(self.x, options)),
    ("y", @ron.ToRon::to_ron(self.y, options)),
  ])
}

///|
impl @ron.FromRon for Point with fn from_ron(value, path, options) {
  @ron.require_struct_name(value, "Point", path, options)
  let fields = @ron.struct_fields(value, path)
  {
    x: @ron.field(fields, "x", path, options),
    y: @ron.field(fields, "y", path, options),
  }
}

///|
fn main raise {
  let point : Point = { x: 1, y: 2, }
  let source = @ron.encode(point)
  println(source)
  let decoded : Point = @ron.decode(source)
  println("x = " + decoded.x.to_string())
  println("y = " + decoded.y.to_string())
}
