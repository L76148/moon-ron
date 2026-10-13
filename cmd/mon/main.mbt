///|
priv suberror CliError {
  Io(String)
  Parse(@moonmon.MonError, String)
  Write(@moonmon.MonWriteError)
  Usage(String)
}

///|
fn CliError::to_string(self : CliError) -> String {
  match self {
    Io(message) => "io error: " + message
    Parse(error, source) => @moonmon.render_error(source, error)
    Write(error) => @moonmon.render_write_error(error)
    Usage(message) => "usage error: " + message
  }
}

///|
fn usage() -> String {
  (
    #|Usage:
    #|  mon check <file>     parse a MON document and report its shape
    #|  mon compact <file>   print the document in canonical compact form
    #|  mon format <file>    print the document with multiline formatting
    #|  mon version          print the module version
  )
}

///|
/// Parse one document and describe the value it holds.
fn parse_source(path : String, source : StringView) -> String raise CliError {
  let value = @moonmon.parse(source) catch {
    error => raise Parse(error, source.to_owned())
  }
  "ok: " + path + " -> " + describe(value)
}

///|
fn compact_source(source : StringView) -> String raise CliError {
  let value = @moonmon.parse(source) catch {
    error => raise Parse(error, source.to_owned())
  }
  @moonmon.to_string(value) catch {
    error => raise Write(error)
  }
}

///|
fn format_source(source : StringView) -> String raise CliError {
  let value = @moonmon.parse(source) catch {
    error => raise Parse(error, source.to_owned())
  }
  @moonmon.to_string_pretty(value) catch {
    error => raise Write(error)
  }
}

///|
fn describe(value : @moonmon.MonValue) -> String {
  match value {
    Sequence(values) => "sequence of " + values.length().to_string()
    Tuple(values) => "tuple of " + values.length().to_string()
    Map(entries) => "map of " + entries.length().to_string()
    Fields(fields) => "fields of " + fields.length().to_string()
    Record(name, fields) =>
      "record " + name + " with " + fields.length().to_string() + " fields"
    TupleVariant(name, values) =>
      "variant " + name + " with " + values.length().to_string() + " arguments"
    Variant(name) => "variant " + name
    Range(_) => "range"
    _ => value.kind()
  }
}

///|
fn run(args : Array[String]) -> Unit raise CliError {
  match args {
    [] => println(usage())
    ["--help"] | ["help"] => println(usage())
    ["version"] => println("moon-mon 0.1.0")
    ["check", path] => {
      let source = @fs.read_file_to_string(path) catch {
        @fs.IOError(message) => raise Io(message)
      }
      println(parse_source(path, source))
    }
    ["compact", path] => {
      let source = @fs.read_file_to_string(path) catch {
        @fs.IOError(message) => raise Io(message)
      }
      println(compact_source(source))
    }
    ["format", path] => {
      let source = @fs.read_file_to_string(path) catch {
        @fs.IOError(message) => raise Io(message)
      }
      println(format_source(source))
    }
    _ => raise Usage("expected `check`, `compact`, or `format` with one file")
  }
}

///|
fn main {
  let raw_args = @env.args()
  let args : Array[String] = if raw_args.length() == 0 {
    []
  } else {
    raw_args[1:].to_owned()
  }
  run(args) catch {
    error => {
      eprintln(error.to_string())
      @sys.exit(1)
    }
  }
}
