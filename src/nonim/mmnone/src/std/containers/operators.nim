#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________
proc len  *[T](x :openArray[T]) :int {.magic: LengthOpenArray.}
proc `[]` *[T](x :openArray[T]; index :int) :T {.magic: ArrGet.}

