#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps nim.gen
from ../nimc as nim import treeRepr


#_______________________________________
# @section Inspect: Source Code
#_____________________________
const src = """
import strutils
import strutils as str
import strutils except endsWith
from strformat import endsWith, startsWith
from strformat as fmt import nil
include file
"""


#_______________________________________
# @section Inspect: Entry Point
#_____________________________
when isMainModule:
  # Report to CLI and exit
  debugEcho "____ AST Inspector: _____________________________________"
  debugEcho nim.getAST(src, "inspect.src").treeRepr()
  debugEcho "_________________________________________________________"

