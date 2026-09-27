# RON compatibility corpus

These fixtures exercise parser, formatter, serializer, typed codec, and
extension behavior without requiring external services.

- `basic.ron`: structs, lists, maps, tuples, strings, bytes, and numbers
- `extensions.ron`: all supported document extension attributes
- `kitchen_sink.ron`: nested RON structures and comments
- `invalid/unclosed-list.ron`: parse failure
- `invalid/unknown-extension.ron`: extension validation failure

Run a fixture through the CLI:

```text
moon run cmd/ron -- check corpus/basic.ron
moon run cmd/ron -- format corpus/basic.ron
moon run cmd/ron -- compact corpus/kitchen_sink.ron
```
