# Changelog

## Unreleased

### Added

- Generic RON parser with a dynamically typed `RonValue`
- Canonical compact serializer for every `RonValue` variant
- Deterministic multiline formatter with configurable indentation
- `FromRon` and `ToRon` traits with typed `decode` and `encode`
- Typed implementations for primitives, options, arrays, string maps, tuples,
  and `RonValue`
- Path-aware `RonDecodeError` and `RonPath`
- Positioned `RonError` diagnostics and nesting-depth limits
- Public `parse`, `valid`, and `to_string` entry points
- Parser tests covering scalars, comments, strings, bytes, containers,
  structs, enums, errors, and depth limits
- Serializer tests covering escaping, exact output, and parse/serialize
  round trips
- Formatter tests covering nested structures, maps, indentation, empty
  containers, and round trips
- Typed codec tests covering custom structs, enums, containers, and errors
- A runnable parser example and repository CI
