#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../expression
import ./comment as Comment


func random *(
    info   : TLineInfo;
    cmment : bool = R.bool();
  ) :PNode=
  result = newNodeI(nkDiscardStmt, info)
  if R.bool() : result.add(expression.random(info))
  else        : result.add(newNodeI(nkEmpty, info))
  if cmment: result.addComment()
