from ./operators          as container_operators import len, `[]`
from ../numbers/operators as number_operators    import `<`, inc

iterator items *[T](a :openArray[T]) :T {.inline.}=
  var index = 0
  while index < a.len:
    yield a[index]
    index.inc

