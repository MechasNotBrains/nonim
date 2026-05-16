# Renderer Bug: nkImportExceptStmt except-list wraps to indent 0

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkImportExceptStmt`
node with identifiers long enough to exceed the line width, the except-list wraps to column 0
instead of maintaining proper indentation. This produces code with invalid indentation that
the parser rejects.

The bug only manifests when the combined length of the module name, alias, and except entries
exceeds the renderer's line width threshold, forcing a line break.

## Rendered output vs expected

```nim
# Rendered (invalid):
import ceHayJAx5uAuQmkoT7IRqTQvhEwryaoSGaRkeSxIOPmMf2a759xkZwBTXZuSsiG as
    XX3EwzXR0HaMMJQsJcyOe9zOe except
JCceOSLi1v87ryBcX2HoikN0tyII3ObKXaDSmeFW8Gx68vs57DtWaYp0m8Xd1,
XTiZs1sprYOqQVHmUTZ7Y7O

# Expected (valid):
import ceHayJAx5uAuQmkoT7IRqTQvhEwryaoSGaRkeSxIOPmMf2a759xkZwBTXZuSsiG as
    XX3EwzXR0HaMMJQsJcyOe9zOe except
    JCceOSLi1v87ryBcX2HoikN0tyII3ObKXaDSmeFW8Gx68vs57DtWaYp0m8Xd1,
    XTiZs1sprYOqQVHmUTZ7Y7O
```

The except identifiers at column 0 are parsed as new top-level statements, producing
"invalid indentation" errors.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random import-except statements and writes output to `fuzz_output.nim`

## Hypothesis

The `gcommaAux` call for the except-list uses `g.indent` as the wrap indent, which is 0
for top-level statements. When a line break is needed, identifiers wrap to that column
instead of indenting relative to the `import` keyword or the `except` keyword.
