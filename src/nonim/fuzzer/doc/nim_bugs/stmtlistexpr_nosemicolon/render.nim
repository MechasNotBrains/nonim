#:____________________________________________________________________
#  Minimal reproduction: nkStmtListExpr inside nkPar renders newlines not semicolons
#
#  Build & run:
#    nim r render.nim
#
#  Expected: `(x = 10; x)` or equivalent parseable form
#  Actual:   `(\n  x = 10\n  x)` which the parser rejects inside parens
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: nkStmtListExpr inside nkPar
#   Parser rejects newline-separated statements inside parens
block:
  let sle = newNodeI(nkStmtListExpr, info)
  let asgn = newNodeI(nkAsgn, info)
  asgn.add(newIdentNode(cache.getIdent("x"), info))
  asgn.add(newIntNode(nkIntLit, 10))
  sle.add(asgn)
  sle.add(newIdentNode(cache.getIdent("x"), info))
  let par = newNodeI(nkPar, info)
  par.add(sle)
  echo "=== Case 1: (x = 10; x) ==="
  echo renderTree(par, {renderDocComments})
  echo ""


# Case 2: nkStmtListExpr with multiple statements inside nkPar
block:
  let sle = newNodeI(nkStmtListExpr, info)
  let asgn1 = newNodeI(nkAsgn, info)
  asgn1.add(newIdentNode(cache.getIdent("a"), info))
  asgn1.add(newIntNode(nkIntLit, 1))
  sle.add(asgn1)
  let asgn2 = newNodeI(nkAsgn, info)
  asgn2.add(newIdentNode(cache.getIdent("b"), info))
  asgn2.add(newIntNode(nkIntLit, 2))
  sle.add(asgn2)
  sle.add(newIdentNode(cache.getIdent("b"), info))
  let par = newNodeI(nkPar, info)
  par.add(sle)
  echo "=== Case 2: (a = 1; b = 2; b) ==="
  echo renderTree(par, {renderDocComments})
