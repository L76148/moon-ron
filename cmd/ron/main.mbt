///|
priv suberror CliError {
  Io(String)
  Parse(@moonron.RonError, String)
  Usage(String)
}

///|
fn CliError::to_string(self : CliError) -> String {
  match self {
    Io(message) => "io error: " + message
    Parse(error, source) => @moonron.render_error(source, error)
    Usage(message) => "usage error: " + message
  }
}

///|
fn parse_source(source : StringView) -> @moonron.RonDocument raise CliError {
  @moonron.parse_document(source) catch {
    error => raise Parse(error, source.to_owned())
  }
}

///|
fn with_header(document : @moonron.RonDocument, body : String) -> String {
  let attribute = document.extensions.to_attribute()
  if attribute.length() == 0 {
    body
  } else {
    attribute + "\n" + body
  }
}

///|
fn check_source(source : StringView) -> Unit raise CliError {
  parse_source(source) |> ignore
}

///|
fn format_source(source : StringView) -> String raise CliError {
  let document = parse_source(source)
  with_header(document, @moonron.to_string_pretty(document.value))
}

///|
fn compact_source(source : StringView) -> String raise CliError {
  let document = parse_source(source)
  with_header(document, @moonron.to_string(document.value))
}

///|
fn usage() -> String {
  (
    #|Usage:
    #|  ron check <file>
    #|  ron format <file>
    #|  ron compact <file>
  )
}

///|
fn run_command(args : Array[String]) -> Unit raise CliError {
  if args.length() == 0 || args[0] == "--help" || args[0] == "help" {
    println(usage())
    return
  }
  if args.length() != 2 {
    raise Usage("expected a command and one file path")
  }
  let command = args[0]
  let path = args[1]
  let source = @fs.read_file_to_string(path) catch {
    @fs.IOError(message) => raise Io(message)
  }
  match command {
    "check" => {
      check_source(source)
      println("ok: " + path)
    }
    "format" => println(format_source(source))
    "compact" => println(compact_source(source))
    _ => raise Usage("unknown command " + command)
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
  run_command(args) catch {
    error => {
      eprintln(error.to_string())
      @sys.exit(1)
    }
  }
}
