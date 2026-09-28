///|
test "renders parser errors with a caret" {
  let source = "[1,\n@]"
  let error : @moon-ron.RonError = try {
    @moon-ron.parse(source) |> ignore
    fail("expected parse error")
  } catch {
    @moon-ron.UnexpectedChar(_, _) as error => error
    _ => fail("expected UnexpectedChar")
  }
  assert_eq(
    @moon-ron.render_error(source, error),
    (
      #|error: unexpected character '@' at line 2, column 1
      #|  |
      #|2 | @]
      #|  | ^
    ),
  )
}

///|
test "renders end of input errors" {
  let source = "\"abc"
  let error : @moon-ron.RonError = try {
    @moon-ron.parse(source) |> ignore
    fail("expected parse error")
  } catch {
    @moon-ron.UnexpectedEof(_) as error => error
    _ => fail("expected UnexpectedEof")
  }
  assert_eq(
    @moon-ron.render_error(source, error),
    (
      #|error: unexpected end of input at line 1, column 5
      #|  |
      #|1 | "abc
      #|  |     ^
    ),
  )
}

///|
test "renders typed errors with paths" {
  let error : @moon-ron.RonDecodeError = try {
    let _ : Int = @moon-ron.decode("\"value\"")
    fail("expected decode error")
  } catch {
    @moon-ron.TypeMismatch(_, _, _) as error => error
    _ => fail("expected TypeMismatch")
  }
  assert_eq(
    @moon-ron.render_decode_error("\"value\"", error),
    (
      #|error: expected Int, found string
      #|  at $
    ),
  )
}

///|
test "renders typed syntax errors through the parser renderer" {
  let error : @moon-ron.RonDecodeError = try {
    let _ : Int = @moon-ron.decode("[1,")
    fail("expected decode error")
  } catch {
    @moon-ron.Syntax(_) as error => error
    _ => fail("expected Syntax")
  }
  let rendered = @moon-ron.render_decode_error("[1,", error)
  assert_true(rendered.contains("unexpected end of input"))
  assert_true(rendered.contains("^"))
}
