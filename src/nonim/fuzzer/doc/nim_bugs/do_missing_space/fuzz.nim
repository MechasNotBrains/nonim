#:____________________________________________________________________
#  Fuzzer: nkDo missing space in renderer output
#
#  Generates random nkCall nodes with nkDo children and writes the
#  rendered output to `fuzz_output.nim` in this directory.
#
#  Build & run:
#    nim r doc/nim_bugs/do_missing_space/fuzz.nim
#    nim check doc/nim_bugs/do_missing_space/fuzz_output.nim
#
#  The second command will fail to parse because of the missing space.
#:____________________________________________________________________
# @deps std
from std/os import `/`, parentDir
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
from "$nim"/compiler/renderer import renderTree, renderDocComments
# @deps nim.gen
from nimgen/generate import nil

const count {.intdefine.} = 4096 ## Override with -d:count=N

let outputPath = currentSourcePath.parentDir / "fuzz_output.nim"
let root = generate.root(outputPath)

for _ in 0..<count:
  let callNode = generate.expression_call(root.info, depth= 1)
  let doNode = generate.statement_procedure(root.info)
  doNode.kind = nkDo
  callNode.add(doNode)
  root.node.add(callNode)

writeFile(outputPath, renderTree(root.node, {renderDocComments}))
echo "Wrote ", outputPath
