#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps nim.gen
from ../nimc as nim import treeRepr


#_______________________________________
# @section Inspect: Source Code
#_____________________________
const src = """
thing(0;1,2,3,4,5,6,7,8,9)
"""


#_______________________________________
# @section Inspect: Entry Point
#_____________________________
when isMainModule:
  # Report to CLI and exit
  debugEcho "____ AST Inspector: _____________________________________"
  debugEcho nim.getAST(src, "inspect.src").treeRepr()
  debugEcho "_________________________________________________________"

