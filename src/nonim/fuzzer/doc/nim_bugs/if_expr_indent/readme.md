# Renderer Bug: nkIfExpr elif/else branches render at outer indent level

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkIfExpr` node
that is nested inside another expression (e.g. a call argument inside a proc body), the
`elif` and `else` branches are rendered at the outer scope's indent level rather than
matching the context of the `if`. This produces code with invalid indentation that the
parser rejects.

## Rendered output vs expected

```nim
# Rendered (invalid):
proc bar() =
  let x = foo(if cond1: 1
  elif cond2:
    2
  else:
    3
  )

# Expected (valid):
proc bar() =
  let x = foo(if cond1: 1
              elif cond2: 2
              else: 3)
```

The `elif` at column 2 is at the `let` statement's indent, not inside the call
parentheses where the `if` started. The parser reads `elif` as a new statement
at the proc body level and rejects it.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random if-expressions in nested contexts and writes output to `fuzz_output.nim`

## Hypothesis

The renderer uses `optNL(g)` to emit newlines before `elif`/`else` branches, which outputs
at `g.indent` — the current global indent level. When the if-expression is nested inside
another construct, `g.indent` reflects the outer scope rather than the local expression
context, so branches are dedented relative to where the `if` keyword appeared.
