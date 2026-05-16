#:____________________________________________________________________
#  Minimal reproduction: nkStaticExpr renders `static EXPR` without parens
#
#  Build & run:
#    nim r render.nim
#
#  Expected: `static(addr(x))` or equivalent parseable form
#  Actual:   `static addr(x)` which the parser rejects inside parens
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: static with addr (keyword-expression) inside parens
#   Parser rejects keyword after `static` inside parenthesized context
block:
  let inner = newNodeI(nkAddr, info)
  inner.add(newIdentNode(cache.getIdent("x"), info))
  let staticNode = newNodeI(nkStaticExpr, info)
  staticNode.add(inner)
  let par = newNodeI(nkPar, info)
  par.add(staticNode)
  echo "=== Case 1: (static addr(x)) ==="
  echo renderTree(par, {renderDocComments})
  echo ""


# Case 2: static with `not` prefix (another keyword-expression)
block:
  let inner = newNodeI(nkPrefix, info)
  inner.add(newIdentNode(cache.getIdent("not"), info))
  inner.add(newIdentNode(cache.getIdent("y"), info))
  let staticNode = newNodeI(nkStaticExpr, info)
  staticNode.add(inner)
  let par = newNodeI(nkPar, info)
  par.add(staticNode)
  echo "=== Case 2: (static not y) ==="
  echo renderTree(par, {renderDocComments})
  echo ""


# Case 3: static with literal (works fine)
block:
  let staticNode = newNodeI(nkStaticExpr, info)
  staticNode.add(newIntNode(nkIntLit, 42))
  echo "=== Case 3: static 42 ==="
  echo renderTree(staticNode, {renderDocComments})
