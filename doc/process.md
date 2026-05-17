# Feature Process

Every new feature must be implemented across all backends simultaneously.
No backend progresses without the others having parity.

## Steps

1. **Test case first**: Create `src/nonim/backend/test/cases/<name>/input.nim` with the Nim source.
2. **Expected outputs**: Create `expected.c`, `expected.zig`, and `expected.nim` in the same directory.
3. **Add test assertions**: Add the test to `backend/test/cleanc.nim` and `backend/test/zig.nim`.
4. **Converter**: If the feature requires a new PNode kind, implement it in `ast/convert.nim`.
5. **C codegen**: Implement in `codegen/C.nim`.
6. **Zig codegen**: Implement in `codegen/zig.nim`.
7. **Nim codegen**: Verify the existing nim codegen handles it (it usually already does via slate).
8. **Run all tests**: All three backends must pass before the feature is considered done.

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
