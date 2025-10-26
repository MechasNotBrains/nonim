#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ./statement/procedure
import ./statement/variable
import ./statement/call


const Nodes_all * = ["variable", "proc", "call"]


func random *(
    info : TLineInfo;
    kind : string = R.sample(Nodes_all);
  ) :PNode=
  return case kind
  of "variable" : variable.random(info)
  of "proc"     : procedure.random(info)
  of "call"     : call.random(info)
  else:nil # unreachable

