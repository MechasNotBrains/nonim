#:____________________________________________________________________
#  Minimal reproduction: nkCommand wraps args with invalid indentation
#
#  Build & run:
#    nim r render.nim
#
#  Expected: arguments on same line or validly indented for command syntax
#  Actual:   arguments wrap to indentation that the parser rejects
#:____________________________________________________________________
import "$nim"/compiler/[ ast, idents, renderer, lineinfos ]

var cache = newIdentCache()
let info = TLineInfo(fileIndex: FileIndex(0), line: 1, col: 1)


# nkCommand inside a proc body with long args
block:
  let cmd = newNodeI(nkCommand, info)
  cmd.add(newIdentNode(cache.getIdent("someProcedureWithAVeryLongNameThatForcesWrapping"), info))
  cmd.add(newIdentNode(cache.getIdent("aVeryLongIdentifierNameThatWillForceTheRendererToWrapToTheNextLine"), info))
  cmd.add(newIdentNode(cache.getIdent("anotherVeryLongIdentifierThatPushesEvenFurtherPastTheLineLimit"), info))

  let body = newNodeI(nkStmtList, info)
  body.add(cmd)

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

  echo "=== nkCommand inside proc ==="
  echo renderTree(procDef, {renderDocComments})
