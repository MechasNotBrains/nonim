#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, options, lineinfos, msgs, idents, parser ]
from   "$nim"/compiler/renderer import renderTree, renderNoComments, renderNoPragmas
# @deps std
from std/strutils  import replace
from std/strformat import `&`


#_______________________________________
# @section Nim Compiler: Formatting Helper Tools
#_____________________________
const Sep = ". "
const Spc = "  "
#___________________
func `*` *(ident :int; tab :string) :string=
  ## @descr Returns the given `tab` string concatenated `ident` times
  for id in 0..<ident: result.add tab
#___________________
proc treeRepr *(node :PNode; indent :int= 0) :string # fw declare for strvalue
#___________________
proc strValue *(node :PNode) :string=
  if node == nil: return
  case node.kind
  of nkEmpty                   : result = ""
  of nkAccQuoted               :
    for entry in node          : result.add entry.strValue
  of nkSym                     : result = node.sym.name.s
  of nkIdent                   : result = node.ident.s
  of nkCharLit                 : result = $char(node.intVal)
  of nkIntLit..nkUInt64Lit     : result = $node.intVal
  of nkFloatLit..nkFloat128Lit : result = $node.floatVal
  of nkStrLit                  : result = node.strVal.replace("\n", "\\n")
  of nkRStrLit..nkTripleStrLit : result = node.strVal
  of nkCommentStmt             : result = node.comment() # assert false, debugEcho(node.treeRepr & "\n\n" & $node[] & "\n" & node.renderTree)
  of nkBracket                 :
    for id,entry in node.pairs:
      assert entry.kind in nkCharLit..nkTripleStrLit or entry.kind == nkIdent
      result.add entry.strValue
      if id != node.sons.len-1: result.add " " # Skip adding " " at the end for the last entry
  else:raise newException(ValueError, &"Tried to get the strValue of a node that doesn't have one.\n  {$node.kind}\n{node.treeRepr}\n{node.renderTree}\n")
#___________________
proc treeRepr *(node :PNode; indent :int= 0) :string=
  ## @descr
  ##  Returns the treeRepr of the given AST.
  ##  Similar to NimNode.treeRepr, but for PNode.
  # Base Case
  if node == nil: return
   # Process this node
  result.add &"{indent*Sep}{$node.kind}"
  case node.kind
  of nkSym, nkIdent, nkCharLit..nkTripleStrLit: result.add &"{Spc}{node.strValue}"
  else:discard
  result.add "\n"
  # Recurse all subnodes
  for child in node: result.add child.treeRepr(indent+1)


#_______________________________________
# @section Nim Compiler: Error Management
#_____________________________
type ParserError = object of CatchableError
var errorStr :string
proc errorAST (conf :options.ConfigRef; info :lineinfos.TLineInfo; msg :lineinfos.TMsgKind; arg :string)=
  if errorStr.len == 0 and msg <= errMax:
    errorStr = msgs.formatMsg(conf, info, msg, arg)
    raise newException(ParserError, errorStr)


#_______________________________________
# @section Nim Compiler: Parser Process
#_____________________________
proc getAST *(code :string; file :string= "") :ast.PNode=
  ## @descr Gets the AST of {@arg code}. The given {@arg file} path is used for error messages.
  var cache  = idents.newIdentCache()
  var config = options.newConfigRef()
  result = parser.parseString(
    s            = code,
    cache        = cache,
    config       = config,
    filename     = file,
    line         = 0,
    errorHandler = errorAST
    ) #:: parser.parseString( ... )
#___________________
proc readAST *(file :string) :ast.PNode= nimc.getAST(file.readFile(), file)
  ## @descr Reads the AST of the given nim file.

