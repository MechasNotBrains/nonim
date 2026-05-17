#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ./expression_literal as literal


func random *(
    info : TLineInfo;
    T    : string= R.typename()
  ) :PNode=
  result = newNodeI(nkReturnStmt, info)
  result.add(literal.random(T))

