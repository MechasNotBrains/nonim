#:____________________________________________________________________
#  Fuzzer: nkImportExceptStmt except-list wraps to indent 0
#
#  Generates random import-except statements with long identifiers
#  and writes the rendered output to `fuzz_output.nim`.
#
#  Build & run:
#    nim r doc/nim_bugs/import_except_indent/fuzz.nim
#    nim check doc/nim_bugs/import_except_indent/fuzz_output.nim
#
#  The second command will fail to parse because of invalid indentation.
#:____________________________________________________________________
# @deps std
from std/os import `/`, parentDir
# @deps compiler
import "$nim"/compiler/ast
# @deps nim.gen
from nimgen/generate import nil
from nimgen/generate/statement/module import nil

const count {.intdefine.} = 4096 ## Override with -d:count=N

let outputPath = currentSourcePath.parentDir / "fuzz_output.nim"
let root = generate.root(outputPath)

for _ in 0..<count:
  root.node.add(module.Import(root.info, As= "alias", entries= 4))

writeFile(outputPath, generate.render(root))
echo "Wrote ", outputPath
