#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
from   "$nim"/compiler/renderer import renderTree, renderNoPragmas


#_______________________________________
# @section AST Render tools
#_____________________________
type RootData * = tuple[node :PNode, info :TLineInfo]
func Const *(root :RootData) :string=
  result = ""
  debugEcho "........................."
  for entry in root.node[0].sons:
    debugEcho entry.repr
#___________________
proc code *(
    root        : RootData;
    allowBlocks : bool = true;
  ) :string=
  result = renderTree(root.node, {renderNoPragmas})
