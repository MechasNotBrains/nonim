# Renderer Bug: nkStaticExpr renders `static EXPR` without parenthesizing the inner expression

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkStaticExpr`
node, it outputs `static EXPR` without parenthesizing the inner expression. When `EXPR`
starts with a keyword (like `addr`, `not`, `if`), the parser rejects it inside
parenthesized contexts because it reads `static` as a type and then fails on the
unexpected keyword token.

## Rendered output vs expected

```nim
# Rendered (invalid inside parens):
(static addr(x))
(static not y)

# Expected (valid):
(static(addr(x)))
(static(not y))
```

The parser reads `(static` and expects either `)` or a type expression, but encounters
the keyword `addr` or `not` which is not valid in that position.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random static expressions and writes output to `fuzz_output.nim`

## Hypothesis

The `nkStaticExpr` handler in the renderer uses `putWithSpace` to emit `static` followed
by a space, then renders the inner expression directly. It does not wrap the inner
expression in parentheses, so keyword-expressions that follow `static` inside a
parenthesized context confuse the parser.
