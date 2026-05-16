# Invalid code produced by the renderer:
# Parser rejects newline-separated statements inside parentheses.

var x = 0
let y = (
  x = 10
  x)
