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

## NOTE: ObjectConstructors
Thing(name: 42) and .(name: 42) already go through the same codepath (expression_obj_constr).
Nim parses both as nkObjConstr. The difference is that node[0]: nkIdent "Thing" vs nkEmpty for the .() form.

Right now the converter discards node[0] entirely — so Thing(name: 42) loses the type name.
To support Thing{.name= 42} output in Zig, we'd need to store the constructor name in ExpressionObject.
The astTF spec has ExpressionObject with no name or type field, and ExpressionCall which has fields
These two are able to handle unnamed+named constructors.

For now, both forms produce the same anonymous .{...} output.

