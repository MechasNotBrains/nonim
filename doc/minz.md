## Import: minz — Include Design Notes
Zig has no `#include` or preprocessor directives.
The minz backend handles Nim `include` statements differently from minc.


### 1. Recursive include (no extension): `include module` → contents inlined
**Status: implemented.**
Identical to minc.
The preprocessor (`backend/preprocess.nim`) is shared between minc and minz.
It resolves extensionless `include` lines by recursively inlining the referenced source files (`.nim`, `.cm`, `.zm`)
before the Nim parser sees the code. Called by `backend/minz.nim` before `Untyped.compile`.


### 2. Global include (`@`) and local include (`.zig` extension): NOT native to Zig
**Status: implemented** (`backend/postprocess.nim`, run from `backend/minz.nim` after codegen).

Zig has no native equivalent of C's `#include <...>` or `#include "..."`.
Users must reference `.zig` files explicitly, e.g. `include @stdint.zig` or `include path/to/file.zig`.
C-style `.h` paths are a minc concern only.

These cases are emitted as passthrough `include …` lines by the converter,
then resolved and inlined by the post-process pass (`backend/includes.nim` shared loop).

- **minc**: `@`/extension includes become `#include` directives; the C compiler resolves paths.
- **minz**: nonim resolves `.zig` files relative to the input file and inlines their contents into the output.


## minz — Missing Features for Target Output
Target: produce valid Zig from minz source (Nim-like syntax with Zig-specific extensions).
Reference input/output pair: see bottom of this file.

| # | Feature | minz source | Zig target | Converter | Codegen | Complexity |
|---|---------|-------------|------------|-----------|---------|------------|
| 1 | `from` import with symbols | `from ./zig/core.zig import type` | `pub const type = @import("./zig/core.zig").type;` | `nkFromStmt`: `include_path` for module path, `symbol_path` + `Alias` chain for imported symbols | `statement_import_from`: emit `pub const <sym> = @import("<path>").<sym>;` per symbol | **done** |
| 2 | `from` import with `as` alias | `from ./zig/core.zig import type as Engine` | `pub const Engine = @import("./zig/core.zig").type;` | `nkInfix` with `as` in symbol children → `Alias.name` = original, `Alias.target` = alias | `statement_import_from`: use `Alias.target` as const name when present | **done** |
| 3 | `defer` keyword in bodies | `defer arena.deinit()` | `defer arena.deinit();` | `nkDefer` → `eKeyword` wrapped in `sExpression` | `expression_keyword` emits keyword generically | **done** |
| 4 | `try` prefix expression | `try: Jera.create(...)` | `try Jera.create(...)` | `nkTryStmt` → `eKeyword` with keyword="try" and value=inner expression | `expression_keyword` emits keyword + space + value; parser "expected 'except'" warning silenced | **done** |
| 5 | Error union return type `!T` | `proc main *() : !void=` | `pub fn main() !void {` | `nkPrefix(!, T)` for `!T`, `nkInfix(!, E, T)` for `E!T` — both route through `type_error` → `expression_prefix`/`expression_infix` | `type_name_affix`: renders prefix/infix affix as-is; NOTE: space required after `:` in source (`: !void` not `:!void`) | **done** |
| 6 | Anonymous struct literal `.(field: val)` | `.(system: .(window: ...))` | `.{.system= .{.window= ...}}` | `nkObjConstr` (`.()` syntax) and `nkTupleConstr` (named tuples) both → `eObject` with binding chain; parser "expression expected, but found '.'" warning silenced | `expression_object`: emit `.{.name= val, ...}` from `ExpressionObject.fields` | **done** |
| 7 | `@` prefix builtins | `@This()` | `@This()` | `nkPrefix` with `@` → `eAffix` prefix; chains into call correctly | `expression_affix`: suppresses space for `@` prefix (not letter-starting) | **done** |
| 8 | `##!` → `//!` module doc comment | `##!` prefix maps to `//!` (Zig module doc), not `///` | **done** |

### Reference input/output pair

**minz source:**
```
#:____________________
#  GPL-3.0-or-later  :
#:____________________
##! @fileoverview Cable Connector to all Jera modules
#_____________________________________________________|
# @deps mstd
from ./zig/mdk.zig import mstd.cstring
# @deps Jera
const jera * = @This()
const Jera * = jera.Engine.type
from ./zig/core.zig import type as Engine
from ./zig/game.zig import type as Game


#______________________________________
# @section Debug Example: Entry Point
#____________________________
import std
proc main *() :!void=
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator); defer arena.deinit()
  var J = try Jera.create(arena.allocator(), .(system: .(window: .(title: "Jeraᛃ Engine | Debug Example"))))
  J.start()
```

**Zig target:**
```zig
//:____________________
//  GPL-3.0-or-later  :
//:____________________
//! @fileoverview Cable Connector to all Jera modules
//_____________________________________________________|
// Jera
pub const jera    = @This();
pub const Jera    = jera.Engine.type;
pub const Engine  = @import("./zig/core.zig").type;
pub const Game    = @import("./zig/game.zig").type;
// mstd
pub const cstring = @import("./zig/mdk.zig").mstd.cstring;


//______________________________________
// @section Debug Example: Entry Point
//____________________________
const std = @import("std");
pub fn main() !void {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator); defer arena.deinit();
  var J = try Jera.create(arena.allocator(), .{.system= .{.window= .{.title= "Jeraᛃ Engine | Debug Example" }}});
  J.start();
}
```

---

## minz — Feature Phases

### Phase 0: Turing-Complete Core

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Variable: let | `let x :int= 42` | `const x: i64 = 42;` | [x] |
| Variable: var | `var x :int= 0` | `var x: i64 = 0;` | [x] |
| Variable: exported | `let x* :int= 42` | `pub const x: i64 = 42;` | [x] |
| Variable: multiple bindings | `let a, b :int= 0` | `const a: isize = 0; const b: isize = 0;` | [x] |
| Procedure: forward decl | `proc add (x, y :int) :int` | `fn add (x: i64, y: i64) i64;` | [x] |
| Procedure: body | `proc add (...) :int= return x + y` | `fn add (...) i64 { return x + y; }` | [x] |
| Procedure: exported | `proc add* (...)` | `pub fn add (...)` | [x] |
| Expression: integer literal | `42` | `42` | [x] |
| Expression: identifier | `x` | `x` | [x] |
| Expression: binary affix | `x + y` | `x + y` | [x] |
| Expression: unary prefix | `-x` / `not x` | `-x` / `!x` | [x] |
| Expression: indexed | `arr[i]` | `arr[i]` | [x] |
| Type: array | `array[10, int]` | `[10]i64` | [x] |
| Expression: conditional | `if x < 0: ...` | `if (x < 0) { ... }` | [x] |
| Expression: loop | `while x > 0: ...` | `while (x > 0) { ... }` | [x] |
| Statement: expression | `x = x + 1` | `x = x + 1;` | [x] |
| Expression: function call | `add(1, 2)` | `add(1, 2)` | [x] |
| Statement: keyword return | `return x` | `return x;` | [x] |
| Statement: keyword discard | `discard expr` | `_ = expr;` | [x] |
| Statement: keyword break | `break` | `break;` | [x] |
| Statement: keyword continue | `continue` | `continue;` | [x] |
| Type: primitive | `int` / `float32` | `isize` / `f32` | [x] |
| Type: cstring | `cstring` | `[:0]const u8` | [x] |

### Phase 1: Practical Programs

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Procedure: private | no `*` | no `pub` | [x] |
| Type: ptr | `ptr int` | `*i64` | [x] |
| Literal: float | `3.14` | `3.14` | [x] |
| Literal: string | `"hello"` | `"hello"` | [x] |
| Literal: char | `'a'` | `'a'` | [x] |
| Literal: bool | `true` / `false` | `true` / `false` | [x] |
| Literal: nil | `nil` | `null` | [x] |
| Statement: passthrough | `{.emit: "....".}` | `....` | [x] |
| Statement: comment | `# comment` / `## doc` | `// comment` / `/// doc` | [x] |
| Statement: module doc | `##! overview` | `//! overview` | [x] |
| Format: whitespace | normalization | normalization | [x] |
| Import: simple | `import @std` | `const std = @import("std");` | [x] |
| Import: local file | `import name` | `const name = @import("./name.zig");` | [x] |
| Import: from symbols | `from ./zig/core.zig import Game` | `pub const Game = @import("./zig/core.zig").Game;` | [x] |
| Import: from alias | `from @jera import Engine as Jera` | `pub const Jera = @import("jera").Engine;` | [x] |
| Import: module prefix | `import @name` → module, `import name` → local file | converter resolves `@` prefix | [x] |
| Include: recursive | `include module` | contents inlined (preprocessor) | [x] |
| Include: global | `include @file.zig` | contents inlined (postprocess) | [x] |
| Include: local | `include path/file.zig` | contents inlined (postprocess) | [x] |
| Keyword: defer | `defer: arena.deinit()` | `defer arena.deinit();` | [x] |
| Keyword: try prefix | `try: Jera.create(...)` | `try Jera.create(...)` | [x] |
| Error union return | `proc main *() : !void=` | `pub fn main () !void {` | [x] |
| Error union explicit | `proc main *() : anyerror!void=` | `pub fn main () anyerror!void {` | [x] |
| `@` prefix builtins | `@This()` | `@This()` | [x] |
| Anonymous struct literal | `.(field: val)` | `.{.field= val}` | [x] |

### Phase 2: Branches & Zig-Specific

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Branch: if/elif/else | `if x: ... elif y: ... else: ...` | `if (x) {...} else if (y) {...} else {...}` | [x] |
| Branch: case/of | `case x of 1: ... of 2: ...` | `switch (x) { 1 => ..., 2 => ... }` | [x] |
| Expression: block | `block: ...` | `blk: { ... }` | [x] |
| Named constructor | `Thing(x: 1)` | `Thing{.x= 1}` | [x] |
| Dot access | `obj.field` | `obj.field` | [x] |
| Compound assign | `x += 1` | `x += 1;` | [x] |
| Expression: group | `(x + y)` | `(x + y)` | [x] |
| Statement: alias | `const A = B` | `const A = B;` | N/A (no syntax in minz) |

### Phase 3: Type System

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Type: object | `type Vec2 = object` | `const Vec2 = struct {...};` | [x] |
| Type: object fields | `x :int` | `x: i64,` | [x] |
| Type: enum | `type Dir = enum north, south` | `const Dir = enum { north, south };` | [ ] |
| Type: enum values | `north = 0, south = 1` | `north = 0, south = 1` | [ ] |
| Type: procedure | `proc (x :int) :int` | `fn (i64) i64` | [x] |
| Type: alias | `type Foo = int` | `const Foo = i64;` | [x] |
| Type: visibility | `type X* = object` | `pub const X = struct` | [x] |
| Type: union/packed | `type X {.packed.} = object` | `packed struct` | [ ] |

### Phase 4: Control Flow & Compound Expressions

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Expression: array literal | `[1, 2, 3]` | `.{1, 2, 3}` | [ ] |
| Expression: object literal | `Vec2(x: 1, y: 2)` | `.{.x=1, .y=2}` | [ ] |
| Expression: range | `0..10` | `0..10` | [ ] |
| Loop: for | `for i in 0..<10:` | `for (0..10) \|i\|` | [ ] |
| If expression | `let x = if c: a else: b` | `const x = if (c) a else b` | [ ] |

### Phase 5: Generics & Advanced

| Feature | minz source | Zig target | Status |
|---|---|---|---|
| Type: distinct | `type Foo = distinct int` | `const Foo = enum { _ };` | [ ] |
| Generics: procedure | `proc foo[T](x :T)` | `fn foo(comptime T: type, x: T)` | [ ] |
| Generics: object | `type Vec[T] = object` | `fn Vec(comptime T: type) type` | [ ] |
| Generics: instantiation | `Vec[int]` | `Vec(i64)` | [ ] |
| Pragma: on statement | `proc x() {.cdecl.}` | `export` / `inline` | [ ] |
| Pragma: on binding | `x {.volatile.}` | `@volatileCast(x)` | [ ] |

---

## NOTE: ObjectConstructors
Thing(name: 42) and .(name: 42) already go through the same codepath (expression_obj_constr).
Nim parses both as nkObjConstr. The difference is that node[0]: nkIdent "Thing" vs nkEmpty for the .() form.

Right now the converter discards node[0] entirely — so Thing(name: 42) loses the type name.
To support Thing{.name= 42} output in Zig, we'd need to store the constructor name in ExpressionObject.
The astTF spec has ExpressionObject with no name or type field, and ExpressionCall which has fields
These two are able to handle unnamed+named constructors.

For now, both forms produce the same anonymous .{...} output.

