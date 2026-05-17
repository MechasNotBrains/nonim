#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for the clean backend.
## Each test compiles Nim source through sem, converts to astTF,
## then generates output and checks it matches expected.
#___________________________________________________________________|
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

proc generate_nim (source :string) :string=
  let output = nonim.codegen.nim(typed_ast(source))
  return output.modules[0].definitions

proc generate_c (source :string) :string=
  let output = nonim.codegen.C(typed_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected_nim (name :string) :string=
  readFile(cases_dir/name/"expected.nim")

proc case_expected_c (name :string) :string=
  readFile(cases_dir/name/"expected.c")


describe "nonim.cleanc.nim | Variables":
  it "must roundtrip a let binding", proc() =
    let result = generate_nim(case_input("variable"))
    result.eq case_expected_nim("variable")

describe "nonim.cleanc.nim | Procedures":
  todo_it "must roundtrip a proc with body", proc() =
    let result = generate_nim(case_input("procedure_body"))
    result.eq case_expected_nim("procedure_body")

describe "nonim.cleanc.c | Variables":
  it "must generate static const int from let binding", proc() =
    let result = generate_c(case_input("variable"))
    result.eq case_expected_c("variable")

  it "must generate static mutable int from var binding", proc() =
    let result = generate_c(case_input("variable_var"))
    result.eq case_expected_c("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_c(case_input("variable_exported"))
    result.eq case_expected_c("variable_exported")

describe "nonim.cleanc.c | Procedures":
  it "must generate a procedure with body", proc() =
    let result = generate_c(case_input("procedure_body"))
    result.eq case_expected_c("procedure_body")

  it "must omit static for exported procedure", proc() =
    let result = generate_c(case_input("procedure_exported"))
    result.eq case_expected_c("procedure_exported")

