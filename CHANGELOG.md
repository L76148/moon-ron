# Changelog

## Unreleased

### Added

- `mon` package: MON, a data notation written in MoonBit literal syntax, with
  a lexer, a parser, a dynamically typed `MonValue`, sized numbers, ranges,
  positioned diagnostics, and `render_error`
- `cmd/mon` CLI with `check <file>` and `version` commands
- MON fixtures under `corpus/mon`, plus `docs/MON.md` recording the literal
  mapping that was verified form by form against the MoonBit compiler
- MON writer: `to_string` for the canonical compact form and
  `to_string_pretty` for multiline output, both guaranteed to read back as an
  equal value, with `MonWriteError` for the shapes the grammar cannot spell
- `mon compact` and `mon format` commands in `cmd/mon`
- MON preprocessor: `preprocess` expands `#include "path"` and
  `#env "NAME" (fallback)` from an injected environment, with cycle, depth,
  missing-variable, and unreadable-document diagnostics, and leaves directives
  that only appear inside strings, comments, or `#|` strings alone
- `to_moonbit_source` writes a MoonBit binding for a document, so a `.mon` file
  can be inlined into a program; `cmd/embedded` builds and runs the generated
  source, and CI diffs it against the generator
- `mon expand` and `mon gen` commands in `cmd/mon`
- `mon_ron` package: `to_ron` and `from_ron` convert between the two notations,
  with `MonConvertError` for the shapes only one of them can spell, and
  `mon to-ron` and `mon from-ron` commands that pass documents between the two
  CLIs

### Changed

- Adopted the spelling of the current MoonBit release: `Int` is written
  `Int32`, and optional arguments use `name~` instead of `name?`. The compiler
  still accepts both spellings; `moon fmt` on release `0.1.20261012` rewrites
  the old ones, so the repository now matches what `moon fmt --check` expects
  on the release that CI installs.

## 0.1.1

### Added

Repository `main` is published at https://github.com/L76148/moon-ron and the
GitHub Actions CI workflow passes.

- Source-aware diagnostics with source lines and caret positions
- `render_error` and `render_decode_error`
- Generic RON parser with a dynamically typed `RonValue`
- Canonical compact serializer for every `RonValue` variant
- Deterministic multiline formatter with configurable indentation
- RON document attributes for `enable`, `type`, and `schema`
- Open, closed, and inclusive RON ranges with typed `RonRange` conversion
- `unwrap_newtypes`, `implicit_some`, `unwrap_variant_newtypes`, and
  `explicit_struct_names` options
- `parse_document`, `decode_with_options`, and `encode_with_options`
- `check`, `format`, and `compact` CLI commands via `cmd/ron`
- Compatibility corpus covering valid, extension, and invalid documents
- Official `moonbitlang/x/fs` dependency for CLI file access
- `FromRon` and `ToRon` traits with typed `decode` and `encode`
- Typed implementations for primitives, options, arrays, string maps, tuples,
  and `RonValue`
- Typed implementations for `Int16`, `UInt16`, fixed arrays, array views,
  `Result`, and tuples up to eight elements
- Path-aware `RonDecodeError` and `RonPath`
- Positioned `RonError` diagnostics and nesting-depth limits
- Public `parse`, `valid`, and `to_string` entry points
- Parser tests covering scalars, comments, strings, bytes, containers,
  structs, enums, errors, and depth limits
- Serializer tests covering escaping, exact output, and parse/serialize
  round trips
- Formatter tests covering nested structures, maps, indentation, empty
  containers, and round trips
- Extension tests covering attributes, option precedence, and all four
  supported extension semantics
- Range tests covering parsing, compact/pretty output, typed conversion, and
  decimal bounds
- Typed codec tests covering custom structs, enums, containers, and errors
- A runnable parser example and repository CI

## 0.1.0

Initial public release on mooncakes.io.
