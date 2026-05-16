# Invalid code produced by the renderer:
# The `..` operator has no spaces, causing `..-` to lex as a single operator.

let x = 0..-128'i8
let y = 10..-1'i16
