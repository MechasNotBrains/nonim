# Renderer Bug: Form feed character (`\x0C`) in comment causes renderTree to hang

## Summary

When the Nim compiler's AST renderer (`compiler/renderer.nim`) encounters a form feed
character (`\x0C`, ASCII 12) inside a comment node's text, `renderTree` enters an infinite
loop and never returns.

## Affected characters

Any character with ASCII value in the range `\x01`..`\x08` or `\x0B`..`\x0C` or `\x0E`..`\x1F`
will trigger this bug — specifically, any character that is:
- Greater than `\0` (so the null terminator check doesn't catch it)
- Not `\r` (0x0D) or `\n` (0x0A) (handled as newlines)
- Not `\t` (0x09) or space (0x20) (handled as whitespace)
- Less than or equal to `' '` (0x20) (so neither the word loop nor the whitespace cases advance past it)

The form feed `\x0C` is the most common of these in practice.

## Reproduction

See the files in this directory:
- `render.nim` — minimal reproduction that builds AST and renders it (**WARNING: will hang**)
- `generated_invalid.nim` — not applicable (no output is produced; the process hangs)
- `expected_valid.nim` — expected behavior: character stripped or escaped
- `fuzz.nim` + `fuzz.nims` — fuzzer that generates random comments with control characters (**WARNING: will hang without the workaround define**)

## Hypothesis

The `putComment` proc in the renderer iterates over comment characters in a `while` loop.
The `case` statement handles `\0`, `\r`, `\n`, `' '`, `\t`, and `else` (for printable chars).
The `else` branch has two inner loops that only advance past characters where `s[i] > ' '`.
A form feed (`\x0C`) is less than space, so neither loop advances `i`, and the outer
`while` repeats at the same position forever.
