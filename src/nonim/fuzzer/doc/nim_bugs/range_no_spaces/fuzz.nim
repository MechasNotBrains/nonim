#:____________________________________________________________________
#  Fuzzer: nkRange renders `..` without spaces
#
#  Generates random nkRange expressions and writes the rendered output
#  to `fuzz_output.nim` in this directory.
#
#  Build & run:
#    nim r doc/nim_bugs/range_no_spaces/fuzz.nim
#    nim check doc/nim_bugs/range_no_spaces/fuzz_output.nim
#
#  The second command will fail to parse because `..-` lexes as one operator.
#:____________________________________________________________________
# @deps std
from std/os import `/`, parentDir
# @deps compiler
import "$nim"/compiler/ast
# @deps nim.gen
from nimgen/generate import nil
from nimgen/generate/expression import nil
from nimgen/generate/expression/literal import nil

const count {.intdefine.} = 4096 ## Override with -d:count=N

let outputPath = currentSourcePath.parentDir / "fuzz_output.nim"
let root = generate.root(outputPath)

for _ in 0..<count:
  root.node.add(expression.Range(root.info, depth= 1,
    right= literal.integer("int8")))

writeFile(outputPath, generate.render(root))
echo "Wrote ", outputPath
