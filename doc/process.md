# Feature Process

Every new feature must be implemented across all backends simultaneously.
No backend progresses without the others having parity.

## Steps

1. **Track the feature**: Add the syntax construct to `doc/all.nim`, `doc/all.c`, and `doc/all.zig` marked as `[ ]`.
2. **Test case first**: Create `src/nonim/backend/test/cases/<name>/input.nim` with the Nim source.
3. **Expected outputs**: Create `expected.c`, `expected.zig`, and `expected.nim` in the same directory.
4. **Add test assertions**: Add the test to `backend/test/cleanc.nim` and `backend/test/zig.nim`.
5. **Converter**: If the feature requires a new PNode kind, implement it in `ast/convert.nim`.
6. **C codegen**: Implement in `codegen/C.nim`.
7. **Zig codegen**: Implement in `codegen/zig.nim`.
8. **Nim codegen**: Verify the existing nim codegen handles it (it usually already does via slate).
9. **Run all tests**: All three backends must pass before the feature is considered done.
10. **Mark done**: Update the `[ ]` to `[x]` in all three `doc/all.*` files.

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
- [ ] Procedure: body (return statement, expressions)
- [ ] Expressions: binary operators (+, -, *, /)
- [ ] Expressions: function calls
- [ ] Types: type declarations (struct/object)
- [ ] Control flow: if/else
- [ ] Control flow: while
