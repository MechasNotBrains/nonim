#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## MinZ backend: untyped AST path.
## Parses Nim source without semantic analysis and emits Zig.
#_______________________________________________________________|
# @deps nimc
import "$nim"/compiler/[ast]
# @deps nonim
import ../cli
import ../cli/output as cli_output
import ../nimc/Untyped
import ../ast/convert
import ../codegen/zig
import ../codegen/output
import ./preprocess


proc generate *(options :Options) :Output=
  let source    = preprocess.processIncludes(readFile(options.input), options.input)
  let root      = Untyped.compile(source, options.input)
  let converted = root.convert(Language.Zig, typed=false, options.input)
  return converted.zig()


proc run *(options :Options) =
  cli_output.run(options, generate(options))

