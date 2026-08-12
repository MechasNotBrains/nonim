type Type [T] = object
  result  :T
  process {.generic.}= proc (P :var ptr Type[T]) :void=
    for field {.inline.} in @typeInfo(T).struct.fields:
      discard field
      discard P
