# Feature Process

Every new feature must be implemented across ALL 5 backends simultaneously.
No backend progresses without the others having parity.

## Backends (5 total)

| Backend | Pipeline | Converter | Codegen | Test file |
|---|---|---|---|---|
| cleanc | typed (sem) | `ast/convert.nim` (Language.C) | `codegen/C.nim` | `backend/test/cleanc.nim` |
| zig | typed (sem) | `ast/convert.nim` (Language.Zig) | `codegen/zig.nim` | `backend/test/zig.nim` |
| minc | untyped (parse) | `ast/convert.nim` (Language.C) | `codegen/C.nim` | `cli/minc_test.nim` |
| minz | untyped (parse) | `ast/convert.nim` (Language.Zig) | `codegen/zig.nim` | (TBD) |
| nim | typed (sem) | `ast/convert.nim` (Language.Nim) | `codegen/nim.nim` | `codegen/nim_test.nim` |

- **Typed** backends use `nimc/Typed.nim` (full semantic analysis, symbols carry type info)
- **Untyped** backends use `nimc/Untyped.nim` (parse only, no type resolution)
- The converter is target-aware (`Language` enum) and produces target-specific type names in the AST

## Steps

1. **Track the feature**: Add the syntax construct to `doc/all.nim`, `doc/all.c`, and `doc/all.zig` marked as `[ ]`.
2. **Codegen unit tests (ALL 3 LANGS)**: Add a test case factory in `codegen/test/<category>.nim`. Add assertions to ALL THREE: `codegen/c_test.nim`, `codegen/zig_test.nim`, AND `codegen/nim_test.nim`. See them FAIL.
3. **Backend integration tests**: Create `src/nonim/backend/test/cases/<name>/input.nim` with expected outputs (`expected.c`, `expected.zig`, `expected.nim`). Add assertions to ALL 5 backend test files. See them FAIL.
4. **Converter**: If the feature requires a new PNode kind, implement it in `ast/convert.nim`. The converter handles BOTH typed and untyped PNode trees.
5. **C codegen**: Implement in `codegen/C.nim`. See `codegen/c_test.nim` PASS.
6. **Zig codegen**: Implement in `codegen/zig.nim`. See `codegen/zig_test.nim` PASS.
7. **Nim codegen**: Implement in `codegen/nim.nim`. See `codegen/nim_test.nim` PASS.
8. **Run ALL tests**: All 3 codegen unit tests AND all 5 backend integration tests must pass. No backend can be skipped.
9. **Mark done**: Update the `[ ]` to `[x]` in all three `doc/all.*` files.

## Phase Landmarks

After completing each phase, a landmark test (`cases/phaseN/input.nim`) must be created that exercises ALL features of that phase in a single realistic program. This landmark must pass on all 5 backends. The landmark test is in each backend test file under `describe "nonim.lang | astTF Phase Landmarks"`.

Phase landmarks MUST also validate the expected output files with the target language's own toolchain:
- **Nim**: `nim check expected.nim`
- **Zig**: `zig ast-check expected.zig`
- **C**: `clang -fsyntax-only expected.c`

If any validation fails, the codegen output is structurally invalid regardless of string matching.

## Rules

- ALL 5 BACKENDS must pass. No backend is exempt.
- A feature is NOT done until cleanc, zig, minc, minz, AND nim all pass for it.
- The codegen tests run BEFORE the backend tests.
- NEVER implement a feature in one backend without the others.
- Test cases are shared — one `input.nim` produces expected output for every target language.
- Expected files MUST be validated with the target language toolchain (`nim check`, `zig ast-check`, `zig cc -fsyntax-only`). NEVER use codegen output as expected files without this validation — that's circular and catches nothing.
- When typed and untyped produce different output (e.g., type translation, operator reordering), use `expected.untyped.c` / `expected.untyped.zig` alongside the typed `expected.c` / `expected.zig`. The untyped test runners check for the `.untyped.` variant first, falling back to the regular file.
- Input files MUST have explicit type annotations — untyped backends cannot infer types.
- The converter is target-aware (Language enum) and typed-aware (`typed: bool`). Type translation happens in the converter ONLY for typed ASTs. Untyped passes type names through verbatim.
- Codegens are pure renderers — they emit whatever text is in the AST without translation.
- East-const rule applies to all C output (`int const`, not `const int`).
- Zig output must pass `zig fmt` (when format is active).
- C output must pass `clang-format -i` (when format is active).

## Current features (ordered by astTF phases)

### Phase 0: Turing-Complete Core

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Variable: let | `let x :int= 42` | `static int const x = 42;` | `const x: i64 = 42;` | [x] |
| Variable: var | `var x :int= 0` | `static int x = 0;` | `var x: i64 = 0;` | [x] |
| Variable: exported | `let x* :int= 42` | `int const x = 42;` | `pub const x: i64 = 42;` | [x] |
| Variable: multiple bindings | `let a, b :int= 0` | `static int64_t const a = 0; static int64_t const b = 0;` | `const a: isize = 0; const b: isize = 0;` | [x] |
| Variable: type inference | `let x = 42` | `int64_t const x = 42;` | `const x: isize = 42;` | [x] (typed only) |
| Procedure: forward decl | `proc add (x, y :int) :int` | `static int add (int const x, int const y);` | `fn add (x: i64, y: i64) i64;` | [x] |
| Procedure: body | `proc add (...) :int= return x + y` | `static int add (...) { return x + y; }` | `fn add (...) i64 { return x + y; }` | [x] |
| Procedure: exported | `proc add* (...)` | `int add (...)` (no static) | `pub fn add (...)` | [x] |
| Expression: integer literal | `42` | `42` | `42` | [x] |
| Expression: identifier | `x` | `x` | `x` | [x] |
| Expression: binary affix | `x div y` / `x + y` | `x / y` / `x + y` | `x / y` / `x + y` | [x] |
| Expression: unary prefix | `-x` / `not x` | `-x` / `!x` | `-x` / `!x` | [x] |
| Expression: indexed | `arr[i]` | `arr[i]` | `arr[i]` | [x] |
| Type: array | `array[10, int]` | `int[10]` | `[10]i64` | [x] |
| Expression: conditional | `if x < 0: ...` | `if (x < 0) { ... }` | `if (x < 0) { ... }` | [x] |
| Expression: loop | `while x > 0: ...` | `while (x > 0) { ... }` | `while (x > 0) { ... }` | [x] |
| Statement: expression | `x = x + 1` | `x = x + 1;` | `x = x + 1;` | [x] |
| Expression: function call | `add(1, 2)` | `add(1, 2)` | `add(1, 2)` | [x] |
| Statement: variable | `let x :int= 42` | `static int const x = 42;` | `const x: i64 = 42;` | [x] |
| Statement: procedure | (see procedure) | (see procedure) | (see procedure) | [x] |
| Statement: keyword return | `return x` | `return x;` | `return x;` | [x] |
| Statement: keyword discard | `discard expr` | `(void)(expr);` | `_ = expr;` | [x] |
| Statement: keyword break | `break` | `break;` | `break;` | [x] |
| Statement: keyword continue | `continue` | `continue;` | `continue;` | [x] |
| Type: primitive | `int` / `float32` | `int64_t` / `float` | `isize` / `f32` | [x] |
| Type: array | `array[10, int]` | `int64_t[10]` | `[10]isize` | [x] |
| Type: cstring | `cstring` | `char const*` | `[:0]const u8` | [ ] |
| Type: string | `string` | (dynamic, TBD) | (dynamic, TBD) | [ ] |
| Type: seq | `seq[int]` | (dynamic array, TBD) | (std.ArrayList, TBD) | [ ] |
| Type: int/uint platform size | `int`/`uint` mapped to 64-bit for now; needs proper platform-aware solution alongside string/seq/tuple runtime types | | | [ ] |

### Phase 1: Practical Programs

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Type: ptr | `ptr int` | `int*` | `*i64` | [ ] |
| Literal: float | `3.14` | `3.14` | `3.14` | [ ] |
| Literal: string | `"hello"` | `"hello"` | `"hello"` | [ ] |
| Literal: char | `'a'` | `'a'` | `'a'` | [ ] |
| Literal: bool | `true` / `false` | `true` / `false` | `true` / `false` | [ ] |
| Literal: nil | `nil` | `NULL` | `null` | [ ] |
| Statement: comment | `# comment` / `## doc` | `// comment` | `// comment` | [ ] |
| Statement: import | `import os` | `#include <os.h>` | `const os = @import("os");` | [ ] |
| Statement: passthrough | (unsupported syntax) | (unsupported syntax) | (unsupported syntax) | [ ] |
| Statement: alias | `const A = B` | `#define A B` | `const A = B;` | [ ] |
| Procedure: callable | `template` / `method` / `iterator` | N/A | N/A | [ ] |
| Procedure: private | no `*` | `static` | no `pub` | [ ] |
| Procedure: impure | `proc` vs `func` | N/A | N/A | [ ] |
| Format: whitespace | indentation-based | braces | braces | [ ] |

### Phase 2: Branches & Pragmas

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Branch: if/elif/else | `if x: ... elif y: ... else: ...` | `if (x) {...} else if (y) {...} else {...}` | `if (x) {...} else if (y) {...} else {...}` | [x] |
| Branch: case/of | `case x of 1: ... of 2: ...` | `switch (x) { case 1: ... case 2: ... }` | `switch (x) { 1 => ..., 2 => ... }` | [ ] |
| Pragma: standalone | `{.emit: "code".}` | `#pragma ...` | `@...` | [ ] |
| Pragma: on statement | `proc x() {.cdecl.}` | `__attribute__((cdecl))` | `export` / `inline` | [ ] |
| Pragma: on binding | `x {.volatile.}` | `volatile x` | `@volatileCast(x)` | [ ] |
| Expression: block | `block: ...` | `({ ... })` (GCC ext) | `blk: { ... }` | [ ] |

### Phase 3: Type System

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Type statement: object | `type Vec2 = object` | `typedef struct {...} Vec2;` | `const Vec2 = struct {...};` | [x] |
| Type: object exported fields | `x* :int` | `int x;` (all public) | `x: i64,` (all public) | [ ] |
| Type: object private fields | `x :int` (no `*`) | `int x;` (all public) | `x: i64,` (all public) | [ ] |
| Type: object keyword | union/tuple/interface | `union` / struct | `packed struct` / `extern struct` | [ ] |
| Type: enum | `type Dir = enum north, south` | `typedef enum { north, south } Dir;` | `const Dir = enum { north, south };` | [ ] |
| Type: enum values | `north = 0, south = 1` | `north = 0, south = 1` | `north = 0, south = 1` | [ ] |
| Type: procedure | `proc (x :int) :int` | `int (*)(int)` | `fn (i64) i64` | [ ] |
| Type: range | `range[0..10]` | N/A | N/A | [ ] |
| Type: visibility | `type X* = object` | N/A (all public) | `pub const X = struct` | [ ] |

### Phase 4: Control Flow & Compound Expressions

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Expression: array literal | `[1, 2, 3]` | `{1, 2, 3}` | `.{1, 2, 3}` | [ ] |
| Expression: object literal | `Vec2(x: 1, y: 2)` | `(Vec2){.x=1, .y=2}` | `.{.x=1, .y=2}` | [ ] |
| Expression: range | `0..10` | N/A | `0..10` | [ ] |
| Loop: for | `for i in 0..<10:` | `for (int i=0; i<10; i++)` | `for (0..10) \|i\|` | [ ] |
| Loop: do-while | N/A | `do {...} while (x);` | N/A | [ ] |
| Conditional: case keyword | `case x` | `switch (x)` | `switch (x)` | [ ] |

### Phase 5: Type Links & Generics

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Type: alias | `type Foo = int` | `typedef int Foo;` | `const Foo = i64;` | [ ] |
| Type: distinct | `type Foo = distinct int` | `typedef int Foo;` (no safety) | `const Foo = enum { _ };` | [ ] |
| Type: inheritance | `type Circle = object of Shape` | embedded struct | N/A | [ ] |
| Type: pragmas | `type X {.packed.} = object` | `__attribute__((packed))` | `packed` | [ ] |
| Generics: procedure | `proc foo[T](x :T)` | N/A (macros/void*) | `fn foo(comptime T: type, x: T)` | [ ] |
| Generics: object | `type Vec[T] = object` | N/A | `fn Vec(comptime T: type) type` | [ ] |
| Generics: instantiation | `Vec[int]` | N/A | `Vec(i64)` | [ ] |
| TypePrimitive: ref | `ref object` | pointer + malloc | `*T` | [ ] |
| TypePrimitive: ptr | `ptr int` | `int*` | `*i64` | [ ] |
| Expression: group | `(x + y)` | `(x + y)` | `(x + y)` | [ ] |

### Not in astTF phases (Nim-specific)

| Feature | Nim | C | Zig | Status |
|---|---|---|---|---|
| Tuple unpacking | `let (a, b) = foo()` | N/A | N/A | [ ] |
| Default params | `proc foo(x :int= 0)` | N/A | N/A | [ ] |
| Varargs | `proc foo(x :varargs[int])` | `void foo(int, ...)` | N/A | [ ] |
| Overloading | multiple procs same name | N/A | N/A | [ ] |
| Closures | `proc(): int= ...` | function pointers + ctx | N/A | [ ] |
| Iterators | `iterator items(x :seq[int])` | N/A | N/A | [ ] |
| Converters | `converter toInt(x :float)` | N/A | N/A | [ ] |
| Templates | `template foo()` | `#define foo()` | N/A | [ ] |
| Macros | `macro foo()` | N/A | N/A | [ ] |
| Defer | `defer: close(f)` | N/A | `defer` | [ ] |
| Try/except | `try: ... except: ...` | N/A | `catch` | [ ] |
| Raise | `raise newException(...)` | N/A | `return error.*` | [ ] |
| Seq types | `seq[int]` | dynamic array | `std.ArrayList` | [ ] |
| Custom operators | `proc \`+\`(...)` | function call | function call | [ ] |
| Dot access | `obj.field` | `obj.field` / `obj->field` | `obj.field` | [ ] |
| Type conversions | `int(x)` | `(int)(x)` | `@intCast(x)` | [ ] |
| If expressions | `let x = if c: a else: b` | `x = c ? a : b` | `const x = if (c) a else b` | [ ] |
| Compound assign | `x += 1` | `x += 1;` | `x += 1;` | [ ] |
| String interp | `&"hello {name}"` | N/A | `std.fmt` | [ ] |
| Export | `export module` | N/A | `pub` | [ ] |
