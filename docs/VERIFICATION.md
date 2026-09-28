# Milestone verification

Recorded on 2026-09-28.

| Check | Result |
| --- | --- |
| `moon check --deny-warn` | passed |
| `moon test --deny-warn` | 49 of 49 passed |
| `moon test --deny-warn --target wasm` | 49 of 49 passed |
| `moon test --deny-warn --target wasm-gc` | 49 of 49 passed |
| `moon fmt --check` | passed |
| `moon run cmd/main` | printed multiline `Point` output |
| `moon run cmd/typed` | encoded and decoded a custom `Point` type |
| `moon run cmd/extensions` | preserved `implicit_some` in a typed config |
| `moon run cmd/ron -- check corpus/basic.ron` | passed |
| `moon run cmd/ron -- format corpus/basic.ron` | produced multiline RON |
| `moon run cmd/ron -- check corpus/invalid/unclosed-list.ron` | failed as expected |
| `moon run cmd/ron -- check corpus/ranges.ron` | passed |
| `moon run cmd/ron -- check corpus/typed_values.ron` | passed |
| `moon publish` | published `L76148/moon-ron@0.1.1` |
| `moon search L76148/moon-ron` | found version `0.1.1` |
| `git push origin main` | pushed all commits to GitHub |
| GitHub Actions run `36421875599` | completed successfully |

The local machine does not have Node.js or a system C compiler, so JavaScript
runtime execution and Native linking were not available in this environment.
Static checks for all configured targets passed with
`moon check --deny-warn --target all`.

This verification covers all six core development milestones plus range and
typed-codec hardening and source-aware diagnostics. The package is published
to mooncakes.io, the GitHub repository is public, and remote CI passes. The
repository is ready for final submission and organizer review.
