# Non-overlap evidence

Checked on 2026-09-28 with the current MoonBit registry:

```text
moon search ron --limit 20
```

The only matches were unrelated packages containing the letters `ron` in a
package name (`Ronlands/ttf_parser_moonbit` and
`Ronlands/moonbit_zstd`). No RON parser, serializer, or typed converter was
returned.

The existing MoonBit data-format ecosystem covers JSON, TOML, YAML, KDL, and
HCL. RON is a separate syntax and data model with Rust-oriented structs,
tuple structs, enum variants, options, and byte literals, so this project does
not duplicate those packages.

## MON

Checked on 2026-10-13:

```text
moon search mon --limit 30
moon search "object notation" --limit 20
moon search "data format" --limit 20
moon search literal --limit 20
```

The results cover MongoDB drivers, Monte Carlo simulation, Vue-style UI
frameworks, and the established formats (JSON, TOML, YAML, KDL, HCL, Amazon
Ion, NestedText, Gherkin). `marianoguerra/shrubbery` parses Racket's shrubbery
notation, and `marianoguerra/tutuca` ships a value language inside its Vue
framework port; neither reads a MoonBit literal expression, and neither
handles `#|` multiline strings, `b"\x41"` byte strings, or `1L`/`1UL` sized
integers. No published package reads a MoonBit literal document as data.
