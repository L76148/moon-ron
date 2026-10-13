# RON compatibility corpus

These fixtures exercise parser, formatter, serializer, typed codec, and
extension behavior without requiring external services.

- `basic.ron`: structs, lists, maps, tuples, strings, bytes, and numbers
- `extensions.ron`: all supported document extension attributes
- `kitchen_sink.ron`: nested RON structures and comments
- `ranges.ron`: open, closed, inclusive, integer, and decimal ranges
- `typed_values.ron`: values used by the broader typed codec suite
- `invalid/unclosed-list.ron`: parse failure
- `invalid/unknown-extension.ron`: extension validation failure

Run a fixture through the CLI:

```text
moon run cmd/ron -- check corpus/basic.ron
moon run cmd/ron -- format corpus/basic.ron
moon run cmd/ron -- compact corpus/kitchen_sink.ron
```

## MON documents

`corpus/mon` holds the MON fixtures, which the `cmd/mon` reader checks:

- `scalars.mon`: every scalar spelling, including sized integers and bytes
- `config.mon`: a named record with maps, options, ranges, and a `#|` string
- `services.mon`: nested records, variants, field maps, and open ranges

```text
moon run cmd/mon -- check corpus/mon/scalars.mon
moon run cmd/mon -- check corpus/mon/config.mon
moon run cmd/mon -- check corpus/mon/services.mon
moon run cmd/mon -- compact corpus/mon/config.mon
moon run cmd/mon -- format corpus/mon/services.mon
```
