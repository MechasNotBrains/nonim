#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for the clean backend POC.
## Each test compiles Nim source through sem, converts to astTF,
## runs nonim's nim codegen, and checks the output matches expected.
#___________________________________________________________________|
# @deps std
from std/os import `/`, parentDir
# @deps nimc
import "$nim"/compiler/[ast]
# @deps tests
import minitest
# @deps nonim
from ../../nonim import nil
# @deps nonim
import ../nimc/Typed
import ../ast as astTF


const cases_dir = currentSourcePath().parentDir()/"test"/"cases"

proc roundtrip (source :string) :string=
  let compiled = Typed.compile(source)
  var root     = newNode(nkStmtList)
  for statement in compiled.statements:
    root.add(statement)
  let converted = astTF.convert(root)
  let output    = nonim.codegen.nim(converted)
  return output.modules[0].definitions

proc case_input(name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected(name :string) :string=
  readFile(cases_dir/name/"expected.nim")


describe "nonim.convert | Variables":
  it "must roundtrip a let binding", proc() =
    let result = test.roundtrip(case_input("variable"))
    result.eq case_expected("variable")

describe "nonim.convert | Procedures":
  it "must roundtrip a proc signature", proc() =
    let result = test.roundtrip(case_input("procedure"))
    result.eq case_expected("procedure")

