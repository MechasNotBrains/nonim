#:____________________________________________________________________
#  Minimal reproduction: nkIfExpr elif/else render at outer indent
#
#  Build & run:
#    nim r render.nim
#
#  Expected: elif/else indented to match the `if` context
#  Actual:   elif/else render at the outermost indent level
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: if-expr as a call argument inside a proc body
#   elif/else render at column 0 instead of matching the call indent
block:
  let ifNode = newNodeI(nkIfExpr, info)

  let elif1 = newNodeI(nkElifExpr, info)
  elif1.add(newIdentNode(cache.getIdent("cond1"), info))
  elif1.add(newIntNode(nkIntLit, 1))
  ifNode.add(elif1)

  let elif2 = newNodeI(nkElifExpr, info)
  elif2.add(newIdentNode(cache.getIdent("cond2"), info))
  elif2.add(newIntNode(nkIntLit, 2))
  ifNode.add(elif2)

  let elseN = newNodeI(nkElseExpr, info)
  elseN.add(newIntNode(nkIntLit, 3))
  ifNode.add(elseN)

  # Wrap in: proc body > let assignment > call > if-expr
  let call = newNodeI(nkCall, info)
  call.add(newIdentNode(cache.getIdent("foo"), info))
  call.add(ifNode)

  let letDef = newNodeI(nkIdentDefs, info)
  letDef.add(newIdentNode(cache.getIdent("x"), info))
  letDef.add(newNodeI(nkEmpty, info))
  letDef.add(call)

  let letSection = newNodeI(nkLetSection, info)
  letSection.add(letDef)

  let body = newNodeI(nkStmtList, info)
  body.add(letSection)

  let params = newNodeI(nkFormalParams, info)
  params.add(newNodeI(nkEmpty, info))

  let procDef = newNodeI(nkProcDef, info)
  procDef.add(newIdentNode(cache.getIdent("bar"), info))
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(params)
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(body)

  echo "=== Case 1: if-expr inside call inside proc ==="
  echo renderTree(procDef, {renderDocComments})
