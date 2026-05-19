#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for the zig backend.
#__________________________________|
# @deps std
from std/os import `/`, parentDir, execShellCmd
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
  return astTF.convert(root, astTF.Language.Zig)

proc generate_zig (source :string) :string=
  let output = nonim.codegen.zig(typed_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  readFile(cases_dir/name/"input.nim")

proc case_expected (name :string) :string=
  readFile(cases_dir/name/"expected.zig")


describe "nonim.zig | astTF Phase Landmarks":
  it "must generate a complete Phase 0 program", proc() =
    let result = generate_zig(case_input("phase0"))
    result.eq case_expected("phase0")

  it "must pass zig ast-check on Phase 0 output", proc() =
    let code = execShellCmd("zig ast-check " & cases_dir/"phase0"/"expected.zig")
    code.eq 0

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

  it "must generate multiple bindings", proc() =
    let result = generate_zig(case_input("variable_multi"))
    result.eq case_expected("variable_multi")

describe "nonim.zig | Procedures":
  it "must generate a fn with body", proc() =
    let result = generate_zig(case_input("procedure_body"))
    result.eq case_expected("procedure_body")

  it "must generate pub fn for exported procedure", proc() =
    let result = generate_zig(case_input("procedure_exported"))
    result.eq case_expected("procedure_exported")

  it "must generate a function call expression", proc() =
    let result = generate_zig(case_input("expression_call"))
    result.eq case_expected("expression_call")

describe "nonim.zig | Types":
  it "must generate a struct from object type", proc() =
    let result = generate_zig(case_input("type_object"))
    result.eq case_expected("type_object")

describe "nonim.zig | Discard":
  it "must generate discard as _ = expr", proc() =
    let result = generate_zig(case_input("statement_discard"))
    result.eq case_expected("statement_discard")

describe "nonim.zig | Control Flow":
  it "must generate if/else from Nim if/else", proc() =
    let result = generate_zig(case_input("control_if"))
    result.eq case_expected("control_if")

  it "must generate while loop", proc() =
    let result = generate_zig(case_input("control_while"))
    result.eq case_expected("control_while")

  it "must generate break inside loop", proc() =
    let result = generate_zig(case_input("statement_break"))
    result.eq case_expected("statement_break")

  it "must generate continue inside loop", proc() =
    let result = generate_zig(case_input("statement_continue"))
    result.eq case_expected("statement_continue")

describe "nonim.zig | Literals":
  it "must generate bool literals", proc() =
    let result = generate_zig(case_input("literal_bool"))
    result.eq case_expected("literal_bool")

  it "must generate nil as null", proc() =
    let result = generate_zig(case_input("literal_nil"))
    result.eq case_expected("literal_nil")

  it "must generate float literal", proc() =
    let result = generate_zig(case_input("literal_float"))
    result.eq case_expected("literal_float")

  it "must generate string literal", proc() =
    let result = generate_zig(case_input("literal_string"))
    result.eq case_expected("literal_string")

  it "must generate char literal", proc() =
    let result = generate_zig(case_input("literal_char"))
    result.eq case_expected("literal_char")

describe "nonim.zig | Types":
  it "must translate primitive types correctly", proc() =
    let result = generate_zig(case_input("type_primitive"))
    result.eq case_expected("type_primitive")

  it "must generate a pointer type", proc() =
    let result = generate_zig(case_input("type_ptr"))
    result.eq case_expected("type_ptr")

describe "nonim.zig | Expressions":
  it "must generate array indexing", proc() =
    let result = generate_zig(case_input("expression_indexed"))
    result.eq case_expected("expression_indexed")

describe "nonim.zig | Operators":
  it "must translate Nim operators to Zig operators", proc() =
    let result = generate_zig(case_input("expression_operator"))
    result.eq case_expected("expression_operator")

describe "nonim.zig | Passthrough":
  it "must emit raw code from emit pragma", proc() =
    let result = generate_zig(case_input("statement_passthrough"))
    result.eq case_expected("statement_passthrough")

