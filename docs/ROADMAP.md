# Roadmap

Development is intentionally split into independently verifiable increments.

1. [x] Generic RON parser and dynamic value tree
2. [x] Canonical RON serializer
3. [x] Typed `FromRon` and `ToRon` conversion traits
4. [x] Structured formatter and diagnostics
5. [x] RON extension attributes
6. [x] CLI, examples, and compatibility corpus
7. [x] RON range syntax and typed `RonRange`

The `mon` package extends the module with MON, a data notation written in
MoonBit literal syntax, and it grows under the same rules.

8. [x] MON syntax core: lexer, parser, `MonValue`, positioned diagnostics, and
   the `mon check` CLI
9. [x] MON writer: canonical output and a formatter for MON documents
10. [x] MON preprocessor: directive expansion and MoonBit source generation
11. [x] MON to RON bridge: value conversion in `mon_ron`, plus the
    `mon to-ron` and `mon from-ron` commands

Each increment must pass the repository CI and be usable without requiring
unfinished later increments.
