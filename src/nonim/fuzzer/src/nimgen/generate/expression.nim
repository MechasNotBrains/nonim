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


const MaxDepth * = 3

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
func eq *(
    info  : TLineInfo;
    depth : int   = 0;
    name  : PNode = identifier.random(info);
    value : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkExprEqExpr, info)
  result.add(name)
  result.add(value)
#___________________
func arguments *(
    info  : TLineInfo;
    count : int  = R.integer(10);
    depth : int  = 0;
    named : bool = false;
  ) :seq[PNode]=
  let limit = max(0, count div max(1, depth))
  for _ in 0..<limit:
    if named and R.bool(): result.add(expression.eq(info, depth= depth))
    else:                  result.add(expression.random(info, depth= depth + 1))
#___________________
func call *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = expression.arguments(info, depth= depth, named= true);
  ) :PNode=
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
# @section Expression Generation: Bracket Expression (Indexed Access)
#_____________________________
func arrayAccess *(
    info  : TLineInfo;
    ident : PNode = identifier.random(info);
    index : PNode = expression.random(info);
  ) :PNode=
  result = newNodeI(nkBracketExpr, info)
  result.add(ident)
  result.add(index)


#_______________________________________
# @section Expression Generation: Call String Literal
#_____________________________
func callStrLit *(
    info : TLineInfo;
    name : PNode = identifier.random(info);
    str  : PNode = literal.string(kind= nkRStrLit);
  ) :PNode=
  result = newNodeI(nkCallStrLit, info)
  result.add(name)
  result.add(str)


#_______________________________________
# @section Expression Generation: Range
#_____________________________
func Range *(
    info  : TLineInfo;
    depth : int   = 0;
    left  : PNode = expression.random(info, depth= depth + 1);
    right : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  # @workaround nkRange renderer bug: outputs `left..right` without spaces,
  #   so negative right side like `X..-128'i8` lexes as operator `..-`. See: renderer.nim
  result = newNodeI(nkRange, info)
  result.add(left)
  when defined(NimCompilerBug_RangeNoSpaces):
    result.add(right)
  else:
    let rightPar = newNodeI(nkPar, info)
    rightPar.add(right)
    result.add(rightPar)


#_______________________________________
# @section Expression Generation: Bracket (Array Constructor)
#_____________________________
func bracket *(
    info  : TLineInfo;
    depth : int       = 0;
    args  : seq[PNode] = expression.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkBracket, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Curly (Set Constructor)
#_____________________________
func curly *(
    info  : TLineInfo;
    depth : int       = 0;
    args  : seq[PNode] = expression.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkCurly, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Tuple Constructor
#_____________________________
func Tuple *(
    info  : TLineInfo;
    depth : int       = 0;
    args  : seq[PNode] = expression.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkTupleConstr, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Expr Colon Expr (Named Parameter)
#_____________________________
func exprColonExpr *(
    info  : TLineInfo;
    depth : int   = 0;
    name  : PNode = identifier.random(info);
    value : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkExprColonExpr, info)
  result.add(name)
  result.add(value)


#_______________________________________
# @section Expression Generation: Object Constructor
#_____________________________
func fields *(
    info  : TLineInfo;
    count : int = R.integer(10);
    depth : int = 0;
  ) :seq[PNode]=
  let limit = max(0, count div max(1, depth))
  for _ in 0..<limit:
    result.add(expression.exprColonExpr(info, depth= depth + 1))
#___________________
func Object *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = expression.fields(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkObjConstr, info)
  result.add(identifier.random(info))
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Table Constructor
#_____________________________
func table *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = expression.fields(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkTableConstr, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Cast
#_____________________________
func Cast *(
    info  : TLineInfo;
    depth : int    = 0;
    T     : string = R.typename();
    inner : PNode  = expression.random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkCast, info)
  result.add(identifier.typ(info, T))
  result.add(inner)


#_______________________________________
# @section Expression Generation: Static
#_____________________________
func Static *(
    info  : TLineInfo;
    depth : int   = 0;
    inner : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  # @workaround nkStaticExpr renderer bug: renders `static EXPR` without parens,
  #   parser rejects keyword-exprs (addr, not, if) after `static`. See: renderer.nim:1874
  let innerPar = newNodeI(nkPar, info)
  innerPar.add(inner)
  let staticNode = newNodeI(nkStaticExpr, info)
  when defined(NimCompilerBug_StaticExprIndent):
    staticNode.add(inner)
    result = staticNode
  else:
    staticNode.add(innerPar)
    result = newNodeI(nkPar, info)
    result.add(staticNode)


#_______________________________________
# @section Expression Generation: If Expression
#_____________________________
func Elif *(
    info  : TLineInfo;
    depth : int   = 0;
    cond  : PNode = expression.random(info, depth= depth + 1);
    value : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkElifExpr, info)
  result.add(cond)
  result.add(value)
#___________________
func Else *(
    info  : TLineInfo;
    depth : int   = 0;
    value : PNode = expression.random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkElseExpr, info)
  result.add(value)
#___________________
func branches *(
    info     : TLineInfo;
    count    : int  = R.integer(1..4);
    depth    : int  = 0;
    withElse : bool = R.bool();
  ) :seq[PNode]=
  for _ in 0..<count: result.add(expression.Elif(info, depth= depth))
  if withElse: result.add(expression.Else(info, depth= depth))
#___________________
func If *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = expression.branches(info, depth= depth);
  ) :PNode=
  # @workaround nkIfExpr renderer bug: multi-line elif/else at outer indent
  #   breaks parsing in sub-expression contexts. See: renderer.nim:771-781
  let ifNode = newNodeI(nkIfExpr, info)
  for arg in args: ifNode.add(arg)
  when defined(NimCompilerBug_IfExprIndent):
    result = ifNode
  else:
    result = newNodeI(nkPar, info)
    result.add(ifNode)


#_______________________________________
# @section Expression Generation: Entry Point
#_____________________________
func random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode=
  if depth >= MaxDepth:
    result = literal.random(T)
  else:
    result = case R.integer(18)
    of 1: identifier.random(info)
    of 2: expression.par(info, depth= depth)
    of 3: expression.dot(info, depth)
    of 4: expression.call(info, depth= depth)
    of 5: expression.quoted(info)
    of 6: expression.deref(info, expression.random(info, depth= depth + 1))
    of 7: expression.Addr(info, expression.random(info, depth= depth + 1))
    of 8: expression.arrayAccess(info)
    of 9: expression.callStrLit(info)
    of 10: expression.Range(info, depth= depth)
    of 11: expression.bracket(info, depth= depth)
    of 12: expression.curly(info, depth= depth)
    of 13: expression.Tuple(info, depth= depth)
    of 14: expression.Cast(info, depth= depth)
    of 15: expression.Object(info, depth= depth)
    of 16: expression.table(info, depth= depth)
    of 17: expression.Static(info, depth= depth)
    of 18: expression.If(info, depth= depth)
    # TODO: Wire in affix expressions once operator rendering is fixed
    else: literal.random(T)
