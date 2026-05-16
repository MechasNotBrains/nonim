# Corrected version of the renderer output:
# elif/else branches indented to match the if-expression context.

proc bar() =
  let x = foo(if cond1: 1
              elif cond2: 2
              else: 3)
