#:_________________________________________________________
#  clean  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for the clean backend POC.
## Each test compiles Nim source through sem, converts to astTF,
## runs slate's nim codegen, and checks the output matches expected.
#_________________________________________________________|
# @deps std
import std/os
# @deps tests
import minitest
# @deps slate
import slate
import slate/ast as astTF
# @deps clean
import ./compiler
import ./convert


const cases_dir = currentSourcePath().parentDir() / "test" / "cases"

proc roundtrip(source :string) :string=
  let compiled = compile(source)
  let ast = convert(compiled)
  let output = ast.nim()
  return output.modules[0].definitions

proc case_input(name :string) :string=
  readFile(cases_dir / name / "input.nim")

proc case_expected(name :string) :string=
  readFile(cases_dir / name / "expected.nim")


describe "clean.convert | Variables":
  it "must roundtrip a let binding", proc() =
    let result = roundtrip(case_input("variable"))
    result.eq case_expected("variable")

describe "clean.convert | Procedures":
  it "must roundtrip a proc signature", proc() =
    let result = roundtrip(case_input("procedure"))
    result.eq case_expected("procedure")

