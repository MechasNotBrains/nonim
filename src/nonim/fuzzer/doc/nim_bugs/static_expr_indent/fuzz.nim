#:____________________________________________________________________
#  Fuzzer: nkStaticExpr renders without parens around inner expression
#
#  Generates random static expressions and writes the rendered output
#  to `fuzz_output.nim`.
#
#  Build & run:
#    nim r doc/nim_bugs/static_expr_indent/fuzz.nim
#    nim check doc/nim_bugs/static_expr_indent/fuzz_output.nim
#
#  The second command will fail to parse because of keyword-expressions
#  after `static` inside parenthesized contexts.
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
  root.node.add(generate.Static(root.info, depth= 1))

writeFile(outputPath, renderTree(root.node, {renderDocComments}))
echo "Wrote ", outputPath
