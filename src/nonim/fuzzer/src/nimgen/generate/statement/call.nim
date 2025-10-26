#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../identifier
import ../expression


proc random *(
    info : TLineInfo;
    name : string = identifier.name();
    args : int    = R.integer(16)
  ) :PNode=
  result = newNodeI(if R.bool(): nkCall else: nkCommand, info)
  result.add(identifier.random(info))
  for _ in 0..<args: result.add(expression.random(info))

