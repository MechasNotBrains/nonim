# Renderer Bug: nkPragmaExpr closing `.}` clashes with dot-access suffix

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkPragmaExpr`
node that is followed by a dot access (`nkDotExpr`), the pragma closing `.}` is
immediately followed by `.field`, producing `.}.field` which the parser rejects.

## Rendered output vs expected

```nim
# Rendered (invalid):
foo {.inline.}.bar

# Expected (valid):
(foo {.inline.}).bar
```

The parser reads `.}.` as an invalid token sequence — it sees the pragma close `.}`,
then the unexpected `.` which it cannot parse in that context.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random pragma expressions in dot-access contexts and writes output to `fuzz_output.nim`

## Hypothesis

The renderer outputs the pragma closing token `.}` and then immediately renders the dot
access `.field` without any separating space or parentheses. The lexer/parser cannot
distinguish `.}` followed by `.field` from a malformed token sequence.
