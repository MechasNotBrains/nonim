#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import std/unittest
# @deps nim.gen
from ./generate import nil
import ./tests/base

suite "Compiler Test":
  test "Generated code compiles successfully":
    check compileTest("generator", "generated_code.nim", generate.nim("generated_code.nim"))

