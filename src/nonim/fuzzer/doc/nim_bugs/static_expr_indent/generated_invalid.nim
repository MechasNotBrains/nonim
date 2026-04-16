# Invalid code produced by the renderer:
# Parser rejects keyword-expressions after `static` inside parens.

var x = 10
let a = (static addr(x))
let b = (static not true)
