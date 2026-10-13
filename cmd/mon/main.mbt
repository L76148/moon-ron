///|
priv suberror CliError {
  Io(String)
  Parse(@moonmon.MonError, String)
  Preprocess(@moonmon.MonPreprocessError, String)
  Write(@moonmon.MonWriteError)
  RonParse(@ron.RonError, String)
  Convert(@mon_ron.MonConvertError)
  Usage(String)
}

///|
fn CliError::to_string(self : CliError) -> String {
  match self {
    Io(message) => "io error: " + message
    Parse(error, source) => @moonmon.render_error(source, error)
    Preprocess(error, source) => @moonmon.render_preprocess_error(source, error)
    Write(error) => @moonmon.render_write_error(error)
    RonParse(error, source) => @ron.render_error(source, error)
    Convert(error) => "error: " + @mon_ron.MonConvertError::message(error)
    Usage(message) => "usage error: " + message
  }
}

///|
fn usage() -> String {
  (
    #|Usage:
    #|  mon check <file>        parse a MON document and report its shape
    #|  mon compact <file>      print the document in canonical compact form
    #|  mon format <file>       print the document with multiline formatting
    #|  mon expand <file>       print the document with its directives expanded
    #|  mon gen <file> [name [type]]
    #|                          print MoonBit source that holds the document
    #|  mon to-ron <file>       convert the document to RON
    #|  mon from-ron <file>     convert a RON document to MON
    #|  mon version             print the module version
  )
}

///|
/// Convert a MON document into RON, with its directives expanded first.
fn to_ron_source(path : String, source : StringView) -> String raise CliError {
  let expanded = expand_source(path, source)
  let value = @moonmon.parse(expanded) catch {
    error => raise Parse(error, expanded)
  }
  let converted = @mon_ron.to_ron(value) catch { error => raise Convert(error) }
  @ron.to_string(converted)
}

///|
/// Convert a RON document into MON.
fn from_ron_source(source : StringView) -> String raise CliError {
  let value = @ron.parse(source) catch {
    error => raise RonParse(error, source.to_owned())
  }
  let converted = @mon_ron.from_ron(value) catch {
    error => raise Convert(error)
  }
  @moonmon.to_string(converted) catch {
    error => raise Write(error)
  }
}

///|
/// Read a file, or `None` when it cannot be read.
fn read_file(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    @fs.IOError(_) => None
  }
}

///|
/// Read a document, reporting a failed read as a CLI error.
fn read_document(path : String) -> String raise CliError {
  match read_file(path) {
    Some(text) => text
    None => raise Io("cannot read " + path)
  }
}

///|
/// The directory part of a path, used to resolve `#include` paths.
fn base_directory(path : String) -> String {
  let mut end = -1
  for i = 0; i < path.length(); i = i + 1 {
    match path.get_char(i) {
      Some(char) => if char == '/' || char == '\\' { end = i }
      None => ()
    }
  }
  if end < 0 {
    ""
  } else {
    path.unsafe_substring(start=0, end=end + 1)
  }
}

///|
/// Resolve an include path against the directory of the root document.
fn resolve_path(base : String, path : String) -> String {
  match path.get_char(0) {
    Some('/') | Some('\\') => path
    _ =>
      match path.get_char(1) {
        Some(':') => path
        _ => base + path
      }
  }
}

///|
/// The variables and documents of the running environment.
fn environment_for(path : String) -> @moonmon.MonEnvironment {
  let base = base_directory(path)
  {
    lookup: fn(name) { @env.get_env_var(name.to_owned()) },
    read: fn(target) { read_file(resolve_path(base, target.to_owned())) },
  }
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
fn expand_source(path : String, source : StringView) -> String raise CliError {
  @moonmon.preprocess(source, environment=environment_for(path)) catch {
    error => raise Preprocess(error, source.to_owned())
  }
}

///|
/// Print MoonBit source for a document, with its directives expanded first.
fn generate_source(
  path : String,
  source : StringView,
  name : String,
  type_name : String,
) -> String raise CliError {
  let expanded = expand_source(path, source)
  let value = @moonmon.parse(expanded) catch {
    error => raise Parse(error, expanded)
  }
  @moonmon.to_moonbit_source(value, name~, type_name~) catch {
    error => raise Write(error)
  }
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
    ["check", path] => println(parse_source(path, read_document(path)))
    ["compact", path] => println(compact_source(read_document(path)))
    ["format", path] => println(format_source(read_document(path)))
    ["expand", path] => println(expand_source(path, read_document(path)))
    ["gen", path] =>
      println(generate_source(path, read_document(path), "value", ""))
    ["gen", path, name] =>
      println(generate_source(path, read_document(path), name, ""))
    ["gen", path, name, type_name] =>
      println(generate_source(path, read_document(path), name, type_name))
    ["to-ron", path] => println(to_ron_source(path, read_document(path)))
    ["from-ron", path] => println(from_ron_source(read_document(path)))
    _ => raise Usage("expected a command and one file, and a name for `gen`")
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
