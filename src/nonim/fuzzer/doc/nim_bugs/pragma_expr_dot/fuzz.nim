#:____________________________________________________________________
#  Fuzzer: nkPragmaExpr `.}` clashes with dot-access suffix
#
#  Generates random pragma expressions used inside dot-access contexts
#  and writes the rendered output to `fuzz_output.nim`.
#
#  Build & run:
#    nim r doc/nim_bugs/pragma_expr_dot/fuzz.nim
#    nim check doc/nim_bugs/pragma_expr_dot/fuzz_output.nim
#
#  The second command will fail to parse because `.}.` is rejected.
#:____________________________________________________________________
# @deps std
from std/os import `/`, parentDir
# @deps compiler
import "$nim"/compiler/ast
from "$nim"/compiler/renderer import renderTree, renderDocComments
# @deps nim.gen
from nimgen/generate import nil
from nimgen/generate/identifier import nil

const count {.intdefine.} = 4096 ## Override with -d:count=N

let outputPath = currentSourcePath.parentDir / "fuzz_output.nim"
let root = generate.root(outputPath)

for _ in 0..<count:
  let dotNode = newNodeI(nkDotExpr, root.info)
  dotNode.add(generate.pragma(root.info))
  dotNode.add(identifier.random(root.info))
  root.node.add(dotNode)

writeFile(outputPath, renderTree(root.node, {renderDocComments}))
echo "Wrote ", outputPath
