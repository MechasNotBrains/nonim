#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the minc (untyped C) backend.
#_______________________________________________________________|
# @deps std
from std/os import `/`, parentDir, fileExists, execShellCmd
# @deps nimc
import "$nim"/compiler/[ast]
# @deps tests
import minitest
# @deps nonim
from ../../../nonim import nil
import ../../nimc/Untyped
import ../../ast as astTF


const cases_dir = currentSourcePath().parentDir()/"cases"

proc untyped_ast (source :string) :astTF.Ast=
  let root = Untyped.compile(source)
  return astTF.convert(root, astTF.Language.C, typed=false)

proc generate_c (source :string) :string=
  let output = nonim.codegen.C(untyped_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected (name :string) :string=
  let untyped_path = cases_dir/name/"expected.untyped.c"
  if fileExists(untyped_path): return readFile(untyped_path)
  readFile(cases_dir/name/"expected.c")


describe "nonim.minc | astTF Phase Landmarks":
  it "must generate a complete Phase 0 program", proc() =
    let result = generate_c(case_input("phase0"))
    result.eq case_expected("phase0")

  it "must pass clang syntax check on Phase 0 output", proc() =
    let code = execShellCmd("clang -fsyntax-only " & cases_dir/"phase0"/"expected.untyped.c")
    code.eq 0

describe "nonim.minc | Variables":
  it "must generate static const int from let binding", proc() =
    let result = generate_c(case_input("variable"))
    result.eq case_expected("variable")

  it "must generate static mutable int from var binding", proc() =
    let result = generate_c(case_input("variable_var"))
    result.eq case_expected("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_c(case_input("variable_exported"))
    result.eq case_expected("variable_exported")

  it "must generate multiple bindings", proc() =
    let result = generate_c(case_input("variable_multi"))
    result.eq case_expected("variable_multi")

describe "nonim.minc | Procedures":
  it "must generate a static forward declaration", proc() =
    let result = generate_c(case_input("procedure"))
    result.eq case_expected("procedure")

  it "must generate a procedure with body", proc() =
    let result = generate_c(case_input("procedure_body"))
    result.eq case_expected("procedure_body")

  it "must omit static for exported procedure", proc() =
    let result = generate_c(case_input("procedure_exported"))
    result.eq case_expected("procedure_exported")

  it "must generate a function call expression", proc() =
    let result = generate_c(case_input("expression_call"))
    result.eq case_expected("expression_call")

describe "nonim.minc | Control Flow":
  it "must generate if/else", proc() =
    let result = generate_c(case_input("control_if"))
    result.eq case_expected("control_if")

  it "must generate while loop", proc() =
    let result = generate_c(case_input("control_while"))
    result.eq case_expected("control_while")

  it "must generate break inside loop", proc() =
    let result = generate_c(case_input("statement_break"))
    result.eq case_expected("statement_break")

  it "must generate continue inside loop", proc() =
    let result = generate_c(case_input("statement_continue"))
    result.eq case_expected("statement_continue")

describe "nonim.minc | Statements":
  it "must generate discard as (void) cast", proc() =
    let result = generate_c(case_input("statement_discard"))
    result.eq case_expected("statement_discard")

describe "nonim.minc | Types":
  it "must generate a struct from object type", proc() =
    let result = generate_c(case_input("type_object"))
    result.eq case_expected("type_object")

  it "must translate primitive types correctly", proc() =
    let result = generate_c(case_input("type_primitive"))
    result.eq case_expected("type_primitive")

describe "nonim.minc | Expressions":
  it "must generate array indexing", proc() =
    let result = generate_c(case_input("expression_indexed"))
    result.eq case_expected("expression_indexed")

  it "must translate Nim operators to C operators", proc() =
    let result = generate_c(case_input("expression_operator"))
    result.eq case_expected("expression_operator")
