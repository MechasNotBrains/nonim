#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
proc len  *[T](x :openArray[T]) :int {.magic: LengthOpenArray.}
proc `[]` *[T](x :openArray[T]; index :int) :T {.magic: ArrGet.}

