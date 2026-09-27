# Milestone verification

Recorded on 2026-09-28.

| Check | Result |
| --- | --- |
| `moon check --deny-warn` | passed |
| `moon test --deny-warn` | 33 of 33 passed |
| `moon test --deny-warn --target wasm` | 33 of 33 passed |
| `moon test --deny-warn --target wasm-gc` | 33 of 33 passed |
| `moon fmt --check` | passed |
| `moon run cmd/main` | printed multiline `Point` output |
| `moon run cmd/typed` | encoded and decoded a custom `Point` type |
| `moon run cmd/extensions` | preserved `implicit_some` in a typed config |

The local machine does not have Node.js or a system C compiler, so JavaScript
runtime execution and Native linking were not available in this environment.
Static checks for all configured targets passed with
`moon check --deny-warn --target all`.

This verification covers the generic parser, compact serializer, structured
formatter, typed codec, and extension-attribute milestones. Compatibility
corpus, CLI workflows, mooncakes.io publication, and remote CI execution
remain required before final acceptance.
