# MON syntax

A MON document is one value. Whitespace is irrelevant, `//` starts a comment
that ends at the newline, and there are no other comment forms.

## Grammar

```text
document      = trivia* value trivia*
value         = "true" | "false" | "()" | char | string | multiline
              | byte | byte_string | number
              | sequence | parenthesized | braced
              | name | name "(" arguments ")" | name "{" fields "}"
              | range
sequence      = "[" (value ("," value)* ","?)? "]"
parenthesized = "(" ")" | "(" value ")"
              | "(" value "," (value ",")* value? ","? ")"
braced        = "{" "}" | "{" "key": value, ... "}"
              | "{" field: value, ... "}"
fields        = field ":" value ("," field ":" value)* ","?
field         = lower_name
name          = UpperName ("::" UpperName)*
range         = value? (".." | "..=") value?
```

Notes on the shape:

- `()` is `Unit`. `(1)` is the value `1`, because MoonBit has no
  one-element tuple, and `(1, 2)` is a tuple.
- `{ "key": value }` is a `Map` whose keys are value expressions, and
  `{ field: value }` is a `Fields` value whose keys are bare names. The
  lookahead for `name:` is what separates the two.
- `None` is a `Variant`, `Some(1)` is a `TupleVariant`, and a bare `Name` or
  `Enum::Name` is a `Variant`. In MoonBit those spellings are constructors,
  so MON keeps them as constructors instead of inventing an option type.
- A MON document has no free variables, so a lowercase name is only legal as
  a field name after a `{`, or as a map key after `:`.

## Every literal is checked against the compiler

The value of MON is that its literals are MoonBit's literals. The table below
was produced by compiling each spelling with the MoonBit toolchain and
keeping only the forms the compiler accepts.

| MON form | Example | MoonBit |
| --- | --- | --- |
| unit | `()` | accepted |
| boolean | `true`, `false` | accepted |
| char | `'A'`, `'\n'`, `'\u{4E2D}'`, `'\''` | accepted |
| char, rejected | `'\0'`, `'\x41'` | `\0` is a lexing error; `\x..` is deprecated for `Char` |
| string | `"a\tb"`, `"\u{4E2D}"`, `"\u0041"`, `"\\"`, `"\/"`, `"\b"`, `"\f"` | accepted |
| string, rejected | `"\0"`, `"\v"`, `"\a"` | invalid escape |
| multiline | `#|first` / `#|second` | accepted |
| byte | `b'z'`, `b'\x41'` | accepted |
| byte string | `b"raw\x00bytes"`, `b"\x41A"` | accepted; `\x` takes exactly two digits |
| integer | `42`, `-7`, `0x2A`, `0o52`, `0b101010`, `1_000_000` | accepted |
| integer, rejected | `1l` | unknown suffix |
| sized integer | `9_000_000_000L`, `4_294_967_295U`, `18_446_744_073_709_551_615UL` | accepted |
| integer, out of range | `4294967296` | literal is out of range for `Int` |
| float | `3.5`, `-1.5`, `1.25e-3`, `1.0e10` | accepted |
| float, rejected | `1e10`, `1.5f` | an exponent needs a fractional part; there is no `f` suffix |
| sequence | `[1, 2, 3]` | accepted |
| tuple | `(1, "a")` | accepted |
| map | `{ "cpu": 4 }` | accepted |
| field map | `{ x: 1 }` | accepted when the type is known |
| constructor | `Some(1)`, `None`, `Ok(1)`, `Color::Red` | accepted |
| comments | `// text` | accepted |
| comments, rejected | `/* text */` | MoonBit has no block comments |

`\x` is a byte escape only: MoonBit accepts `b"\x41"` and rejects `"\x41"`.
MON follows the same rule.

### Multiline strings

The `#|` form keeps the text after the marker verbatim and drops the
indentation before it. Measured against MoonBit:

```text
    #|w          -> "w"
    #| x         -> " x"
    #|  y        -> "  y"
      #|  b      -> "  b"    (second line of a literal)
```

Lines are joined with `\n` and no trailing newline is added. A line that does
not start with `#|` ends the literal, so inside a container the literal has to
be wrapped in parentheses, exactly as MoonBit requires.

## Two extensions for data

MoonBit is an expression language, and two things a data document needs are
not expressions:

- **Named records.** `Pt { x: 1 }` is rejected by the compiler with
  "Unexpected `{` after `Pt`, missing `::` here", because a struct literal
  infers its type from the context. A data document has no context, so MON
  lets the document name the record: `Point { x: 1, y: 2 }` parses to
  `Record("Point", ...)`. The unnamed form `{ x: 1 }` stays available for
  data that is already inside a named record.
- **Ranges.** MoonBit accepts `..<` and `..=` only inside `for` loops
  ("Range operators are currently only supported in `for .. in` loops"), and
  `1..10` is not an expression at all. MON gives data documents `1..10`,
  `1..=10`, `..10`, and `1..`.

Both extensions are marked here because the rest of the grammar is not a
reinterpretation of MoonBit syntax; it is MoonBit syntax.

## Strictness where the compiler is lenient

MON rejects `1_` and `1__0` even though the compiler accepts them. A digit
separator has to sit between digits, which keeps the spelling unambiguous for
other tools that read the same files.

## Writing

`to_string` writes the canonical compact form and `to_string_pretty` writes the
multiline form. Both produce text that `parse` reads back as an equal value,
and `mon compact` and `mon format` do the same from the CLI.

```text
let source = @mon.to_string(value)
let readable = @mon.to_string_pretty(value, indent=2)
```

The output is canonical rather than literal-preserving: `0x2A` comes back as
`42`, `1.25e-3` as `0.00125`, and a `#|` string as one escaped line. What
matters for reading back is kept:

- an integral double keeps a fractional part (`3.0`) and a printed exponent
  gains one (`1.0e-7`), so the text reads as a `Double` and not as an `Int`;
- sized integers keep their suffix (`9000000000L`, `4294967295U`,
  `18446744073709551615UL`);
- bytes use the two-digit `\x..` escape outside printable ASCII, and strings
  use `\u{...}` for control characters;
- a one-element tuple is written `(1,)`, because MoonBit has no one-element
  tuple and `(1)` is just `1`;
- empty containers stay `[]`, `{}`, and `()`.

Two shapes raise a `MonWriteError` instead of producing text that would not
read back: a double that is an infinity or a NaN, which MoonBit has no literal
for, and a name or field name that is not a MON name. The reader can never
produce either, so a parsed document always round-trips.

## Directives

A document can ask for text before it is read. `preprocess` expands the
directives and returns a plain MON document, so the reader stays a reader:

```text
let source = @mon.preprocess(document, environment=environment)
let value = @mon.parse(source)
```

- `#include "path"` is replaced by that document, expanded with the same
  environment. The environment decides what a path means, so a document can be
  assembled from a directory, from memory, or from a test fixture, and the
  preprocessor reports a cycle, a document it cannot read, and an include that
  nests deeper than `max_include_depth`.
- `#env "NAME"` is replaced by the value of that variable, and
  `#env "NAME" (fallback)` uses the parenthesised document when the variable is
  not set. The value of a variable is MON text, so `MON_PORTS="[8080, 8081]"`
  works as well as `MON_PORTS=8080`, and the parentheses keep a fallback from
  swallowing the punctuation around it:

```text
Config {
  replicas: #env "REPLICAS" (3),
  window: #env "WINDOW" (1..8),
}
```

Directives are only recognised outside strings, characters, comments, and `#|`
multiline strings, so a document that talks *about* directives stays a
document:

```text
[
  "#include \"a.mon\"",   // a string, not a directive
  // #env "PORT" (1)      // a comment, not a directive
]
```

## Generating MoonBit source

`to_moonbit_source` writes a MoonBit binding for a value, which inlines a
document into a program instead of parsing it at start-up:

```text
@mon.to_moonbit_source(value, name="config", type_name="Config")
```

```text
let config : Config = Config::{
  name: "api",
  ports: [
    8080,
  ],
}
```

A named record gains the `::` MoonBit asks for, an integral double keeps its
fractional part, and a range is refused because MoonBit has no range expression
outside a `for` loop. The names in the document become MoonBit names, so a
field that collides with a reserved word such as `sealed` is a document the
generator cannot express.

`cmd/embedded` is the compile-time proof of this path: its `generated.mbt`
holds the output of
`moon run cmd/mon -- gen corpus/mon/embedded.mon config Config`, CI regenerates
that file from the document, formats it, and fails when the result differs, and
the package is built and run.

## RON

The `mon_ron` package converts between the two notations, which share one data
model:

```text
let ron = @mon_ron.to_ron(value)
let value = @mon_ron.from_ron(ron)
```

`mon to-ron <file>` and `mon from-ron <file>` do the same from the CLI, and
`to-ron` expands directives first, so a document that includes fragments
converts after it has been assembled.

The mapping follows what each reader produces, so the text survives the
crossing: `Some(1)` and `None` become a RON `Option`, `Name { field: value }`
becomes a RON struct, `Name(value)` a tuple struct, and a qualified name an
enum. A MON field map `{ field: value }` becomes a RON map with identifier
keys, which is the shape RON reads that text back as. RON keeps a single number
type, so a value that fits `Int` or `UInt` is written with the narrower MON
type, and MON's range maps to RON's range.

Three shapes belong to only one notation, and converting them reports an error
instead of rewriting them quietly: RON's bare identifiers such as `foo` have no
MON value, RON's infinities and NaN have no MoonBit literal, and `Some` with a
number of values other than one has no RON option. `MonConvertError` carries
those three cases and `message` renders them.

The conversion is a pair of functions rather than `ToRon`/`FromRon`
implementations: MoonBit rejects an implementation of a foreign trait for a
foreign type, and letting either core package depend on the other would undo
the split that keeps MON a notation and RON a notation.
