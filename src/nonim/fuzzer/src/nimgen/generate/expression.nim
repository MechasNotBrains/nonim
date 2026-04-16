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
# @section Expression Generation: Parenthesized
#_____________________________
func par *(info :TLineInfo; inner :PNode= expression.random(info, depth= 1); depth :int= 0) :PNode=
  result = newNodeI(nkPar, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Dot Expression
#_____________________________
func dot *(info :TLineInfo; depth :int= 0) :PNode=
  result = newNodeI(nkDotExpr, info)
  result.add(expression.random(info, depth= depth + 1))
  result.add(identifier.random(info))


#_______________________________________
# @section Expression Generation: Call
#_____________________________
func arguments *(info :TLineInfo; count :int= R.integer(16); depth :int= 0) :seq[PNode]=
  let limit = max(0, count div max(1, depth))
  for _ in 0..<limit:
    result.add(expression.random(info, depth= depth + 1))
#___________________
func call *(info :TLineInfo; depth :int= 0; args :seq[PNode]= expression.arguments(info, depth= depth)) :PNode=
  result = newNodeI(nkCall, info)
  result.add(identifier.random(info))
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Acc Quoted
#_____________________________
func quoted *(info :TLineInfo; inner :PNode= identifier.random(info)) :PNode=
  result = newNodeI(nkAccQuoted, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Deref
#_____________________________
func deref *(info :TLineInfo; inner :PNode= expression.random(info)) :PNode=
  result = newNodeI(nkDerefExpr, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Addr
#_____________________________
func Addr *(info :TLineInfo; inner :PNode= expression.random(info)) :PNode=
  result = newNodeI(nkAddr, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Entry Point
#_____________________________
func random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode=
  if depth >= MaxDepth:
    result = literal.random(T)
  else:
    result = case R.integer(7)
    of 1: identifier.random(info)
    of 2: expression.par(info, depth= depth)
    of 3: expression.dot(info, depth)
    of 4: expression.call(info, depth= depth)
    of 5: expression.quoted(info)
    of 6: expression.deref(info, expression.random(info, depth= depth + 1))
    of 7: expression.Addr(info, expression.random(info, depth= depth + 1))
    # TODO: Wire in affix expressions once operator rendering is fixed
    else: literal.random(T)
