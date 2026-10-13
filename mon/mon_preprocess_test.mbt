///|
/// An environment built from two tables, which keeps the tests away from the
/// filesystem and the process environment.
fn environment(
  variables : Array[(String, String)],
  documents : Array[(String, String)],
) -> @mon.MonEnvironment {
  {
    lookup: fn(name) {
      let text = name.to_owned()
      for entry in variables {
        let (key, value) = entry
        if key == text {
          return Some(value)
        }
      }
      None
    },
    read: fn(path) {
      let text = path.to_owned()
      for entry in documents {
        let (key, value) = entry
        if key == text {
          return Some(value)
        }
      }
      None
    },
  }
}

///|
test "expands environment variables" {
  let source =
    #|Config { port: #env "PORT" (8080), name: #env "NAME" ("mon") }
  assert_eq(
    @mon.preprocess(source, environment=environment([("PORT", "9090")], [])),
    "Config { port: 9090, name: (\"mon\") }",
  )
  let value = @mon.parse(
    @mon.preprocess(source, environment=environment([], [])),
  )
  assert_eq(
    value.field("port"),
    Some(@mon.MonValue::Number(@mon.MonNumber::Int(8080))),
  )
}

///|
test "reads a variable value as MON text" {
  let source = "#env \"PORTS\" ([1])"
  let expanded = @mon.preprocess(
    source,
    environment=environment([("PORTS", "[8080, 8081]")], []),
  )
  assert_eq(
    @mon.parse(expanded),
    @mon.MonValue::Sequence([
      @mon.MonValue::Number(@mon.MonNumber::Int(8080)),
      @mon.MonValue::Number(@mon.MonNumber::Int(8081)),
    ]),
  )
}

///|
test "expands includes" {
  let documents = [("shared.mon", "Service { name: \"api\" },")]
  let expanded = @mon.preprocess(
    "[#include \"shared.mon\"]",
    environment=environment([], documents),
  )
  assert_eq(expanded, "[Service { name: \"api\" },]")
  assert_true(@mon.valid(expanded))
}

///|
test "expands nested includes" {
  let documents = [
    ("outer.mon", "[#include \"middle.mon\"]"),
    ("middle.mon", "#include \"inner.mon\""),
    ("inner.mon", "42"),
  ]
  assert_eq(
    @mon.preprocess(
      "#include \"outer.mon\"",
      environment=environment([], documents),
    ),
    "[42]",
  )
}

///|
test "reports include problems" {
  try {
    @mon.preprocess("#include \"missing.mon\"", environment=environment([], []))
    |> ignore
    fail("expected a missing include")
  } catch {
    @mon.IncludeNotFound(_, path) => assert_eq(path, "missing.mon")
    _ => fail("expected IncludeNotFound")
  }
  try {
    @mon.preprocess(
      "#include \"loop.mon\"",
      environment=environment([], [("loop.mon", "#include \"loop.mon\"")]),
    )
    |> ignore
    fail("expected a cycle")
  } catch {
    @mon.IncludeCycle(_, path) => assert_eq(path, "loop.mon")
    _ => fail("expected IncludeCycle")
  }
  try {
    @mon.preprocess(
      "#include \"outer.mon\"",
      environment=environment([], [
        ("outer.mon", "#include \"inner.mon\""),
        ("inner.mon", "1"),
      ]),
      max_include_depth=1,
    )
    |> ignore
    fail("expected a depth limit")
  } catch {
    @mon.IncludeDepthExceeded(_, limit) => assert_eq(limit, 1)
    _ => fail("expected IncludeDepthExceeded")
  }
}

///|
test "reports directive problems" {
  try {
    @mon.preprocess("#env \"UNSET\"", environment=environment([], [])) |> ignore
    fail("expected a missing variable")
  } catch {
    @mon.MissingVariable(_, name) => assert_eq(name, "UNSET")
    _ => fail("expected MissingVariable")
  }
  try {
    @mon.preprocess("#when \"FLAG\" (1)") |> ignore
    fail("expected an unknown directive")
  } catch {
    @mon.UnknownDirective(_, name) => assert_eq(name, "#when")
    _ => fail("expected UnknownDirective")
  }
  try {
    @mon.preprocess("#env PORT") |> ignore
    fail("expected a missing argument")
  } catch {
    @mon.MissingArgument(_, directive) => assert_eq(directive, "#env")
    _ => fail("expected MissingArgument")
  }
}

///|
/// Directives are text, but a document hides them in strings, comments, and
/// multiline strings often enough that the preprocessor has to leave those
/// alone.
test "leaves text that only looks like a directive alone" {
  let source =
    #|[
    #|  "#include \"a.mon\"",
    #|  '#',
    #|  // #env "PORT" (1)
    #|  (
    #|    #|#env "PORT" (1)
    #|  ),
    #|]
  assert_eq(@mon.preprocess(source), source)
  assert_true(@mon.valid(source))
}

///|
test "renders preprocessor errors" {
  let source = "[\n  #when (1),\n]"
  let error : @mon.MonPreprocessError = try {
    @mon.preprocess(source) |> ignore
    fail("expected a preprocessor error")
  } catch {
    @mon.UnknownDirective(_, _) as error => error
    _ => fail("expected UnknownDirective")
  }
  assert_eq(
    @mon.render_preprocess_error(source, error),
    (
      #|error: unknown directive `#when` at line 2, column 3
      #|  |
      #|2 |   #when (1),
      #|  |   ^
    ),
  )
}
