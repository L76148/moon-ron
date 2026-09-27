# Roadmap

Development is intentionally split into independently verifiable increments.

1. [x] Generic RON parser and dynamic value tree
2. [x] Canonical RON serializer
3. [ ] Typed `FromRon` and `ToRon` conversion traits
4. [ ] Structured formatter and diagnostics
5. [ ] RON extension attributes
6. [ ] CLI, examples, and compatibility corpus

Each increment must pass the repository CI and be usable without requiring
unfinished later increments.
