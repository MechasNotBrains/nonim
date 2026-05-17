#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for the zig backend.
#__________________________________|
# @deps std
from std/os import `/`, parentDir
# @deps nimc
import "$nim"/compiler/[ast]
# @deps tests
import minitest
# @deps nonim
from ../../../nonim import nil
import ../../nimc/Typed
import ../../ast as astTF


const cases_dir = currentSourcePath().parentDir()/"cases"

let compiler = Typed.Compiler.create()

proc typed_ast (source :string) :astTF.Ast=
  let compiled = compiler.compile(source)
  var root     = newNode(nkStmtList)
  for statement in compiled.statements:
    root.add(statement)
  return astTF.convert(root)

proc generate_zig (source :string) :string=
  let output = nonim.codegen.zig(typed_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected (name :string) :string=
  readFile(cases_dir/name/"expected.zig")


describe "nonim.zig | Variables":
  it "must generate const from let binding", proc() =
    let result = generate_zig(case_input("variable"))
    result.eq case_expected("variable")

  it "must generate var from var binding", proc() =
    let result = generate_zig(case_input("variable_var"))
    result.eq case_expected("variable_var")

  it "must generate pub const for exported let binding", proc() =
    let result = generate_zig(case_input("variable_exported"))
    result.eq case_expected("variable_exported")

describe "nonim.zig | Procedures":
  it "must generate a fn with body", proc() =
    let result = generate_zig(case_input("procedure_body"))
    result.eq case_expected("procedure_body")

