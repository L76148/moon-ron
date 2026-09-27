# Changelog

## Unreleased

### Added

- Generic RON parser with a dynamically typed `RonValue`
- Canonical compact serializer for every `RonValue` variant
- Positioned `RonError` diagnostics and nesting-depth limits
- Public `parse`, `valid`, and `to_string` entry points
- Parser tests covering scalars, comments, strings, bytes, containers,
  structs, enums, errors, and depth limits
- Serializer tests covering escaping, exact output, and parse/serialize
  round trips
- A runnable parser example and repository CI
