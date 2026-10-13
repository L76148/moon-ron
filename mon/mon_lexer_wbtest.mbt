///|
/// Token labels for one document, which is easier to read than the tokens.
fn labels(source : StringView) -> Array[String] raise MonError {
  tokenize(source).map(fn(info : MonTokenInfo) { token_label(info.token) })
}

///|
test "labels every token" {
  assert_eq(labels("Point { x: 1 }"), [
    "the name `Point`", "`{`", "the name `x`", "`:`", "a number", "`}`", "the end of the document",
  ])
  assert_eq(labels("b'x' b\"y\" true false None"), [
    "a byte", "a byte string", "a boolean", "a boolean", "the name `None`", "the end of the document",
  ])
}

///|
test "lexes qualified names" {
  assert_eq(labels("Color::Red"), [
    "the name `Color::Red`", "the end of the document",
  ])
}

///|
test "lexes a multiline string as one token" {
  assert_eq(
    tokenize("#|a\n#|b\n").map(fn(info : MonTokenInfo) {
      match info.token {
        String(value) => value
        _ => "?"
      }
    }),
    ["a\nb", "?"],
  )
}

///|
test "reports the position of the token" {
  let tokens = tokenize("[\n  1,\n]")
  assert_eq(tokens.length(), 5)
  assert_eq(tokens[1].position.line, 2)
  assert_eq(tokens[1].position.column, 2)
  assert_eq(tokens[3].position.line, 3)
}

///|
test "rejects text MoonBit rejects" {
  let invalid = ["'\\0'", "\"\\v\"", "1e10", "1Lx", "'\\x41'", "/* x */"]
  for source in invalid {
    assert_true(
      try {
        tokenize(source) |> ignore
        false
      } catch {
        _ => true
      },
    )
  }
}
