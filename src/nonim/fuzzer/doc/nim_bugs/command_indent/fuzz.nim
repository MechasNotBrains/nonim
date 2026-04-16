#:____________________________________________________________________
#  Fuzzer: nkCommand wraps args with invalid indentation
#
#  Generates random procedures containing command calls with long
#  identifiers and writes the rendered output to `fuzz_output.nim`.
#
#  Build & run:
#    nim r doc/nim_bugs/command_indent/fuzz.nim
#    nim check doc/nim_bugs/command_indent/fuzz_output.nim
#
#  The second command will fail to parse because of invalid indentation.
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
  root.node.add(generate.statement_procedure(root.info))

writeFile(outputPath, renderTree(root.node, {renderDocComments}))
echo "Wrote ", outputPath
