#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________
## Unit tests for the clean backend POC.
## Each test compiles Nim source through sem, converts to astTF,
## runs slate's nim codegen, and checks the output matches expected.
#_________________________________________________________|
# @deps std
from std/os import `/`, parentDir
# @deps tests
import minitest
# @deps slate
import slate
import slate/ast as astTF
# @deps clean
import ../nimc/Typed
import ./convert as nonim


const cases_dir = currentSourcePath().parentDir()/"test"/"cases"

proc roundtrip (source :string) :string=
  let compiled = Typed.compile(source)
  let ast      = nonim.convert(compiled)
  let output   = slate.codegen.nim(ast)
  return output.modules[0].definitions

proc case_input(name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected(name :string) :string=
  readFile(cases_dir/name/"expected.nim")


describe "nonim.cleanc.convert | Variables":
  it "must roundtrip a let binding", proc() =
    let result = test.roundtrip(case_input("variable"))
    result.eq case_expected("variable")

describe "nonim.cleanc.convert | Procedures":
  it "must roundtrip a proc signature", proc() =
    let result = test.roundtrip(case_input("procedure"))
    result.eq case_expected("procedure")

