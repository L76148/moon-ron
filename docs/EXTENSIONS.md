# RON extensions

Document attributes are parsed only before the root value:

```ron
#![enable(implicit_some, unwrap_newtypes)]
Config(count: 5)
```

The parser also accepts and ignores `#![type = "..."]` and
`#![schema = "..."]` compatibility attributes.

## Supported extensions

- `unwrap_newtypes`: use `newtype` when decoding a newtype wrapper.
- `implicit_some`: `Option[T]` accepts a bare `T` value as `Some(value)`.
- `unwrap_variant_newtypes`: use `variant_newtype` for enum payloads.
- `explicit_struct_names`: use `require_struct_name` to reject anonymous
  struct syntax when a name is required.

## Options and documents

- `RonExtensions` holds the four extension flags.
- `RonOptions` combines extensions and the nesting-depth limit.
- `RonDocument` returns the parsed value together with extensions declared by
  the source document.
- `decode_with_options` merges caller options with document attributes before
  typed decoding.
- `encode_with_options` writes enabled extensions back as an attribute header.

Extension behavior is opt-in at the type level: newtype, enum, and struct
implementations call the corresponding helper where that behavior applies.
