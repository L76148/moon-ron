# Roadmap

Development is intentionally split into independently verifiable increments.

1. [x] Generic RON parser and dynamic value tree
2. [x] Canonical RON serializer
3. [x] Typed `FromRon` and `ToRon` conversion traits
4. [x] Structured formatter and diagnostics
5. [x] RON extension attributes
6. [ ] CLI, examples, and compatibility corpus

Each increment must pass the repository CI and be usable without requiring
unfinished later increments.
