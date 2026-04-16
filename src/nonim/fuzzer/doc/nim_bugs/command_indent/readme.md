# Renderer Bug: nkCommand wraps long argument lists with invalid indentation

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkCommand` node
(call without parentheses) inside a nested context like a proc body, long argument lists
wrap to an indentation level that the parser rejects. The arguments are indented relative
to the command name rather than following the command call syntax rules.

## Rendered output vs expected

```nim
# Rendered (invalid):
proc bar() =
  someProcedureWithAVeryLongNameThatForcesWrapping
      aVeryLongIdentifierNameThatWillForceTheRendererToWrapToTheNextLine,
      anotherVeryLongIdentifierThatPushesEvenFurtherPastTheLineLimit

# Expected (valid):
proc bar() =
  someProcedureWithAVeryLongNameThatForcesWrapping aVeryLongIdentifierNameThatWillForceTheRendererToWrapToTheNextLine,
      anotherVeryLongIdentifierThatPushesEvenFurtherPastTheLineLimit
```

The parser sees the indented identifier on the next line as a new statement rather than
a continuation of the command call.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random command calls and writes output to `fuzz_output.nim`

## Hypothesis

The renderer wraps command arguments at a column offset relative to the command name,
but without parentheses the parser cannot distinguish the wrapped continuation from a
new indented statement. The bug only manifests when the command name plus first argument
exceeds the line width, forcing a line break before any argument is emitted.
