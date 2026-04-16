#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
from std/strutils import replace
# @deps compiler
import "$nim"/compiler/[ ast, idents, options, lineinfos, msgs, pathutils ]
# @deps nim.gen
import ./random
import ./random as R
import ./typetools
import ./generate/shared
import ./generate/characters
import ./generate/identifier
import ./generate/expression_literal as literal
import ./generate/statement_comment
import ./generate/statement_return
import ./generate/render
export render


#_______________________________________
# @section RootData Generation
#_____________________________
proc root *(path :string) :RootData=
  let config  = newConfigRef()
  let absPath = AbsoluteFile(path)
  let info    = newLineInfo(config, absPath, 0, 0)
  let node    = newNodeI(nkStmtList, info)
  return (node:node, info:info)


#_______________________________________
# @section Expression Generation: Forward Declarations
#_____________________________
const ExprMaxDepth * = 3
func expression_random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode
func lambda *(info :TLineInfo; depth :int= 0) :PNode


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
  of 1: generate.prefix(info,  left=  generate.expression_random(info, depth= depth + 1))
  of 2: generate.postfix(info, right= generate.expression_random(info, depth= depth + 1))
  else: generate.infix(info,
    left=  generate.expression_random(info, depth= depth + 1),
    right= generate.expression_random(info, depth= depth + 1))


#_______________________________________
# @section Expression Generation: Parenthesized
#_____________________________
func par *(
    info  : TLineInfo;
    depth : int   = 0;
    inner : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkPar, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Dot Expression
#_____________________________
func dot *(info :TLineInfo; depth :int= 0) :PNode=
  result = newNodeI(nkDotExpr, info)
  result.add(generate.expression_random(info, depth= depth + 1))
  result.add(identifier.random(info))


#_______________________________________
# @section Expression Generation: Call Expression
#_____________________________
func eq *(
    info  : TLineInfo;
    depth : int   = 0;
    name  : PNode = identifier.random(info);
    value : PNode = generate.expression_random(info, depth= depth + 1);
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
    if named and R.bool(): result.add(generate.eq(info, depth= depth))
    else:                  result.add(generate.expression_random(info, depth= depth + 1))
#___________________
func expression_call *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = generate.arguments(info, depth= depth, named= true);
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
func deref *(
    info  : TLineInfo;
    depth : int   = 0;
    inner : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkDerefExpr, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Addr
#_____________________________
func Addr *(
    info  : TLineInfo;
    depth : int   = 0;
    inner : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkAddr, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Bind
#_____________________________
func Bind *(
    info  : TLineInfo;
    inner : PNode = identifier.random(info);
  ) :PNode=
  result = newNodeI(nkBind, info)
  result.add(inner)


#_______________________________________
# @section Expression Generation: Bracket Expression (Indexed Access)
#_____________________________
func arrayAccess *(
    info  : TLineInfo;
    depth : int   = 0;
    ident : PNode = identifier.random(info);
    index : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkBracketExpr, info)
  result.add(ident)
  result.add(index)


#_______________________________________
# @section Expression Generation: Curly Expression (Overloaded `{}` Operator)
#_____________________________
func curlyExpr *(
    info  : TLineInfo;
    depth : int       = 0;
    ident : PNode     = identifier.random(info);
    args  : seq[PNode] = generate.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkCurlyExpr, info)
  result.add(ident)
  for arg in args: result.add(arg)


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
    left  : PNode = generate.expression_random(info, depth= depth + 1);
    right : PNode = generate.expression_random(info, depth= depth + 1);
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
    args  : seq[PNode] = generate.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkBracket, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Curly (Set Constructor)
#_____________________________
func curly *(
    info  : TLineInfo;
    depth : int       = 0;
    args  : seq[PNode] = generate.arguments(info, depth= depth);
  ) :PNode=
  result = newNodeI(nkCurly, info)
  for arg in args: result.add(arg)


#_______________________________________
# @section Expression Generation: Tuple Constructor
#_____________________________
func Tuple *(
    info  : TLineInfo;
    depth : int       = 0;
    args  : seq[PNode] = generate.arguments(info, depth= depth);
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
    value : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkExprColonExpr, info)
  result.add(name)
  result.add(value)


#_______________________________________
# @section Expression Generation: Pragma Expression
#_____________________________
func pragmaValue *(info :TLineInfo) :PNode=
  if R.bool(): result = literal.random()
  else:        result = identifier.random(info)
#___________________
func pragmaEntry *(info :TLineInfo) :PNode=
  result = case R.integer(2)
  of 1: generate.exprColonExpr(info, value= generate.pragmaValue(info))
  of 2: generate.eq(info, value= generate.pragmaValue(info))
  else: identifier.random(info)
#___________________
func pragmaNode *(
    info  : TLineInfo;
    count : int  = R.integer(1..8);
    decl  : bool = false;
  ) :PNode=
  result = newNodeI(nkPragma, info)
  for _ in 0..<count:
    if decl: result.add(generate.pragmaEntry(info))
    else:    result.add(identifier.random(info))
#___________________
func pragma *(
    info  : TLineInfo;
    count : int   = R.integer(1..8);
    inner : PNode = identifier.random(info);
    decl  : bool  = false;
    wrap  : bool  = true;
  ) :PNode=
  # @workaround nkPragmaExpr renderer bug: `.}` closing clashes with dot-access
  #   suffix, producing `.}.` which the parser rejects. See: renderer.nim:1224-1226
  let pragmaExpr = newNodeI(nkPragmaExpr, info)
  pragmaExpr.add(inner)
  pragmaExpr.add(generate.pragmaNode(info, count= count, decl= decl))
  when defined(NimCompilerBug_PragmaExprDot):
    result = pragmaExpr
  else:
    if wrap:
      result = newNodeI(nkPar, info)
      result.add(pragmaExpr)
    else:
      result = pragmaExpr


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
    result.add(generate.exprColonExpr(info, depth= depth + 1))
#___________________
func Object *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = generate.fields(info, depth= depth);
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
    args  : seq[PNode] = generate.fields(info, depth= depth);
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
    inner : PNode  = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkCast, info)
  result.add(identifier.typ(info, T))
  result.add(inner)


#_______________________________________
# @section Expression Generation: Conv (Explicit Type Conversion)
#_____________________________
func conv *(
    info  : TLineInfo;
    depth : int    = 0;
    T     : string = R.typename();
    inner : PNode  = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkConv, info)
  result.add(identifier.typ(info, T))
  result.add(inner)


#_______________________________________
# @section Expression Generation: Static
#_____________________________
func Static *(
    info  : TLineInfo;
    depth : int   = 0;
    inner : PNode = generate.expression_random(info, depth= depth + 1);
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
    cond  : PNode = generate.expression_random(info, depth= depth + 1);
    value : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkElifExpr, info)
  result.add(cond)
  result.add(value)
#___________________
func Else *(
    info  : TLineInfo;
    depth : int   = 0;
    value : PNode = generate.expression_random(info, depth= depth + 1);
  ) :PNode=
  result = newNodeI(nkElseExpr, info)
  result.add(value)
#___________________
func branches *(
    info  : TLineInfo;
    count : int = R.integer(1..4);
    depth : int = 0;
  ) :seq[PNode]=
  for _ in 0..<count: result.add(generate.Elif(info, depth= depth))
  result.add(generate.Else(info, depth= depth))
#___________________
func If *(
    info  : TLineInfo;
    depth : int        = 0;
    args  : seq[PNode] = generate.branches(info, depth= depth);
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
func expression_random *(info :TLineInfo; T :string= R.typename(); depth :int= 0) :PNode=
  if depth >= ExprMaxDepth:
    result = literal.random(T)
  else:
    result = case R.integer(23)
    of  1: identifier.random(info)
    of  2: generate.par(info, depth= depth)
    of  3: generate.dot(info, depth)
    of  4: generate.expression_call(info, depth= depth)
    of  5: generate.quoted(info)
    of  6: generate.deref(info, depth= depth)
    of  7: generate.Addr(info, depth= depth)
    of  8: generate.arrayAccess(info, depth= depth)
    of  9: generate.callStrLit(info)
    of 10: generate.Range(info, depth= depth)
    of 11: generate.bracket(info, depth= depth)
    of 12: generate.curly(info, depth= depth)
    of 13: generate.Tuple(info, depth= depth)
    of 14: generate.Cast(info, depth= depth)
    of 15: generate.Object(info, depth= depth)
    of 16: generate.table(info, depth= depth)
    of 17: generate.Static(info, depth= depth)
    of 18: generate.If(info, depth= depth)
    of 19: generate.curlyExpr(info, depth= depth)
    of 20: generate.Bind(info)
    of 21: generate.pragma(info)
    of 22: generate.conv(info, depth= depth)
    of 23:
      if depth > 0 : literal.random(T)
      else         : generate.lambda(info, depth= depth)
    # TODO: Wire in affix expressions once operator rendering is fixed
    else: literal.random(T)


#_______________________________________
# @section Statement Generation: Variable
#_____________________________
func statement_variable_runtime (
    info    : TLineInfo;
    public  : bool     = false;
    mutable : bool     = true;
    cmment  : bool     = random.bool();
    T       : string   = random.typename();
    count   : Positive = 1;
  ) :PNode=
  let kind = if mutable: nkVarSection else: nkLetSection
  result = newNodeI(kind, info)
  for id in 1..count:
    let identDefs = newNodeI(nkIdentDefs, info)
    let nameNode = identifier.random(info, public)
    if random.bool(): identDefs.add(generate.pragma(info, inner= nameNode, decl= true))
    else:             identDefs.add(nameNode)
    identDefs.add(identifier.typ(info, T))
    identDefs.add(generate.expression_random(info, T))
    if cmment: identDefs.addComment()
    result.add(identDefs)
#___________________
func statement_variable_comptime (
    info    : TLineInfo;
    public  : bool     = false;
    cmment  : bool     = random.bool();
    T       : string   = random.typename();
    count   : Positive = 1;
  ) :PNode=
  result = newNodeI(nkConstSection, info)
  for id in 1..count:
    let constDef = newNodeI(nkConstDef, info)
    let nameNode = identifier.random(info, public)
    if random.bool(): constDef.add(generate.pragma(info, inner= nameNode, decl= true))
    else:             constDef.add(nameNode)
    constDef.add(identifier.typ(info, T))
    constDef.add(generate.expression_random(info, T))
    if cmment: constDef.addComment()
    result.add constDef
#___________________
func statement_variable *(
    info    : TLineInfo;
    public  : bool   = random.bool();
    mutable : bool   = random.bool();
    runtime : bool   = random.bool();
    comment : bool   = random.bool();
    T       : string = random.typename();
  ) :PNode=
  if runtime : generate.statement_variable_runtime(info, public, mutable, comment, T)
  else       : generate.statement_variable_comptime(info, public, comment, T)


#_______________________________________
# @section Statement Generation: Call
#_____________________________
func statement_call_node *(
    info    : TLineInfo;
    command : bool              = false;
    name    : string            = identifier.name();
    args    : openArray[PNode]  = [];
  ) :PNode=
  result = newNodeI(if command: nkCommand else: nkCall, info)
  result.add(identifier.node(info, name))
  for arg in args: result.add(arg)
#___________________
func statement_call *(
    info    : TLineInfo;
    command : bool = false;
    args    : int  = R.integer(16);
    cmment  : bool = R.bool();
  ) :PNode=
  # @workaround nkCommand renderer bug: command syntax wraps long lines without
  #   parens, producing invalid indentation. See: renderer.nim:1227-1237
  const CallIdentLen = when defined(NimCompilerBug_CommandIndent): 64 else: 8
  result = newNodeI(if command: nkCommand else: nkCall, info)
  result.add(identifier.random(info, length= R.integer(1..CallIdentLen)))
  for _ in 0..<args: result.add(generate.expression_random(info, depth= 1))
  if cmment: result.addComment()


#_______________________________________
# @section Statement Generation: Assignment
#_____________________________
func statement_assignment_node *(
    info  : TLineInfo;
    name  : string;
    value : PNode;
  ) :PNode=
  result = newNodeI(nkAsgn, info)
  result.add(identifier.node(info, name))
  result.add(value)
#___________________
func statement_default_result *(
    info : TLineInfo;
    T    : string;
  ) :PNode=
  result = generate.statement_assignment_node(info, "result", generate.statement_call_node(info, name= "default", args= [identifier.node(info, T)]))
#___________________
func statement_assignment *(info : TLineInfo) :PNode=
  result = generate.statement_assignment_node(info, identifier.name(), generate.expression_random(info))


#_______________________________________
# @section Statement Generation: Discard
#_____________________________
func statement_discard *(
    info   : TLineInfo;
    cmment : bool = R.bool();
  ) :PNode=
  result = newNodeI(nkDiscardStmt, info)
  if R.bool() : result.add(generate.expression_random(info))
  else        : result.add(newNodeI(nkEmpty, info))
  if cmment: result.addComment()


#_______________________________________
# @section Statement Generation: Module
#_____________________________
# @workaround nkImportExceptStmt renderer bug: wraps except-list at indent 0.
#   See: nim compiler renderer.nim:1696-1706
const ModuleIdentLen = when defined(NimCompilerBug_ImportExceptIndent): 64 else: 8
func statement_import *(
    info    : TLineInfo;
    entries : int    = 0;
    As      : string = "";
    From    : bool   = false;
    cmment  : bool   = R.bool();
  ) :PNode=
  let kind =
    if   From        : nkFromStmt
    elif entries > 0 : nkImportExceptStmt
    else             : nkImportStmt
  let name =
    if As == "": identifier.random(info, length= R.integer(1..ModuleIdentLen))
    else       : generate.infix(
      info  = info,
      op    = "as",
      left  = identifier.random(info, length= R.integer(1..ModuleIdentLen)),
      right = identifier.node(info, As))
  result = newNodeI(kind, info)
  result.add(name)
  for _ in 0..<entries: result.add(identifier.random(info, length= R.integer(1..ModuleIdentLen)))
  if cmment: result.addComment()
#___________________
func statement_include *(
    info   : TLineInfo;
    cmment : bool = R.bool();
  ) :PNode=
  result = newNodeI(nkIncludeStmt, info)
  result.add(identifier.random(info))
  if cmment: result.addComment()
#___________________
func statement_module *(
    info : TLineInfo;
  ) :PNode=
  case R.integer(4)
  of 1: generate.statement_include(info)
  of 2: generate.statement_import(info, As= identifier.name())
  of 3: generate.statement_import(info, As= identifier.name(), entries= R.integer(5))
  of 4: generate.statement_import(info, entries= R.integer(6))
  else: generate.statement_import(info)


#_______________________________________
# @section Statement Generation: Procedure
#_____________________________
const ProcMaxDepth * = 4
#___________________
func statement_generate *(
    info  : TLineInfo;
    kind  : TNodeKind;
    depth : int = 0;
  ) :PNode
#___________________
func statement_procedure *(
    info     : TLineInfo;
    public   : bool = false;
    cmment   : bool = R.bool();
    pragmas  : bool = R.bool();
    args     : bool = R.bool();
    defaults : bool = R.bool();
    depth    : int  = 0;
  ) :PNode
#___________________
proc procedure_arguments *(
    info      : TLineInfo;
    retType   : string;
    numParams : int;
    pragmas   : bool = false;
    defaults  : bool = false;
  ) :PNode=
  result = newNodeI(nkFormalParams, info)
  result.add(identifier.typ(info, retType))
  var usedNames: seq[string]
  var remaining = numParams
  while remaining > 0:
    # Create a (single or grouped) argument
    let T         = R.sample(basicTypes)
    let groupSize = R.integer(1..remaining)
    let group     = newNodeI(nkIdentDefs, info)
    for _ in 0..<groupSize:
      var name_unique = identifier.name(length= R.integer(1..32))
      while name_unique in usedNames:  # If name already exists, retry until we get a different/unused one
        name_unique = identifier.name(length= R.integer(1..32))
      usedNames.add(name_unique)
      let nameNode = identifier.node(info, name_unique)
      if pragmas and R.bool() : group.add(generate.pragma(info, inner= nameNode, decl= true, wrap= false))
      else                    : group.add(nameNode)
    group.add(identifier.typ(info, T))
    if defaults and R.bool(): group.add(generate.expression_random(info, T, depth= 1))
    else:                     group.add(newNodeI(nkEmpty, info))
    # Add the group to the result and continue
    result.add(group)
    remaining -= groupSize
#___________________
func procedure_body *(
    info          : TLineInfo;
    retType       : string;
    numStatements : int;
    depth         : int = 0;
  ) :PNode=
  result = newNodeI(nkStmtList, info)
  if retType != "void": result.add(generate.statement_default_result(info, retType))
  for _ in 0..<numStatements:
    result.add(generate.statement_generate(info, R.sample(Statements_body), depth= depth))
  if result.len == 0: result = newNodeI(nkEmpty, info)
#___________________
func statement_procedure *(
    info     : TLineInfo;
    public   : bool = false;
    cmment   : bool = R.bool();
    pragmas  : bool = R.bool();
    args     : bool = R.bool();
    defaults : bool = R.bool();
    depth    : int  = 0;
  ) :PNode=
  let nameNode  = identifier.random(info, public)
  let retType   = R.sample(basicTypes)
  let body      = generate.procedure_body(info, retType, numStatements= R.integer(0..16), depth= depth) 
  let arguments =
    if not args : newNodeI(nkEmpty, info)
    else        : generate.procedure_arguments(info, retType, numParams= R.integer(0..16), pragmas= pragmas, defaults= defaults)
  let pragmas   =
    if pragmas  : generate.pragmaNode(info, decl= true)
    else        : newNodeI(nkEmpty, info)
  let generics = newNodeI(nkEmpty, info)
  result = newNodeI(nkProcDef, info)
  result.add(nameNode)                 # 0: Name
  result.add(generics)                 # 1: Generic params
  result.add(newNodeI(nkEmpty, info))  # 2: Signature (pattern)
  result.add(arguments)                # 3: Formal params
  result.add(pragmas)                  # 4: Pragma
  result.add(newNodeI(nkEmpty, info))  # 5: Reserved
  result.add(body)                     # 6: Body
  if cmment: result.addComment()


#_______________________________________
# @section Expression Generation: Lambda
#_____________________________
func lambda *(info :TLineInfo; depth :int= 0) :PNode=
  let retType   = R.sample(basicTypes)
  let arguments = generate.procedure_arguments(info, retType, numParams= R.integer(0..8))
  let body      = generate.procedure_body(info, retType, numStatements= R.integer(0..8), depth= depth)
  result = newNodeI(nkLambda, info)
  result.add(newNodeI(nkEmpty, info))
  result.add(newNodeI(nkEmpty, info))
  result.add(newNodeI(nkEmpty, info))
  result.add(arguments)
  result.add(newNodeI(nkEmpty, info))
  result.add(newNodeI(nkEmpty, info))
  result.add(body)


#_______________________________________
# @section Statement Generation: Dispatch
#_____________________________
func statement_generate *(
    info  : TLineInfo;
    kind  : TNodeKind;
    depth : int = 0;
  ) :PNode=
  result = case kind
  of nkVarSection, nkLetSection,
     nkConstSection            : generate.statement_variable(info)
  of nkProcDef                 :
    if depth < ProcMaxDepth    : generate.statement_procedure(info, depth= depth + 1)
    else                       : generate.statement_variable(info, public=false)
  of nkCall                    : generate.statement_call(info)
  of nkCommand                 : generate.statement_call(info, command= true)
  of nkCommentStmt             : statement_comment.random(info)
  of nkAsgn                    : generate.statement_assignment(info)
  of nkDiscardStmt             : generate.statement_discard(info)
  of nkImportStmt, nkFromStmt,
     nkImportExceptStmt,
     nkIncludeStmt             : generate.statement_module(info)
  else                         : newNodeI(nkEmpty, info)


#_______________________________________
# @section Node Generation: Top-Level
#_____________________________
func node_random *(info :TLineInfo) :PNode=
  result = generate.statement_generate(info, R.sample(Statements_toplevel))


#_______________________________________
# @section Code Generation: Generic
#_____________________________
proc codegen *(
    kind        : string = "variable";
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string=
  let nodeKind = case kind
    of "variable" : nkVarSection
    of "proc"     : nkProcDef
    of "call"     : nkCall
    of "module"   : nkImportStmt
    of "comment"  : nkCommentStmt
    else: doAssert false, "unknown kind: " & kind; nkEmpty
  let root = generate.root(path)
  for _ in 0..<random.integer(128): root.node.add(generate.statement_generate(root.info, nodeKind))
  return render.code(root, allowBlocks)


#_______________________________________
# @section Code Generation: Specific Nim Syntax
#_____________________________
proc variable *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string= "variable".codegen(path, allowBlocks)
#___________________
proc procs *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string= "proc".codegen(path, allowBlocks)


#_______________________________________
# @section Code Generation: All Nim Syntax
#_____________________________
proc nim *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string=
  let root = generate.root(path)
  for _ in 0..<random.integer(128): root.node.add(generate.node_random(root.info))
  return render.code(root, allowBlocks)

