///|
/// Emit a MoonBit binding whose value is the given MON value.
///
/// The text is MoonBit source, so a document can be inlined into a program
/// instead of being parsed at run time:
///
/// ```text
/// let config = Config::{
///   name: "api",
///   ports: [8080],
/// };
/// ```
///
/// `Name { field: value }` becomes the `Name::{ field: value }` form MoonBit
/// requires, and a range is refused because MoonBit has no range expression
/// outside a `for` loop.
///
/// MoonBit asks for a type annotation on a binding that stands at the top of a
/// file, so `type_name` is emitted between the name and the value when it is
/// given.
pub fn to_moonbit_source(
  value : MonValue,
  name~ : String = "value",
  type_name~ : String = "",
) -> String raise MonWriteError {
  if !valid_field_name(name) {
    raise InvalidName(name)
  }
  if type_name.contains("\n") || type_name.contains("\r") {
    raise InvalidName(type_name)
  }
  let writer = MonWriter::{
    buffer: StringBuilder(),
    indent: 2,
    pretty: true,
    moonbit: true,
  }
  writer.write(value, 0)
  let declared = if type_name.length() > 0 { " : " + type_name } else { "" }
  "let " + name + declared + " = " + writer.text()
}
