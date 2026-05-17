#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## End-to-end tests for the cleanc (typed) backend.
#_______________________________________________________________|
# @deps std
from std/os import `/`, parentDir
# @deps nimc
import "$nim"/compiler/[ast]
# @deps tests
import minitest
# @deps nonim
import ../cli
import ../nimc/Typed
import ../ast/convert
import ../codegen/C
import ../codegen/output


const cases_dir = currentSourcePath().parentDir()/".."/"backend"/"test"/"cases"

let compiler = Typed.Compiler.create()

proc generate_from (name :string) :string=
  let source = readFile(cases_dir/name/"input.nim")
  let compiled = compiler.compile(source, cases_dir/name/"input.nim")
  var root = newNode(nkStmtList)
  for statement in compiled.statements:
    root.add(statement)
  let converted = convert.convert(root, cases_dir/name/"input.nim")
  let output = converted.C()
  return output.modules[0].definitions

proc case_expected_c (name :string) :string=
  readFile(cases_dir/name/"expected.c")


describe "nonim.cli.cleanc | Variables":
  it "must generate static const int from let binding", proc() =
    let result = generate_from("variable")
    result.eq case_expected_c("variable")

  it "must generate static mutable int from var binding", proc() =
    let result = generate_from("variable_var")
    result.eq case_expected_c("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_from("variable_exported")
    result.eq case_expected_c("variable_exported")

describe "nonim.cli.cleanc | Procedures":
  it "must generate a static forward declaration", proc() =
    let result = generate_from("procedure")
    result.eq case_expected_c("procedure")
