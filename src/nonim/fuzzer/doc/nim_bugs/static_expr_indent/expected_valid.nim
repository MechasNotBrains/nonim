# Corrected version of the renderer output:
# Inner expression wrapped in parens to avoid keyword ambiguity.

var x = 10
let a = (static(addr(x)))
let b = (static(not true))
