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
moon run cmd/mon -- compact <file>
moon run cmd/mon -- format <file>
moon run cmd/mon -- expand <file>
moon run cmd/mon -- gen <file> [name [type]]
moon run cmd/mon -- version
```

`check` parses the document and reports its shape (`ok: path -> record Config
with 14 fields`). `compact` and `format` print the canonical compact form and
the multiline form. `expand` resolves `#include` and `#env` against the
directory of the given file and the process environment. `gen` prints the
MoonBit binding that holds the document, which is how a `.mon` file is inlined
into a program.

Invalid documents produce a nonzero exit status and a diagnostic on standard
error, with the source line, column, and caret. `docs/MON.md` describes the
directives and the generated source, and the RON conversion commands arrive in
the last increment of `docs/ROADMAP.md`.
