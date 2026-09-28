# Final acceptance checklist

## Hard requirements

| Requirement | Evidence |
| --- | --- |
| MoonBit is the primary implementation language | 3,900+ MoonBit source lines under `moon.mod` |
| Public GitHub repository | https://github.com/L76148/moon-ron |
| Clear commit history | 53 commits, all authored by `L76148 <2237501538@qq.com>` |
| Clear source structure | Parser, AST, serializer, formatter, diagnostics, typed codec, CLI, examples, corpus |
| README with goal, installation, usage, examples | `README.md` and `README.mbt.md` |
| CI covers check, build, and test | `.github/workflows/ci.yml`; latest run `36426269022` passed |
| Runnable example | `cmd/main`, `cmd/typed`, `cmd/extensions`, and `cmd/ron` |
| Core-path tests | 49 tests pass on Wasm and Wasm GC |
| Published on mooncakes.io | `L76148/moon-ron@0.1.1` |
| OSI-approved license | Apache-2.0 |

## Quality signals

- `moon check --deny-warn --target all` passes.
- `moon fmt --check` passes.
- `moon info` produces committed interfaces for every package.
- CLI compatibility corpus covers valid, invalid, extension, range, and typed
  documents.
- Source-aware diagnostics identify line, column, source text, and caret.
- No obsolete contributor identity is present in reachable Git objects.

## Commands

```text
moon check --deny-warn
moon test --deny-warn
moon fmt --check
moon run cmd/main
moon run cmd/typed
moon run cmd/extensions
moon run cmd/ron -- check corpus/basic.ron
```
