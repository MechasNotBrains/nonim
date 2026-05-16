proc len  *[T](x :openArray[T]) :int {.magic: LengthOpenArray.}
proc `[]` *[T](x :openArray[T]; index :int) :T {.magic: ArrGet.}

