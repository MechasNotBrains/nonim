type Holder [T] = object
  data    :T
  get {.generic.}= proc (S :ptr Holder[T]) :T=
    return S.data
