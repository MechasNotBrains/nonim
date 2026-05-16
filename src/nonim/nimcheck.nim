#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
from std/os import commandLineParams
from std/paths import Path
# @deps nim.gen
import ./nimc


#_______________________________________
# @section nim.check Entry Point
#_____________________________
proc file *(path :string) :void= discard nimc.readAST(path.Path)
#___________________
when isMainModule:
  type NimCheckError = object of CatchableError
  let args :seq[string]= os.commandLineParams()
  if args.len != 1: raise newException(NimCheckError, "Invalid number of arguments. Usage:\n  nimcheck file.nim")
  nimcheck.file(args[0])

