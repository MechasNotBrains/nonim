#:____________________________________________________________________
#  Minimal reproduction: nkRange renders `..` without spaces
#
#  Build & run:
#    nim r render.nim
#
#  Expected: spaces around `..` operator
#  Actual:   no spaces — `0..-128'i8` lexes `..-` as one operator
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: range with negative right side
#   Lexer reads `..-` as a single operator token
block:
  let rangeNode = newNodeI(nkRange, info)
  rangeNode.add(newIntNode(nkIntLit, 0))
  rangeNode.add(newIntNode(nkInt8Lit, -128))
  echo "=== Case 1: range with negative right ==="
  echo renderTree(rangeNode, {renderDocComments})
  echo ""


# Case 2: range with positive right side (works by accident)
block:
  let rangeNode = newNodeI(nkRange, info)
  rangeNode.add(newIntNode(nkIntLit, 0))
  rangeNode.add(newIntNode(nkInt8Lit, 127))
  echo "=== Case 2: range with positive right ==="
  echo renderTree(rangeNode, {renderDocComments})
  echo ""


# Case 3: range with identifiers (works by accident)
block:
  let rangeNode = newNodeI(nkRange, info)
  rangeNode.add(newIdentNode(cache.getIdent("a"), info))
  rangeNode.add(newIdentNode(cache.getIdent("b"), info))
  echo "=== Case 3: range with identifiers ==="
  echo renderTree(rangeNode, {renderDocComments})
