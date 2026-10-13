///|
/// Errors raised while expanding the directives of a MON document.
pub(all) suberror MonPreprocessError {
  /// The `#name` is not a directive.
  UnknownDirective(MonPosition, String)
  /// A directive is missing its quoted argument.
  MissingArgument(MonPosition, String)
  /// `#env` named a variable that is not set and gave no fallback.
  MissingVariable(MonPosition, String)
  /// `#include` named a document the environment cannot read.
  IncludeNotFound(MonPosition, String)
  /// A document includes itself, directly or through another document.
  IncludeCycle(MonPosition, String)
  /// Includes nest deeper than `max_include_depth`.
  IncludeDepthExceeded(MonPosition, Int32)
} derive(Eq, Debug)

///|
pub extend MonPreprocessError with Eq::{not_equal, equal}

///|
pub extend MonPreprocessError with @debug.Debug::{to_repr}

///|
/// The variables and documents a MON document asks for.
///
/// `lookup` answers `#env` and `read` answers `#include`. Both answer `None`
/// when the name is unknown, which is how the preprocessor reports a variable
/// that is not set and a document it cannot read.
pub(all) struct MonEnvironment {
  lookup : (StringView) -> String?
  read : (StringView) -> String?
}

///|
/// An environment with no variables and no documents.
pub fn MonEnvironment::default() -> MonEnvironment {
  { lookup: fn(_name) { None }, read: fn(_path) { None }, }
}

///|
/// Expand the directives of a MON document.
///
/// The result is a plain MON document with no directives left, so `parse`
/// reads it. Two directives are understood:
///
/// - `#include "path"` is replaced by the expanded text of that document.
///   The environment supplies the text, so the same document can be expanded
///   from a directory, from memory, or from a test fixture.
/// - `#env "NAME"` is replaced by the value of that variable, and
///   `#env "NAME" (fallback)` uses the parenthesised document instead when the
///   variable is not set. The value of a variable is MON text, so a document
///   can be configured from the environment without quoting tricks.
///
/// Directives are only recognised outside strings, characters, comments, and
/// `#|` multiline strings. `max_include_depth` bounds how deep `#include` may
/// nest.
pub fn preprocess(
  source : StringView,
  environment~ : MonEnvironment = MonEnvironment::default(),
  max_include_depth~ : Int32 = 16,
) -> String raise MonPreprocessError {
  let preprocessor : MonPreprocessor = {
    environment,
    max_include_depth,
    includes: [],
    chars: source.to_array(),
    offset: 0,
    line: 1,
    column: 0,
  }
  preprocessor.expand()
}

///|
priv struct MonPreprocessor {
  environment : MonEnvironment
  max_include_depth : Int32
  includes : Array[String]
  chars : Array[Char]
  mut offset : Int32
  mut line : Int32
  mut column : Int32
}

///|
fn MonPreprocessor::expand(
  self : MonPreprocessor,
) -> String raise MonPreprocessError {
  let output = StringBuilder()
  while true {
    match self.peek() {
      None => break
      Some('/') if self.peek_at(1) == Some('/') => self.copy_comment(output)
      Some('"') => self.copy_quoted(output, '"')
      Some('\'') => self.copy_quoted(output, '\'')
      Some('#') =>
        if self.peek_at(1) == Some('|') {
          self.copy_multiline(output)
        } else {
          self.expand_directive(output)
        }
      Some(char) => {
        output.write_char(char)
        self.advance() |> ignore
      }
    }
  }
  output.to_string()
}

///|
/// Expand one directive, which starts with `#` and a name.
fn MonPreprocessor::expand_directive(
  self : MonPreprocessor,
  output : StringBuilder,
) -> Unit raise MonPreprocessError {
  let position = self.position()
  self.advance() |> ignore
  let name = self.read_name()
  match name {
    "" => raise UnknownDirective(position, "#")
    "include" => self.expand_include(output, position)
    "env" => self.expand_variable(output, position)
    _ => raise UnknownDirective(position, "#" + name)
  }
}

///|
fn MonPreprocessor::expand_include(
  self : MonPreprocessor,
  output : StringBuilder,
  position : MonPosition,
) -> Unit raise MonPreprocessError {
  let path = self.read_argument(position, "#include")
  if self.includes.contains(path) {
    raise IncludeCycle(position, path)
  }
  if self.includes.length() >= self.max_include_depth {
    raise IncludeDepthExceeded(position, self.max_include_depth)
  }
  match (self.environment.read)(path) {
    None => raise IncludeNotFound(position, path)
    Some(source) => {
      let nested = self.nested(path, source)
      output.write_string(nested.expand())
    }
  }
}

///|
fn MonPreprocessor::expand_variable(
  self : MonPreprocessor,
  output : StringBuilder,
  position : MonPosition,
) -> Unit raise MonPreprocessError {
  let name = self.read_argument(position, "#env")
  let fallback = self.read_fallback()
  match (self.environment.lookup)(name) {
    Some(value) => output.write_string(value)
    None =>
      match fallback {
        Some(value) => output.write_string(value)
        None => raise MissingVariable(position, name)
      }
  }
}

///|
/// A preprocessor for an included document, which keeps the include stack.
fn MonPreprocessor::nested(
  self : MonPreprocessor,
  path : String,
  source : StringView,
) -> MonPreprocessor {
  let includes : Array[String] = []
  for i = 0; i < self.includes.length(); i = i + 1 {
    includes.push(self.includes[i])
  }
  includes.push(path)
  {
    environment: self.environment,
    max_include_depth: self.max_include_depth,
    includes,
    chars: source.to_array(),
    offset: 0,
    line: 1,
    column: 0,
  }
}

///|
fn MonPreprocessor::read_argument(
  self : MonPreprocessor,
  position : MonPosition,
  directive : String,
) -> String raise MonPreprocessError {
  self.skip_space()
  match self.peek() {
    Some('"') => {
      let buffer = StringBuilder()
      self.advance() |> ignore
      while true {
        match self.peek() {
          Some('"') => {
            self.advance() |> ignore
            break
          }
          Some('\n') | None => raise MissingArgument(position, directive)
          Some(char) => {
            buffer.write_char(char)
            self.advance() |> ignore
          }
        }
      }
      buffer.to_string()
    }
    _ => raise MissingArgument(position, directive)
  }
}

///|
/// Read the optional parenthesised fallback of `#env`.
fn MonPreprocessor::read_fallback(self : MonPreprocessor) -> String? {
  self.skip_space()
  if self.peek() != Some('(') {
    return None
  }
  let buffer = StringBuilder()
  let mut depth = 0
  while true {
    match self.peek() {
      None => break
      Some('"') => self.copy_quoted(buffer, '"')
      Some('\'') => self.copy_quoted(buffer, '\'')
      Some('/') if self.peek_at(1) == Some('/') => self.copy_comment(buffer)
      Some('#') if self.peek_at(1) == Some('|') => self.copy_multiline(buffer)
      Some(char) => {
        if char == '(' {
          depth = depth + 1
        }
        if char == ')' {
          depth = depth - 1
        }
        buffer.write_char(char)
        self.advance() |> ignore
        if depth == 0 {
          break
        }
      }
    }
  }
  Some(buffer.to_string())
}

///|
/// Copy a `//` comment, which never hides or contains a directive.
fn MonPreprocessor::copy_comment(
  self : MonPreprocessor,
  output : StringBuilder,
) -> Unit {
  while true {
    match self.peek() {
      Some('\n') | None => break
      Some(char) => {
        output.write_char(char)
        self.advance() |> ignore
      }
    }
  }
}

///|
/// Copy a string or character literal, including its quotes and escapes.
fn MonPreprocessor::copy_quoted(
  self : MonPreprocessor,
  output : StringBuilder,
  quote : Char,
) -> Unit {
  output.write_char(quote)
  self.advance() |> ignore
  while true {
    match self.peek() {
      None => break
      Some('\n') => break
      Some('\\') => {
        output.write_char('\\')
        self.advance() |> ignore
        match self.peek() {
          Some(char) => {
            output.write_char(char)
            self.advance() |> ignore
          }
          None => break
        }
      }
      Some(char) => {
        output.write_char(char)
        self.advance() |> ignore
        if char == quote {
          break
        }
      }
    }
  }
}

///|
/// Copy a `#|` multiline string, which is a run of lines starting with `#|`.
fn MonPreprocessor::copy_multiline(
  self : MonPreprocessor,
  output : StringBuilder,
) -> Unit {
  let mut first = true
  while true {
    if !first {
      output.write_char('\n')
    }
    first = false
    output.write_string("#|")
    self.advance() |> ignore
    self.advance() |> ignore
    while true {
      match self.peek() {
        Some('\n') | None => break
        Some(char) => {
          output.write_char(char)
          self.advance() |> ignore
        }
      }
    }
    let saved = self.save()
    match self.peek() {
      Some('\n') => {
        self.advance() |> ignore
        self.skip_space()
        if self.peek() == Some('#') && self.peek_at(1) == Some('|') {
          continue
        }
        self.restore(saved)
        break
      }
      _ => break
    }
  }
}

///|
fn MonPreprocessor::read_name(self : MonPreprocessor) -> String {
  let buffer = StringBuilder()
  while true {
    match self.peek() {
      Some(char) if is_name_continue(char) => {
        buffer.write_char(char)
        self.advance() |> ignore
      }
      _ => break
    }
  }
  buffer.to_string()
}

///|
fn MonPreprocessor::skip_space(self : MonPreprocessor) -> Unit {
  while self.peek() == Some(' ') || self.peek() == Some('\t') {
    self.advance() |> ignore
  }
}

///|
fn MonPreprocessor::position(self : MonPreprocessor) -> MonPosition {
  { index: self.offset, line: self.line, column: self.column, }
}

///|
fn MonPreprocessor::peek(self : MonPreprocessor) -> Char? {
  self.chars.get(self.offset)
}

///|
fn MonPreprocessor::peek_at(self : MonPreprocessor, distance : Int32) -> Char? {
  self.chars.get(self.offset + distance)
}

///|
fn MonPreprocessor::advance(self : MonPreprocessor) -> Char? {
  match self.chars.get(self.offset) {
    Some(char) => {
      self.offset = self.offset + 1
      if char == '\n' {
        self.line = self.line + 1
        self.column = 0
      } else {
        self.column = self.column + 1
      }
      Some(char)
    }
    None => None
  }
}

///|
fn MonPreprocessor::save(self : MonPreprocessor) -> (Int32, Int32, Int32) {
  (self.offset, self.line, self.column)
}

///|
fn MonPreprocessor::restore(
  self : MonPreprocessor,
  state : (Int32, Int32, Int32),
) -> Unit {
  let (offset, line, column) = state
  self.offset = offset
  self.line = line
  self.column = column
}
