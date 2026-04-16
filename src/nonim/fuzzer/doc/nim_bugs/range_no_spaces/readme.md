# Renderer Bug: nkRange renders `..` without spaces, causing `..-` to lex as a single operator

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkRange` node,
it outputs `left..right` without any spaces around the `..` operator. When the right-hand
side is a negative literal (e.g. `-128'i8`), the lexer reads `..-` as a single operator token
instead of `..` followed by a unary minus, producing unparseable output.

## Rendered output vs expected

**Negative right side (broken):**
```nim
# Rendered (invalid):
0..-128'i8

# Expected (valid):
0 .. -128'i8
```

**Positive right side (happens to work):**
```nim
# Rendered (valid by accident):
0..127'i8

# The lack of spaces doesn't break here because `..1` isn't a valid operator token.
```

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random range expressions and writes output to `fuzz_output.nim`

## Hypothesis

The `nkRange` handler in the renderer outputs `..` via `put(g, tkDotDot, "..")` with no surrounding
spaces. The issue only manifests when the right operand starts with `-`, because the lexer
greedily tokenizes `..-` as a single dot-like operator.
