# RON ranges

The parser supports every RON range spelling from the compatibility grammar:

```ron
..
..10
3..
3..10
3..=10
-2.1..=7.3
```

`RonValue::Range` stores optional start and end values plus an inclusive flag.
Compact and pretty serialization preserve the range spelling, and `RonRange`
implements `FromRon` and `ToRon` for typed conversion.

Out-of-order bounds and type-specific range semantics remain the caller's
responsibility; this layer preserves the value model and syntax.
