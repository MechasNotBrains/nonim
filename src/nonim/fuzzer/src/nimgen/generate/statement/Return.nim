#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../expression/literal


proc random *(
    info : TLineInfo;
    T    : string= R.typename()
  ) :PNode=
  result = newNodeI(nkReturnStmt, info)
  result.add(literal.random(T))

