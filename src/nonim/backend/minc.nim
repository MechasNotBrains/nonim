#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## MinC backend: untyped AST path.
## Parses Nim source without semantic analysis and emits C.
#_______________________________________________________________|
# @deps nonim
import ../cli
import ../cli/output as cli_output
import ../nimc/Untyped
import ../ast/convert
import ../codegen/C
import ../codegen/output


proc generate *(options :Options) :Output=
  let source    = readFile(options.input)
  let root      = Untyped.compile(source, options.input)
  let converted = root.convert(Language.C, typed=false, options.input)
  return converted.C()


proc run *(options :Options) =
  cli_output.run(options, generate(options))

