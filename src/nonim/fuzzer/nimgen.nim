#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
from std/os import commandLineParams


#_______________________________________
# @section nim.gen Library API
#_____________________________


#_______________________________________
# @section nim.gen Entry Point
#_____________________________
when isMainModule:
  from ./nimgen/cli import nil
  cli.run(os.commandLineParams())

