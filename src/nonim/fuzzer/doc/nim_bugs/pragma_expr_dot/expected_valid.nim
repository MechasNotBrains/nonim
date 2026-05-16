# Corrected version of the renderer output:
# Parentheses separate the pragma expression from the dot access.

let x = (foo {.inline.}).bar
let y = (baz {.noSideEffect.}).qux
