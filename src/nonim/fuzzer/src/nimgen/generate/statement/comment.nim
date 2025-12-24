#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos, renderer ]
# @deps nim.gen
import ../../random as R


#___________________
func contents *(len :int) :string=
  result = ""
  for _ in 1..len: result.add(R.char[system.char]())
#___________________
func random *(
    info : TLineInfo;
    len  : int = R.integer(1..255);
  ) :PNode=
  result = newNodeI(nkCommentStmt, info)
  {.cast(noSideEffect).}: # Adding comments to nodes is safe
    ast.`comment=`(result, comment.contents(len))
    debugEcho "........................................."
    debugEcho $result
    debugEcho "........................................."

