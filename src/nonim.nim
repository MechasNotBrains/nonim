#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import ./nonim/ast     ; export ast
import ./nonim/codegen ; export codegen
import ./nonim/fuzzer  ; export fuzzer

when isMainModule:
  import ./nonim/cli
  import ./nonim/entry
  import ./nonim/minc

  let options = cli.options_parse()
  case options.backend
  of Backend.cleanc: entry.run(options)
  of Backend.minc:   minc.run(options)
