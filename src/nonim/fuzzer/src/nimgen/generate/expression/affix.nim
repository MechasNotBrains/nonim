#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../expression
import ../identifier


#_______________________________________
# @section Expression.Affix Generation: prefix
#_____________________________
func prefix *(
    info  : TLineInfo;
    op    : string = R.operator();
    left  : PNode  = expression.random(info);
  ) :PNode=
  result = newNodeI(nkPrefix, info)
  result.add(identifier.node(info, op))
  result.add(left)


#_______________________________________
# @section Expression.Affix Generation: postfix
#_____________________________
func postfix *(
    info  : TLineInfo;
    op    : string = R.operator();
    right : PNode  = expression.random(info);
  ) :PNode=
  result = newNodeI(nkPostfix, info)
  result.add(identifier.node(info, op))
  result.add(right)


#_______________________________________
# @section Expression.Affix Generation: infix
#_____________________________
func infix *(
    info  : TLineInfo;
    op    : string = R.operator();
    left  : PNode  = expression.random(info);
    right : PNode  = expression.random(info);
  ) :PNode=
  result = newNodeI(nkInfix, info)
  result.add(identifier.node(info, op))
  result.add(left)
  result.add(right)


#_______________________________________
# @section Expression.Affix Generation: Entry Point
#_____________________________
func random *(
    info  : TLineInfo;
    op    : string = R.operator();
  ) :PNode=
  case R.integer(2)
  of 1: affix.prefix(info, op)
  of 2: affix.postfix(info, op)
  else: affix.infix(info, op)

