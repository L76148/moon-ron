# Milestone verification

Recorded on 2026-09-28.

| Check | Result |
| --- | --- |
| `moon check --deny-warn` | passed |
| `moon test --deny-warn` | 22 of 22 passed |
| `moon test --deny-warn --target wasm` | 22 of 22 passed |
| `moon test --deny-warn --target wasm-gc` | 22 of 22 passed |
| `moon fmt --check` | passed |
| `moon run cmd/main` | printed canonical `Point(x: 1, y: 2, tags: ["parser", "ron"])` |
| `moon run cmd/typed` | encoded and decoded a custom `Point` type |

The local machine does not have Node.js or a system C compiler, so JavaScript
runtime execution and Native linking were not available in this environment.
Static checks for all configured targets passed with
`moon check --deny-warn --target all`.

This verification covers the generic parser, canonical serializer, and typed
codec milestones. Pretty formatting, mooncakes.io publication, and remote CI
execution remain required before final acceptance.
