// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "L76148/moon-ron"

version = "0.1.1"

readme = "README.mbt.md"

repository = "https://github.com/L76148/moon-ron"

license = "Apache-2.0"

keywords = [ "ron", "parser", "serialization", "configuration" ]

preferred_target = "wasm"

description = "A strict RON parser, serializer, formatter, and typed codec for MoonBit."

import {
  "moonbitlang/x@0.5.5",
}
