# Invalid code produced by the renderer:
# The `.}` closing clashes with the `.bar` dot access.

let x = foo {.inline.}.bar
let y = baz {.noSideEffect.}.qux
