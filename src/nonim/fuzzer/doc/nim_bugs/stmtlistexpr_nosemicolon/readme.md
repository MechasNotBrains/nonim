# Renderer Bug: nkStmtListExpr inside nkPar renders with newlines instead of semicolons

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkStmtListExpr`
node inside an `nkPar` node, it outputs statements separated by newlines. The parser
requires semicolons between statements inside parentheses, so the rendered code is rejected
with `expected: ')', but got: ...`.

## Rendered output vs expected

```nim
# Rendered (invalid):
let y = (
  x = 10
  x)

# Expected (valid):
let y = (x = 10; x)
```

The parser reads `(` and expects either `)` or a semicolon-separated expression list,
but encounters a newline followed by a new statement which it cannot parse in that context.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` — fuzzer that generates random stmtListExpr nodes and writes output to `fuzz_output.nim`

## Hypothesis

The `gstmts` procedure in the renderer handles `nkStmtListExpr` with `optNL` (newlines)
between children, which is correct at the top level but incorrect inside parenthesized
contexts. The `gcond` procedure already special-cases `nkStmtListExpr` by wrapping it in
parens, but this does not help when `nkStmtListExpr` appears as a child of `nkPar` directly.
The renderer would need to detect when it is inside a parenthesized context and emit
semicolons instead of newlines between `nkStmtListExpr` children.
