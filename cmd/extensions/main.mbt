///|
priv struct Config {
  count : Int?
}

///|
impl @ron.ToRon for Config with fn to_ron(self, options) {
  @ron.RonValue::Struct("Config", [
    ("count", @ron.ToRon::to_ron(self.count, options)),
  ])
}

///|
impl @ron.FromRon for Config with fn from_ron(value, path, options) {
  @ron.require_struct_name(value, "Config", path, options)
  let fields = @ron.struct_fields(value, path)
  { count: @ron.field(fields, "count", path, options), }
}

///|
fn main raise {
  let source =
    #|#![enable(implicit_some)]
    #|Config(
    #|  count: 5,
    #|)
  let document = @ron.parse_document(source)
  let options = @ron.RonOptions::default().with_extensions(document.extensions)
  let config : Config = @ron.from_value_with_options(document.value, options)
  println(@ron.encode_with_options(config, options~))
}
