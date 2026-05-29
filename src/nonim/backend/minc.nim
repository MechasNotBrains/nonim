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
from ../nimc/errors import nil
import ../ast/convert
import ../codegen/C
import ../codegen/output
import ./preprocess


proc generate *(options :Options) :Output=
  let source    = preprocess.processIncludes(readFile(options.input), options.input)
  let root      = Untyped.compile(source, options.input)
  let converted = root.convert(Language.C, typed=false, options.input)
  result = converted.C()
  result.parse_errors = errors.collected


proc run *(options :Options) =
  cli_output.run(options, generate)

