#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import commandLineParams
from std/paths import Path
# @deps nimc
import ./nimc/Untyped as nimc


#_______________________________________
# @section nim.check Entry Point
#_____________________________
proc code *(src  :string) :void= discard nimc.compile(src)
proc file *(path :string) :void= discard nimc.readAST(path.Path)
#___________________
when isMainModule:
  type NimCheckError = object of CatchableError
  let args :seq[string]= os.commandLineParams()
  if args.len != 1: raise newException(NimCheckError, "Invalid number of arguments. Usage:\n  nimcheck file.nim")
  nimcheck.file(args[0])

