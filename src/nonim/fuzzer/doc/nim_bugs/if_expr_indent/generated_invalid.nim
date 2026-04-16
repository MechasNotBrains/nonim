# Invalid code produced by the renderer:
# elif/else branches are at the proc body indent, not inside the call.

proc bar() =
  let x = foo(if cond1: 1
  elif cond2:
    2
  else:
    3
  )
