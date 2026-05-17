#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Zig backend: typed AST path.
## Full semantic analysis before codegen. Emits Zig.
#_______________________________________________________________|
# @deps nimc
import "$nim"/compiler/[ast]
# @deps nonim
import ../cli
import ../cli/output as cli_output
import ../nimc/Typed
import ../ast/convert
import ../codegen/zig
import ../codegen/output


proc generate *(options :Options) :Output=
  let compiled = Typed.compile(readFile(options.input), options.input)
  var root = newNode(nkStmtList)
  for statement in compiled.statements:
    root.add(statement)
  let converted = convert.convert(root, options.input)
  return converted.zig()


proc run *(options :Options) =
  cli_output.run(options, generate(options))
