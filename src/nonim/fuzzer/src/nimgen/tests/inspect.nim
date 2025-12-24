#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps nim.gen
from ../nimc as nim import treeRepr


#_______________________________________
# @section Inspect: Source Code
#_____________________________
const src = """
## toplevel comment
var one = 1 ## endofline comment
var two = 2
  ## doc comment

##[ inline comment as statement ]##
var ##[ an inline comment ]## thr :int= 2
"""
const src2 = """
#:____________________________________________
##  tiny.nim  |  Example Syntax  |  CC0-1.0  :
#:____________________________________________
# Include any C header natively
include stdint.h

# Toplevel variable declaration
var x :int32_t= 0

# Function Definition
proc everything () :int32_t=
  # Array Definition
  var arr :array[1, int]= [42]

  # Variable declaration with assignment
  var y :int= 0

  # Looping
  while 1:
    # Variable Assignment
    x = x + 2
    x = x - 1

    # Array Indexing
    arr[x] = y
    y = arr[x]

    # Conditionals
    if x == 21:
      continue
    if x == 42:
      break
    if x != 42:
      y = y + 1

  # Return statement
  return arr[0]

# Application Entry Point
proc main *() :int32_t=
  return everything()
"""


#_______________________________________
# @section Inspect: Entry Point
#_____________________________
when isMainModule:
  from "$nim"/compiler/renderer import renderTree, renderNoPragmas
  from "$nim"/compiler/ast import comment

  # Report to CLI and exit
  debugEcho "____ AST Inspector: _____________________________________"
  debugEcho nim.getAST(src, "inspect.src").treeRepr()
  debugEcho "___________________________"
  debugEcho renderTree(nim.getAST(src, "inspect.src"), {renderNoPragmas})
  debugEcho "___________________________"
  debugEcho nim.getAST(src, "inspect.src").sons[0].comment
  debugEcho "_________________________________________________________"

