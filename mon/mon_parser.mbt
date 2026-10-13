///|
priv struct MonParser {
  tokens : Array[MonTokenInfo]
  mut index : Int32
  max_nesting_depth : Int32
}

///|
fn MonParser::new(
  source : StringView,
  max_nesting_depth : Int32,
) -> MonParser raise MonError {
  { tokens: tokenize(source), index: 0, max_nesting_depth, }
}

///|
fn MonParser::current(self : MonParser) -> MonTokenInfo {
  self.tokens[self.index]
}

///|
fn MonParser::is_eof(self : MonParser) -> Bool {
  match self.current().token {
    Eof => true
    _ => false
  }
}

///|
fn MonParser::advance(self : MonParser) -> Unit {
  if !self.is_eof() {
    self.index = self.index + 1
  }
}

///|
/// Whether the current token can start a value.
///
/// The closing tokens and the range operator cannot, which is how open-ended
/// ranges such as `1..` stop.
fn MonParser::value_follows(self : MonParser) -> Bool {
  match self.current().token {
    Bool(_)
    | Number(_)
    | Char(_)
    | String(_)
    | Bytes(_)
    | Byte(_)
    | LBracket
    | LParen
    | LBrace
    | UpperName(_)
    | Path(_) => true
    _ => false
  }
}

///|
fn MonParser::expect(
  self : MonParser,
  expected : MonToken,
  description : String,
) -> Unit raise MonError {
  let matches = match (self.current().token, expected) {
    (LBrace, LBrace) | (RBrace, RBrace) => true
    (LParen, LParen) | (RParen, RParen) => true
    (LBracket, LBracket) | (RBracket, RBracket) => true
    (Colon, Colon) | (Comma, Comma) => true
    _ => false
  }
  if matches {
    self.advance()
  } else {
    raise Expected(
      self.current().position,
      description + ", found " + token_label(self.current().token),
    )
  }
}

///|
fn MonParser::parse_value(
  self : MonParser,
  depth : Int32,
) -> MonValue raise MonError {
  if depth > self.max_nesting_depth {
    raise DepthLimitExceeded(self.max_nesting_depth)
  }
  match self.current().token {
    DotDot | DotDotEq => self.parse_range(None, depth)
    _ => {
      let value = self.parse_atom(depth)
      match self.current().token {
        DotDot | DotDotEq => self.parse_range(Some(value), depth)
        _ => value
      }
    }
  }
}

///|
/// Finish a range whose start (when any) has already been parsed.
fn MonParser::parse_range(
  self : MonParser,
  start : MonValue?,
  depth : Int32,
) -> MonValue raise MonError {
  let inclusive = match self.current().token {
    DotDot => {
      self.advance()
      false
    }
    DotDotEq => {
      self.advance()
      true
    }
    _ => raise Expected(self.current().position, "`..` or `..=`")
  }
  let end = if self.value_follows() {
    Some(self.parse_atom(depth + 1))
  } else {
    None
  }
  MonValue::Range({ start, end, inclusive, })
}

///|
fn MonParser::parse_atom(
  self : MonParser,
  depth : Int32,
) -> MonValue raise MonError {
  let info = self.current()
  match info.token {
    Bool(value) => {
      self.advance()
      MonValue::Bool(value)
    }
    Number(value) => {
      self.advance()
      MonValue::Number(value)
    }
    Char(value) => {
      self.advance()
      MonValue::Char(value)
    }
    String(value) => {
      self.advance()
      MonValue::String(value)
    }
    Bytes(value) => {
      self.advance()
      MonValue::Bytes(value)
    }
    Byte(value) => {
      self.advance()
      MonValue::Byte(value)
    }
    LBracket => self.parse_sequence(depth)
    LParen => self.parse_parenthesized(depth)
    LBrace => self.parse_braces(depth)
    UpperName(name) | Path(name) => {
      self.advance()
      self.parse_constructor(name, depth)
    }
    LowerName(name) =>
      raise InvalidLiteral(
        info.position,
        "`" +
        name +
        "` is not a value: a MON document has no free variables, only uppercase constructor names",
      )
    Eof => raise UnexpectedEof(info.position)
    _ =>
      raise Expected(info.position, "a value, found " + token_label(info.token))
  }
}

///|
fn MonParser::parse_sequence(
  self : MonParser,
  depth : Int32,
) -> MonValue raise MonError {
  self.expect(LBracket, "`[`")
  let values = []
  let mut done = false
  while !done {
    match self.current().token {
      RBracket => done = true
      _ => {
        values.push(self.parse_value(depth + 1))
        match self.current().token {
          Comma => self.advance()
          _ => done = true
        }
      }
    }
  }
  self.expect(RBracket, "`]`")
  MonValue::Sequence(values)
}

///|
/// Parse `()`, `(value)`, or `(value, value, ...)`.
///
/// MoonBit has no one-element tuple, so `(1)` parses to the inner value while
/// `(1, 2)` parses to a tuple.
fn MonParser::parse_parenthesized(
  self : MonParser,
  depth : Int32,
) -> MonValue raise MonError {
  self.expect(LParen, "`(`")
  match self.current().token {
    RParen => {
      self.advance()
      MonValue::Unit
    }
    _ => {
      let first = self.parse_value(depth + 1)
      match self.current().token {
        RParen => {
          self.advance()
          first
        }
        Comma => {
          let values = [first]
          let mut done = false
          while !done {
            self.advance()
            match self.current().token {
              RParen => done = true
              _ => {
                values.push(self.parse_value(depth + 1))
                match self.current().token {
                  Comma => ()
                  _ => done = true
                }
              }
            }
          }
          self.expect(RParen, "`)`")
          MonValue::Tuple(values)
        }
        _ => raise Expected(self.current().position, "`)` or `,`")
      }
    }
  }
}

///|
/// Parse `{ "key": value }` or `{ field: value }`.
///
/// A bare lowercase name followed by `:` is a field, so `{ x: 1 }` parses to
/// `Fields` exactly like a MoonBit struct literal, and `{ "x": 1 }` parses to
/// a `Map` whose key is a string value.
fn MonParser::parse_braces(
  self : MonParser,
  depth : Int32,
) -> MonValue raise MonError {
  self.expect(LBrace, "`{`")
  match self.current().token {
    RBrace => {
      self.advance()
      MonValue::Map([])
    }
    LowerName(_) =>
      if self.field_follows() {
        MonValue::Fields(self.parse_fields(depth))
      } else {
        MonValue::Map(self.parse_map_entries(depth))
      }
    _ => MonValue::Map(self.parse_map_entries(depth))
  }
}

///|
/// Whether the upcoming tokens are `name:`.
fn MonParser::field_follows(self : MonParser) -> Bool {
  let next = self.tokens.get(self.index + 1)
  match (self.current().token, next) {
    (LowerName(_), Some(info)) =>
      match info.token {
        Colon => true
        _ => false
      }
    _ => false
  }
}

///|
fn MonParser::parse_fields(
  self : MonParser,
  depth : Int32,
) -> Array[(String, MonValue)] raise MonError {
  let fields = []
  let mut done = false
  while !done {
    match self.current().token {
      RBrace => done = true
      _ => {
        let name = match self.current().token {
          LowerName(name) => name
          _ => raise Expected(self.current().position, "a field name")
        }
        self.advance()
        self.expect(Colon, "`:`")
        let value = self.parse_value(depth + 1)
        fields.push((name, value))
        match self.current().token {
          Comma => self.advance()
          _ => done = true
        }
      }
    }
  }
  self.expect(RBrace, "`}`")
  fields
}

///|
fn MonParser::parse_map_entries(
  self : MonParser,
  depth : Int32,
) -> Array[(MonValue, MonValue)] raise MonError {
  let entries = []
  let mut done = false
  while !done {
    match self.current().token {
      RBrace => done = true
      _ => {
        let key = self.parse_value(depth + 1)
        self.expect(Colon, "`:`")
        let value = self.parse_value(depth + 1)
        entries.push((key, value))
        match self.current().token {
          Comma => self.advance()
          _ => done = true
        }
      }
    }
  }
  self.expect(RBrace, "`}`")
  entries
}

///|
/// Parse the tail of a constructor: a record, an argument list, or nothing.
fn MonParser::parse_constructor(
  self : MonParser,
  name : String,
  depth : Int32,
) -> MonValue raise MonError {
  match self.current().token {
    LBrace => {
      self.advance()
      MonValue::Record(name, self.parse_fields(depth))
    }
    LParen => {
      self.advance()
      MonValue::TupleVariant(name, self.parse_arguments(depth))
    }
    _ => MonValue::Variant(name)
  }
}

///|
fn MonParser::parse_arguments(
  self : MonParser,
  depth : Int32,
) -> Array[MonValue] raise MonError {
  let values = []
  let mut done = false
  while !done {
    match self.current().token {
      RParen => done = true
      _ => {
        values.push(self.parse_value(depth + 1))
        match self.current().token {
          Comma => self.advance()
          _ => done = true
        }
      }
    }
  }
  self.expect(RParen, "`)`")
  values
}
