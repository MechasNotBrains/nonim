#:____________________________________________________________________
#  Minimal reproduction: nkPragmaExpr `.}` clashes with dot-access suffix
#
#  Build & run:
#    nim r render.nim
#
#  Expected: space or parens separating `.}` from the dot access
#  Actual:   `.}.` which the parser rejects
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: pragma expr followed by dot access
#   `.}` closing clashes with `.bar` producing `.}.bar`
block:
  let pragmaExpr = newNodeI(nkPragmaExpr, info)
  pragmaExpr.add(newIdentNode(cache.getIdent("foo"), info))
  let pragma = newNodeI(nkPragma, info)
  pragma.add(newIdentNode(cache.getIdent("inline"), info))
  pragmaExpr.add(pragma)

  let dotExpr = newNodeI(nkDotExpr, info)
  dotExpr.add(pragmaExpr)
  dotExpr.add(newIdentNode(cache.getIdent("bar"), info))

  echo "=== Case 1: pragmaExpr.bar ==="
  echo renderTree(dotExpr, {renderDocComments})
  echo ""


# Case 2: pragma expr not followed by dot (works fine)
block:
  let pragmaExpr = newNodeI(nkPragmaExpr, info)
  pragmaExpr.add(newIdentNode(cache.getIdent("foo"), info))
  let pragma = newNodeI(nkPragma, info)
  pragma.add(newIdentNode(cache.getIdent("inline"), info))
  pragmaExpr.add(pragma)

  echo "=== Case 2: pragmaExpr standalone ==="
  echo renderTree(pragmaExpr, {renderDocComments})
