# Run with:
# nim r --path:./bin/.lib/astTF/spec ./dump.nim
#__________________________________________________
import ../src/nonim/nimc/Untyped
import ../src/nonim/nimc/ergonomics
import ../src/nonim/ast/convert
import ../src/nonim/codegen/zig

const src = staticRead("./dump_code.nim")
let ast = Untyped.compile(src)
let atf = ast.convert(Language.Zig, typed= false)
echo ast.treeRepr()
echo atf.zig().modules[0].definitions

