///|
/// Optional RON behavior enabled by a document attribute or caller options.
pub(all) struct RonExtensions {
  unwrap_newtypes : Bool
  implicit_some : Bool
  unwrap_variant_newtypes : Bool
  explicit_struct_names : Bool
} derive(Eq, Debug)

///|
pub fn RonExtensions::empty() -> RonExtensions {
  {
    unwrap_newtypes: false,
    implicit_some: false,
    unwrap_variant_newtypes: false,
    explicit_struct_names: false,
  }
}

///|
pub fn RonExtensions::add(
  self : RonExtensions,
  other : RonExtensions,
) -> RonExtensions {
  {
    unwrap_newtypes: self.unwrap_newtypes || other.unwrap_newtypes,
    implicit_some: self.implicit_some || other.implicit_some,
    unwrap_variant_newtypes: self.unwrap_variant_newtypes ||
    other.unwrap_variant_newtypes,
    explicit_struct_names: self.explicit_struct_names ||
    other.explicit_struct_names,
  }
}

///|
pub fn RonExtensions::is_empty(self : RonExtensions) -> Bool {
  !self.unwrap_newtypes &&
  !self.implicit_some &&
  !self.unwrap_variant_newtypes &&
  !self.explicit_struct_names
}

///|
pub fn RonExtensions::from_name(name : String) -> RonExtensions? {
  match name {
    "unwrap_newtypes" =>
      Some({ ..RonExtensions::empty(), unwrap_newtypes: true, })
    "implicit_some" => Some({ ..RonExtensions::empty(), implicit_some: true, })
    "unwrap_variant_newtypes" =>
      Some({ ..RonExtensions::empty(), unwrap_variant_newtypes: true, })
    "explicit_struct_names" =>
      Some({ ..RonExtensions::empty(), explicit_struct_names: true, })
    _ => None
  }
}

///|
pub fn RonExtensions::to_attribute(self : RonExtensions) -> String {
  if self.is_empty() {
    return ""
  }
  let names = []
  if self.unwrap_newtypes {
    names.push("unwrap_newtypes")
  }
  if self.implicit_some {
    names.push("implicit_some")
  }
  if self.unwrap_variant_newtypes {
    names.push("unwrap_variant_newtypes")
  }
  if self.explicit_struct_names {
    names.push("explicit_struct_names")
  }
  "#![enable(" + names.join(", ") + ")]"
}

///|
/// Parsing options and document-level extension defaults.
pub(all) struct RonOptions {
  extensions : RonExtensions
  max_nesting_depth : Int
} derive(Eq, Debug)

///|
pub fn RonOptions::default() -> RonOptions {
  { extensions: RonExtensions::empty(), max_nesting_depth: 128, }
}

///|
pub fn RonOptions::with_extension(
  self : RonOptions,
  extension : RonExtensions,
) -> RonOptions {
  {
    extensions: self.extensions.add(extension),
    max_nesting_depth: self.max_nesting_depth,
  }
}

///|
pub fn RonOptions::with_extensions(
  self : RonOptions,
  extensions : RonExtensions,
) -> RonOptions {
  self.with_extension(extensions)
}

///|
pub fn RonOptions::with_max_nesting_depth(
  self : RonOptions,
  max_nesting_depth : Int,
) -> RonOptions {
  { extensions: self.extensions, max_nesting_depth, }
}

///|
/// A parsed RON value together with the extensions enabled by its attributes.
pub(all) struct RonDocument {
  value : RonValue
  extensions : RonExtensions
} derive(Eq, Debug)

///|
fn RonParser::parse_attributes(
  self : RonParser,
  initial : RonExtensions,
) -> RonExtensions raise RonError {
  let mut extensions = initial
  self.skip_trivia()
  while self.peek() == Some('#') {
    let attribute_position = self.position()
    self.expect('#')
    self.expect('!')
    self.expect('[')
    self.skip_trivia()
    let name = self.parse_identifier()
    self.skip_trivia()
    match name {
      "enable" => extensions = self.parse_enable_attribute(extensions)
      "type" | "schema" => self.parse_ignored_attribute(name)
      _ => raise UnknownAttribute(attribute_position, name)
    }
    self.expect(']')
    self.skip_trivia()
  }
  extensions
}

///|
fn RonParser::parse_enable_attribute(
  self : RonParser,
  initial : RonExtensions,
) -> RonExtensions raise RonError {
  let mut extensions = initial
  self.expect('(')
  self.skip_trivia()
  if self.peek() == Some(')') {
    self.offset = self.offset + 1
    return extensions
  }
  while true {
    let position = self.position()
    let name = self.parse_identifier()
    match RonExtensions::from_name(name) {
      Some(extension) => extensions = extensions.add(extension)
      None => raise UnknownExtension(position, name)
    }
    self.skip_trivia()
    match self.peek() {
      Some(',') => {
        self.offset = self.offset + 1
        self.skip_trivia()
        if self.peek() == Some(')') {
          self.offset = self.offset + 1
          break
        }
      }
      Some(')') => {
        self.offset = self.offset + 1
        break
      }
      Some(char) => raise self.error_char(char)
      None => raise self.error_eof()
    }
  }
  extensions
}

///|
fn RonParser::parse_ignored_attribute(
  self : RonParser,
  name : String,
) -> Unit raise RonError {
  let position = self.position()
  self.expect('=')
  self.skip_trivia()
  match self.peek() {
    Some('"') => self.parse_string_literal() |> ignore
    Some(char) => raise self.error_char(char)
    None => raise self.error_eof()
  }
  if name.length() == 0 {
    raise InvalidAttribute(position, name)
  }
}
