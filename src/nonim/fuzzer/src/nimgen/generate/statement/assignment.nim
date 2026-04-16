#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../identifier
import ../expression
import ./call


#_______________________________________
# @section Statement.Assignment Generation
#_____________________________
func node *(
    info  : TLineInfo;
    name  : string;
    value : PNode;
  ) :PNode=
  ## Generates a `name = value` assignment node
  result = newNodeI(nkAsgn, info)
  result.add(identifier.node(info, name))
  result.add(value)
#___________________
func defaultResult *(
    info : TLineInfo;
    T    : string;
  ) :PNode=
  ## Generates a `result = default(T)` assignment node
  result = assignment.node(info, "result", call.node(info, "default", [identifier.node(info, T)]))
#___________________
func random *(info : TLineInfo) :PNode=
  ## Generates a `??random?? = ??random??` assignment node
  result = assignment.node(info, identifier.name(), expression.random(info))

