type Type [T] = object
  data    :T
  create {.generic.}= proc (val :T) :Type[T]=
    var thing = val
    thing += 1
    return (data: thing)
  get {.generic.}= proc (S :ptr Type[T]) :T=
    return S.data
