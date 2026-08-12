type Type [T] = object
  data    :T
  scalar {.generic.}= proc (P :var ptr Type[T]; F :typedesc) :F=
    case @typeInfo(F)
    of .int : return try: std.fmt.parseInt(F, P.data, 0) except: 0
    else    : return P.data

type Error = object
  id    :int
