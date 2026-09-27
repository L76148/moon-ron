# Typed RON codec

`FromRon` and `ToRon` keep typed conversion separate from parsing and
serialization. The library provides implementations for primitive values,
options, arrays, string-keyed maps, tuples up to three elements, and
`RonValue`.

## Custom struct

```moonbit
priv struct Point {
  x : Int
  y : Int
}

impl @ron.ToRon for Point with fn to_ron(self) {
  @ron.RonValue::Struct("Point", [
    ("x", @ron.ToRon::to_ron(self.x)),
    ("y", @ron.ToRon::to_ron(self.y)),
  ])
}

impl @ron.FromRon for Point with fn from_ron(value, path) {
  let fields = @ron.struct_fields(value, path)
  {
    x: @ron.field(fields, "x", path),
    y: @ron.field(fields, "y", path),
  }
}
```

## Entry points

```text
@ron.encode(value)
@ron.to_value(value)
@ron.decode[Type](source)
@ron.from_value[Type](value)
```

Decode failures use `RonDecodeError` and `RonPath`, so callers can identify
syntax failures, missing fields, type mismatches, tuple length errors, and
unknown enum variants.
