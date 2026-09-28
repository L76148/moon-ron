# Changelog

## Unreleased

### Added

Published as `L76148/moon-ron@0.1.0` on mooncakes.io.

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
