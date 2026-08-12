type Type [T] = object
  data    :T
  process {.generic.}= proc (P :var ptr Type[T]) :void=
    if P.data.valid():
      P.one()
    elif P.data.stored() as fallback:
      P.two(fallback)
    else:
      P.three()
