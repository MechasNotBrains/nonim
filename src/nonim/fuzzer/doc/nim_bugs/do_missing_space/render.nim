#:____________________________________________________________________
#  Minimal reproduction: nkDo missing space in renderer output
#
#  Build & run:
#    nim r render.nim
#
#  Expected: space between call and `do` keyword
#  Actual:   no space — produces `sort(cities)do` and `foodo`
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# Case 1: call with args + nkDo child
#   Expected: sort(cities) do (x, y: string) -> int: ...
#   Actual:   sort(cities)do (x, y: string) -> int: ...
block:
  let call = newNodeI(nkCall, info)
  call.add(newIdentNode(cache.getIdent("sort"), info))
  call.add(newIdentNode(cache.getIdent("cities"), info))

  let doNode = newNodeI(nkDo, info)
  doNode.add(newNodeI(nkEmpty, info))  # 0: name
  doNode.add(newNodeI(nkEmpty, info))  # 1: pattern
  doNode.add(newNodeI(nkEmpty, info))  # 2: genericParams
  let params = newNodeI(nkFormalParams, info)
  params.add(newIdentNode(cache.getIdent("int"), info))
  let paramDef = newNodeI(nkIdentDefs, info)
  paramDef.add(newIdentNode(cache.getIdent("x"), info))
  paramDef.add(newIdentNode(cache.getIdent("y"), info))
  paramDef.add(newIdentNode(cache.getIdent("string"), info))
  paramDef.add(newNodeI(nkEmpty, info))
  params.add(paramDef)
  doNode.add(params)                   # 3: params
  doNode.add(newNodeI(nkEmpty, info))  # 4: pragmas
  doNode.add(newNodeI(nkEmpty, info))  # 5: exceptions
  let body = newNodeI(nkStmtList, info)
  let disc = newNodeI(nkDiscardStmt, info)
  disc.add(newNodeI(nkEmpty, info))
  body.add(disc)
  doNode.add(body)                     # 6: body

  call.add(doNode)
  echo "=== Case 1: call with args + nkDo ==="
  echo renderTree(call, {renderDocComments})
  echo ""


# Case 2: call without args + nkDo child
#   Expected: foo do (x: int): ...
#   Actual:   foodo (x: int): ...
block:
  let call = newNodeI(nkCall, info)
  call.add(newIdentNode(cache.getIdent("foo"), info))

  let doNode = newNodeI(nkDo, info)
  doNode.add(newNodeI(nkEmpty, info))  # 0: name
  doNode.add(newNodeI(nkEmpty, info))  # 1: pattern
  doNode.add(newNodeI(nkEmpty, info))  # 2: genericParams
  let params = newNodeI(nkFormalParams, info)
  params.add(newNodeI(nkEmpty, info))
  let paramDef = newNodeI(nkIdentDefs, info)
  paramDef.add(newIdentNode(cache.getIdent("x"), info))
  paramDef.add(newIdentNode(cache.getIdent("int"), info))
  paramDef.add(newNodeI(nkEmpty, info))
  params.add(paramDef)
  doNode.add(params)                   # 3: params
  doNode.add(newNodeI(nkEmpty, info))  # 4: pragmas
  doNode.add(newNodeI(nkEmpty, info))  # 5: exceptions
  let body = newNodeI(nkStmtList, info)
  let disc = newNodeI(nkDiscardStmt, info)
  disc.add(newNodeI(nkEmpty, info))
  body.add(disc)
  doNode.add(body)                     # 6: body

  call.add(doNode)
  echo "=== Case 2: call without args + nkDo ==="
  echo renderTree(call, {renderDocComments})
