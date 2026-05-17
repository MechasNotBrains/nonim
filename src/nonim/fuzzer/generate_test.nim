#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
import minitest
# @deps nim.gen
from ./generate import nil
import ./tests/base


describe "nonim.fuzzer | Compiler Test":
  it "must compile generated code successfully", proc() =
    compileTest("generator", "generated_code.nim", generate.nim("generated_code.nim"), semaRequired= false).ok()

