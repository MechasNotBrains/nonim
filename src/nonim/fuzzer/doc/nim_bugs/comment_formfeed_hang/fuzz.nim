#:____________________________________________________________________
#  Fuzzer: form feed in comment causes renderTree to hang
#
#  Generates random comments containing control characters and attempts
#  to render them. If renderTree hangs, the process must be killed.
#
#  Build & run:
#    nim r doc/nim_bugs/comment_formfeed_hang/fuzz.nim
#
#  WARNING: This fuzzer will hang when it hits a problematic character.
#  Kill it with Ctrl+C. The last printed character is the one that caused the hang.
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, renderer, lineinfos ]
# @deps nim.gen
from nimgen/random as R import nil

const HangChars = {'\x01'..'\x08', '\x0B'..'\x0C', '\x0E'..'\x1F'}
const count {.intdefine.} = 4096 ## Override with -d:count=N

let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)

for i in 0..<count:
  let root = newNodeI(nkStmtList, info)
  let commentNode = newNodeI(nkCommentStmt, info)
  var text = ""
  for _ in 0..<R.integer(1..64):
    text.add(R.sample(HangChars))
  commentNode.comment = text
  root.add(commentNode)

  echo "Rendering comment ", i, " with chars: ", repr(text)
  let rendered = renderTree(root, {renderDocComments})
  echo "  OK: ", rendered

echo "All ", count, " comments rendered successfully (bug may be fixed)."
