#______________________________________
# @section Helpers
#____________________________
proc sum_forward (T :typedesc; vals :array[_, T]) :T {.private.}=
  var result :T= 0.0
  for val in vals: result += val
  return result

