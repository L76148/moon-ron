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
