#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ./shared


#___________________
func contents *(len :int = R.integer(1..255)) :string=
  result = ""
  for _ in 1..len: result.add(R.sample(VisibleChars))
#___________________
func addComment *(node :PNode) =
  {.cast(noSideEffect).}: # Adding comments to nodes is safe
    node.comment = statement_comment.contents()
#___________________
func random *(
    info : TLineInfo;
    len  : int = R.integer(1..255);
  ) :PNode=
  result = newNodeI(nkCommentStmt, info)
  {.cast(noSideEffect).}: # Adding comments to nodes is safe
    ast.`comment=`(result, statement_comment.contents(len))

