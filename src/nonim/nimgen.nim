#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
from std/os import commandLineParams
#_____________________________
# @section nim.gen Entry Point
when isMainModule:
  from ./fuzzer/cli import nil
  cli.run(os.commandLineParams())
