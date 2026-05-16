#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
proc `<`  *(x, y :int) :bool {.magic: LtI, noSideEffect.}
proc inc  *[T :Ordinal, V :SomeInteger](x :var T, y :V= 1) {.magic: Inc, noSideEffect.}

