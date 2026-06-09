#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps compiler
import "$nim"/compiler/[ast, renderer]
# @deps std
from std/strutils  import repeat, replace
from std/strformat import `&`
# @deps nonim
import ../errors


#_______________________________________
# @section AST formatting
#_____________________________
const Sep * = "  "
const Spc * = " "
proc `*` *(count :int; value :string) :string= value.repeat(count)
#_____________________________
# broken. Needs the ConfigRef generated from the parsing process
# from   "$nim"/compiler/astalgo  import treeToYaml, debug
# proc treeToYaml *(node :PNode) :string= treeToYaml(options.newConfigRef(), node).string
# proc debugAST *(node :ast.PNode) :string=  debug(node)
#_____________________________
proc treeRepr *(node :PNode; indent :int= 0) :string # fw declare for strvalue
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
  else:raise newException(NimcError, &"Tried to get the strValue of a node that doesn't have one.\n  {$node.kind}\n{node.treeRepr}\n{node.renderTree}\n")
#_____________________________
proc treeRepr *(node :PNode; indent :int= 0) :string=
  ## Returns the treeRepr of the given AST.
  ## Similar to NimNode.treeRepr, but for PNode.
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
#_____________________________
proc report *(node :PNode) :void=
  ## Writes CLI information about the given node
  ## Useful for developing and debugging the compilers
  debugEcho node.treeRepr
  debugEcho node.renderTree,"\n"

