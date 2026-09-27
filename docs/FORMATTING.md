# Structured RON formatting

`to_string_pretty` renders a `RonValue` as deterministic multiline RON.

```text
@ron.to_string_pretty(value, indent=2)
```

The formatter:

- expands non-empty sequences, tuples, maps, structs, and enums
- writes one item or field per line
- uses trailing commas, so every emitted document remains parseable
- keeps empty containers compact
- treats negative indentation as zero
- emits no trailing newline

Example:

```text
Point(
  x: 1,
  y: 2,
  tags: [
    "parser",
    "ron",
  ],
)
```
