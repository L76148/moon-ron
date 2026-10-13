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
error. Diagnostics include the source line and caret position.

The CLI uses `moonbitlang/x/fs`; the library packages themselves do not
depend on filesystem access.

## MON CLI

`cmd/mon` reads MON documents, the notation written in MoonBit literal
syntax:

```text
moon run cmd/mon -- check <file>
moon run cmd/mon -- version
```

`check` parses the document and reports its shape (`ok: path -> record Config
with 14 fields`). Invalid documents produce a nonzero exit status and a
diagnostic on standard error, with the source line, column, and caret.
The writer, the preprocessor, and the RON conversion commands arrive in later
increments; see `docs/ROADMAP.md`.
