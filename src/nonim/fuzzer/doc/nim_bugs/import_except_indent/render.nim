#:____________________________________________________________________
#  Minimal reproduction: nkImportExceptStmt except-list wraps to indent 0
#
#  Build & run:
#    nim r render.nim
#
#  Expected: except-list indented to match the import statement
#  Actual:   except-list wraps to column 0 when names are long
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: long names that force line wrapping
#   except-list identifiers wrap to column 0
block:
  let importNode = newNodeI(nkImportExceptStmt, info)
  let asNode = newNodeI(nkInfix, info)
  asNode.add(newIdentNode(cache.getIdent("as"), info))
  asNode.add(newIdentNode(cache.getIdent("ceHayJAx5uAuQmkoT7IRqTQvhEwryaoSGaRkeSxIOPmMf2a759xkZwBTXZuSsiG"), info))
  asNode.add(newIdentNode(cache.getIdent("XX3EwzXR0HaMMJQsJcyOe9zOe"), info))
  importNode.add(asNode)
  importNode.add(newIdentNode(cache.getIdent("JCceOSLi1v87ryBcX2HoikN0tyII3ObKXaDSmeFW8Gx68vs57DtWaYp0m8Xd1"), info))
  importNode.add(newIdentNode(cache.getIdent("XTiZs1sprYOqQVHmUTZ7Y7O"), info))

  echo "=== Case 1: import except with long names ==="
  echo renderTree(importNode, {renderDocComments})
  echo ""


# Case 2: short names — fits on one line (works fine)
block:
  let importNode = newNodeI(nkImportExceptStmt, info)
  let asNode = newNodeI(nkInfix, info)
  asNode.add(newIdentNode(cache.getIdent("as"), info))
  asNode.add(newIdentNode(cache.getIdent("mymod"), info))
  asNode.add(newIdentNode(cache.getIdent("mm"), info))
  importNode.add(asNode)
  importNode.add(newIdentNode(cache.getIdent("foo"), info))
  importNode.add(newIdentNode(cache.getIdent("bar"), info))

  echo "=== Case 2: import except with short names ==="
  echo renderTree(importNode, {renderDocComments})
