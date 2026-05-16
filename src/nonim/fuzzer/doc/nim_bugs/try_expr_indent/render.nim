#:____________________________________________________________________
#  Minimal reproduction: nkTryStmt except/finally at wrong indent inside parens
#
#  Build & run:
#    nim r render.nim
#
#  Expected: except/finally indented relative to `try` inside parens
#  Actual:   except/finally at outer indent, parser rejects it
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: try/except inside nkPar, inside a proc body
#   Parser rejects `except` at wrong indentation
block:
  let tryNode = newNodeI(nkTryStmt, info)
  tryNode.add(newIntNode(nkIntLit, 42))
  let exceptBr = newNodeI(nkExceptBranch, info)
  exceptBr.add(newIntNode(nkIntLit, 0))
  tryNode.add(exceptBr)
  let par = newNodeI(nkPar, info)
  par.add(tryNode)

  let module = newNodeI(nkStmtList, info)
  let procDef = newNodeI(nkProcDef, info)
  procDef.add(newIdentNode(cache.getIdent("foo"), info))
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  let params = newNodeI(nkFormalParams, info)
  params.add(newNodeI(nkEmpty, info))
  procDef.add(params)
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  let body = newNodeI(nkStmtList, info)
  let call = newNodeI(nkCall, info)
  call.add(newIdentNode(cache.getIdent("echo"), info))
  call.add(par)
  body.add(call)
  procDef.add(body)
  module.add(procDef)

  echo "=== Case 1: (try/except) in proc body ==="
  echo renderTree(module, {renderDocComments})
  echo ""


# Case 2: try/except/finally inside nkPar
block:
  let tryNode = newNodeI(nkTryStmt, info)
  tryNode.add(newIntNode(nkIntLit, 42))
  let exceptBr = newNodeI(nkExceptBranch, info)
  exceptBr.add(newIntNode(nkIntLit, 0))
  tryNode.add(exceptBr)
  let fin = newNodeI(nkFinally, info)
  let disc = newNodeI(nkDiscardStmt, info)
  disc.add(newNodeI(nkEmpty, info))
  fin.add(disc)
  tryNode.add(fin)
  let par = newNodeI(nkPar, info)
  par.add(tryNode)

  let module = newNodeI(nkStmtList, info)
  let procDef = newNodeI(nkProcDef, info)
  procDef.add(newIdentNode(cache.getIdent("bar"), info))
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  let params = newNodeI(nkFormalParams, info)
  params.add(newNodeI(nkEmpty, info))
  procDef.add(params)
  procDef.add(newNodeI(nkEmpty, info))
  procDef.add(newNodeI(nkEmpty, info))
  let body = newNodeI(nkStmtList, info)
  let call = newNodeI(nkCall, info)
  call.add(newIdentNode(cache.getIdent("echo"), info))
  call.add(par)
  body.add(call)
  procDef.add(body)
  module.add(procDef)

  echo "=== Case 2: (try/except/finally) in proc body ==="
  echo renderTree(module, {renderDocComments})
