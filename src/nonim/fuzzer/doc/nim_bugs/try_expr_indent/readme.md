# Renderer Bug: nkTryStmt except/finally branches render at wrong indentation inside parentheses

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) renders an `nkTryStmt`
node inside parentheses (e.g. as a sub-expression), the `except` and `finally` branches
are rendered at the outer indentation level. The parser requires `except`/`finally` to
be at the same indentation as `try`, so the rendered code is rejected with
`expected 'except'`.

Unlike the similar `nkIfExpr` indentation bug, wrapping in `nkPar` does not help here —
multiline `try`/`except` inside parentheses fails regardless of indentation.

## Rendered output vs expected

```nim
# Rendered (invalid — except at wrong indent):
proc foo() =
  echo (try:
    42
  except:
    0
  )

# Expected (valid — single line, or block-wrapped):
proc foo() =
  echo (try: 42 except: 0)

# Alternative workaround (valid — block provides indentation context):
proc foo() =
  echo ((block:
    try:
      42
    except:
      0
  ))
```

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it
- `generated_invalid.nim` — example of invalid code produced by the renderer
- `expected_valid.nim` — corrected version of the same code
- `fuzz.nim` — fuzzer that generates random try expressions and writes output to `fuzz_output.nim`

## Hypothesis

The `gtry` procedure in the renderer uses `gstmts` for the body and `gsons` for the
remaining branches (except/finally), which emit `optNL` between children. Inside a
parenthesized context, this produces branches at the wrong indentation level. The `gblock`
procedure has the same issue, but block expressions can be wrapped in `nkPar` as a
workaround since the parser handles `(block: ...)` correctly. For `try`, the parser
requires `except`/`finally` to align with `try`, but the renderer does not indent them
relative to the opening paren.
