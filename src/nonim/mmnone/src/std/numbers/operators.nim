proc `<`  *(x, y :int) :bool {.magic: LtI, noSideEffect.}
proc inc  *[T :Ordinal, V :SomeInteger](x :var T, y :V= 1) {.magic: Inc, noSideEffect.}

