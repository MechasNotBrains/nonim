#:____________________________________________________________________
#  Fuzzer: nkStmtListExpr inside nkPar renders newlines not semicolons
#
#  Generates random stmtListExpr nodes wrapped in nkPar and writes
#  the rendered output to `fuzz_output.nim`.
#
#  Build & run:
#    nim r doc/nim_bugs/stmtlistexpr_nosemicolon/fuzz.nim
#    nim check doc/nim_bugs/stmtlistexpr_nosemicolon/fuzz_output.nim
#
#  The second command will fail to parse because newline-separated
#  statements inside parentheses are rejected.
#:____________________________________________________________________
# @deps std
from std/os import `/`, parentDir
# @deps compiler
import "$nim"/compiler/ast
from "$nim"/compiler/renderer import renderTree, renderDocComments
# @deps nim.gen
from nimgen/generate import nil

const count {.intdefine.} = 4096 ## Override with -d:count=N

let outputPath = currentSourcePath.parentDir / "fuzz_output.nim"
let root = generate.root(outputPath)

for _ in 0..<count:
  let sle = newNodeI(nkStmtListExpr, root.info)
  sle.add(generate.expression_random(root.info, depth= 1))
  sle.add(generate.expression_random(root.info, depth= 1))
  let par = newNodeI(nkPar, root.info)
  par.add(sle)
  root.node.add(par)

writeFile(outputPath, renderTree(root.node, {renderDocComments}))
echo "Wrote ", outputPath
