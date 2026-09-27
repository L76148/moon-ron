# First milestone verification

Recorded on 2026-09-28.

| Check | Result |
| --- | --- |
| `moon check --deny-warn` | passed |
| `moon test --deny-warn` | 13 of 13 passed |
| `moon test --deny-warn --target wasm` | 13 of 13 passed |
| `moon test --deny-warn --target wasm-gc` | 13 of 13 passed |
| `moon fmt --check` | passed |
| `moon run cmd/main` | printed the parsed `Point` value |

The local machine does not have Node.js or a system C compiler, so JavaScript
runtime execution and Native linking were not available in this environment.
Static checks for all configured targets passed with
`moon check --deny-warn --target all`.

This verification covers only the generic parser milestone. Serialization,
typed decoding, mooncakes.io publication, and remote CI execution remain
required before final acceptance.
