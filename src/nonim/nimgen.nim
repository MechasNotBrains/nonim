#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import commandLineParams
#_____________________________
# @section nim.gen Entry Point
when isMainModule:
  from ./fuzzer/cli import nil
  cli.run(os.commandLineParams())
