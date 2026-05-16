#:____________________________________________________________________
#  Minimal reproduction: form feed in comment causes renderTree to hang
#
#  Build & run:
#    nim r render.nim
#
#  WARNING: This program will hang indefinitely. Kill it with Ctrl+C.
#
#  Expected: form feed character handled or stripped from the comment
#  Actual:   renderTree enters an infinite loop
#:____________________________________________________________________
import "$nim"/compiler/[ ast, renderer, lineinfos ]

let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)

let commentNode = newNodeI(nkCommentStmt, info)
commentNode.comment = "hello\x0Cworld"

let root = newNodeI(nkStmtList, info)
root.add(commentNode)

echo "About to call renderTree (will hang)..."
echo renderTree(root, {renderDocComments})
echo "This line is never reached."
