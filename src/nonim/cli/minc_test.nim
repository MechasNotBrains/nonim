#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## End-to-end tests for the minc (untyped) backend.
#_______________________________________________________________|
# @deps std
from std/os import `/`, parentDir
# @deps tests
import minitest
# @deps nonim
import ../cli
import ../backend/minc


const cases_dir = currentSourcePath().parentDir()/".."/"backend"/"test"/"cases"

proc generate_from (name :string) :string=
  let options = Options(
    backend: Backend.minc,
    command: Command.codegen,
    input: cases_dir/name/"input.nim",
    output: cases_dir/name/"output",
  )
  let output = minc.generate(options)
  return output.modules[0].definitions

proc case_expected_c (name :string) :string=
  readFile(cases_dir/name/"expected.c")


describe "nonim.cli.minc | Variables":
  it "must generate static const int from let binding", proc() =
    let result = generate_from("variable")
    result.eq case_expected_c("variable")

  it "must generate static mutable int from var binding", proc() =
    let result = generate_from("variable_var")
    result.eq case_expected_c("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_from("variable_exported")
    result.eq case_expected_c("variable_exported")

describe "nonim.cli.minc | Procedures":
  it "must generate a static forward declaration", proc() =
    let result = generate_from("procedure")
    result.eq case_expected_c("procedure")
