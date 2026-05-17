# Feature Process

Every new feature must be implemented across all backends simultaneously.
No backend progresses without the others having parity.

## Steps

1. **Track the feature**: Add the syntax construct to `doc/all.nim`, `doc/all.c`, and `doc/all.zig` marked as `[ ]`.
2. **Codegen unit tests (ALL 3 LANGS)**: Add a test case factory in `codegen/test/<category>.nim`. Add assertions to ALL THREE: `codegen/c_test.nim`, `codegen/zig_test.nim`, AND `codegen/nim_test.nim`. See them FAIL.
3. **Backend integration tests**: Create `src/nonim/backend/test/cases/<name>/input.nim` with expected outputs (`expected.c`, `expected.zig`, `expected.nim`). Add assertions to `backend/test/cleanc.nim` and `backend/test/zig.nim`. See them FAIL.
4. **Converter**: If the feature requires a new PNode kind, implement it in `ast/convert.nim`.
5. **C codegen**: Implement in `codegen/C.nim`. See `codegen/c_test.nim` PASS.
6. **Zig codegen**: Implement in `codegen/zig.nim`. See `codegen/zig_test.nim` PASS.
7. **Nim codegen**: Implement in `codegen/nim.nim`. See `codegen/nim_test.nim` PASS.
8. **Run ALL tests**: All 3 codegen unit tests AND all backend integration tests must pass. No lang can be skipped.
9. **Mark done**: Update the `[ ]` to `[x]` in all three `doc/all.*` files.

## Rules

- ALL THREE LANGUAGES must have codegen unit tests. No lang is exempt.
- A feature is NOT done until c_test, zig_test, AND nim_test all pass for it.
- The codegen tests run BEFORE the backend tests in `tests.sh`.

## Rules

- NEVER implement a feature in one backend without the others.
- Test cases are shared — one `input.nim` produces expected output for every target language.
- The converter (`ast/convert.nim`) is backend-agnostic. It produces astTF. Backends consume astTF.
- East-const rule applies to all C output (`int const`, not `const int`).
- Zig output must pass `zig fmt` (when format is active).
- C output must pass `clang-format -i` (when format is active).

## Current features

- [x] Variable: let (const in C, const in Zig)
- [x] Variable: var (mutable in C, var in Zig)
- [x] Variable: exported (no static in C, pub in Zig)
- [x] Procedure: forward declaration (signature only, no body)
- [x] Procedure: body (return statement, expressions)
- [x] Statement: discard ((void) in C, _ = in Zig)
- [x] Expressions: binary operators (div, mod, shl, shr, xor, and, or, not)
- [x] Expressions: function calls
- [ ] Types: type declarations (struct/object)
- [ ] Control flow: if/else
- [ ] Control flow: while
