# Source-aware diagnostics

Parser and typed decoding errors can be rendered against the original source:

```text
@ron.render_error(source, error)
@ron.render_decode_error(source, error)
```

Example output:

```text
error: unknown extension not_a_real_extension at line 1, column 11
  |
1 | #![enable(not_a_real_extension)]
  |           ^
```

Typed decoding errors include the logical RON path:

```text
error: expected Int, found string
  at $.y
```

The CLI automatically uses this renderer for file parse errors.
