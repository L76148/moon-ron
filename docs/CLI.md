# RON CLI

The `cmd/ron` executable provides three file-oriented commands:

```text
moon run cmd/ron -- check <file>
moon run cmd/ron -- format <file>
moon run cmd/ron -- compact <file>
```

- `check` parses the file and reports whether it is valid.
- `format` emits deterministic multiline RON to standard output.
- `compact` emits canonical compact RON to standard output.

Document extension attributes are preserved by `format` and `compact`.
Invalid files produce a nonzero exit status and a diagnostic on standard
error.

The CLI uses `moonbitlang/x/fs`; the library packages themselves do not
depend on filesystem access.
