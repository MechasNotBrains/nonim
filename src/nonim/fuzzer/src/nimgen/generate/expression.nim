#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ../typetools
import ./expression/literal
import ./identifier


const MaxDepth * = 4

func random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode


#_______________________________________
# @section Expression Generation: Affix
#_____________________________
func prefix *(
    info : TLineInfo;
    op   : string = R.operator();
    left : PNode;
  ) :PNode=
  result = newNodeI(nkPrefix, info)
  result.add(identifier.node(info, op))
  result.add(left)
#___________________
func postfix *(
    info  : TLineInfo;
    op    : string = R.operator();
    right : PNode;
  ) :PNode=
  result = newNodeI(nkPostfix, info)
  result.add(identifier.node(info, op))
  result.add(right)
#___________________
func infix *(
    info  : TLineInfo;
    op    : string = R.operator();
    left  : PNode;
    right : PNode;
  ) :PNode=
  result = newNodeI(nkInfix, info)
  result.add(identifier.node(info, op))
  result.add(left)
  result.add(right)
#___________________
func affix *(info :TLineInfo; depth :int= 0) :PNode=
  case R.integer(2)
  of 1: expression.prefix(info,  left=  expression.random(info, depth= depth + 1))
  of 2: expression.postfix(info, right= expression.random(info, depth= depth + 1))
  else: expression.infix(info,
    left=  expression.random(info, depth= depth + 1),
    right= expression.random(info, depth= depth + 1))


#_______________________________________
# @section Expression Generation: Entry Point
#_____________________________
func random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode=
  if depth >= MaxDepth:
    result = literal.random(T)
  else:
    result = case R.integer(2)
    of 1: identifier.random(info)
    of 2:
      let inner = newNodeI(nkPar, info)
      inner.add(expression.random(info, T, depth + 1))
      inner
    # TODO: Wire in affix expressions once operator rendering is fixed
    else: literal.random(T)
