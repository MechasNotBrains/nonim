#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import ./nonim/ast     ; export ast
import ./nonim/codegen ; export codegen
import ./nonim/fuzzer  ; export fuzzer

when isMainModule:
  import ./nonim/entry
  entry.run()
