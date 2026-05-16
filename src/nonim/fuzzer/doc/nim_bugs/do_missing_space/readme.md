# Renderer Bug: Missing space before `do` keyword in nkCall with nkDo children

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkCall` node
that contains `nkDo` children, it omits the required space before the `do` keyword.
This produces unparseable output like `foodo` or `sort(cities)do`.

## Rendered output vs expected

**With arguments:**
```nim
# Rendered (invalid):
sort(cities)do (x, y: string) -> int:
  discard

# Expected (valid):
sort(cities) do (x, y: string) -> int:
  discard
```

**Without arguments:**
```nim
# Rendered (invalid):
foodo:
  discard

# Expected (valid):
foo do:
  discard
```

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` — fuzzer that generates random nkCall+nkDo trees and writes output to `fuzz_output.nim`

## Hypothesis

The `postStatements` proc in `renderer.nim` appears to only insert a space before the `do`
keyword when the first post-expression child is `nkStmtList`. When the child is `nkDo` instead,
no space is emitted before delegating to the `nkDo` rendering handler, which adds a space
*after* the keyword but not before it.
