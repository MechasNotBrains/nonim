#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
#_______________________________________
# @section Base Types
#_____________________________
include ./strings/types
include ./numbers/types
include ./memory/types


#_______________________________________
# @section Containers
#_____________________________
include ./containers/types
include ./containers/iterators


# # @section Safety
# {.pragma: mmsafe, raises:[].}
# {.pragma: callback, cdecl, raises: [], gcsafe.}
# type DoesAlloc * = object of RootEffect
# {.pragma: noalloc, forbids: [DoesAlloc].}



# proc allocImpl(size: int): pointer {.exportc: "malloc".} =
#   # log, crash, or forward — your choice

proc printf *(format :cstring) {.importc, varargs, header: "<stdio.h>".}

proc echo *(args :varargs[cstring]) :void=
  for arg in args: printf("%s", arg)
  printf("\n")

const isMainModule *{.magic: "IsMainModule".} :bool= false

