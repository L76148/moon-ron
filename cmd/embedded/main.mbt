///|
/// The type the inlined document has. `generated.mbt` holds what
/// `moon run cmd/mon -- gen corpus/mon/embedded.mon config Config` prints,
/// formatted by `moon fmt`; CI regenerates it and fails when the two differ.
struct Point {
  x : Int32
  y : Int32
}

///|
struct Config {
  name : String
  version : String
  ports : Array[Int32]
  limits : Map[String, UInt32]
  owner : Point?
  banner : String
  mask : Bytes
  total : Int64
  locked : Bool
}

///|
fn main {
  let owner = match config.owner {
    Some(point) => point.x.to_string() + "," + point.y.to_string()
    None => "none"
  }
  println(
    config.name +
    " " +
    config.version +
    " listens on " +
    config.ports.length().to_string() +
    " ports with " +
    config.limits.length().to_string() +
    " limits, owner " +
    owner +
    ", banner length " +
    config.banner.length().to_string() +
    ", mask length " +
    config.mask.length().to_string() +
    ", total " +
    config.total.to_string() +
    ", locked " +
    config.locked.to_string(),
  )
}
