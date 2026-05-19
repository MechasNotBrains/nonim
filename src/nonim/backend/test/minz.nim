#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the minz (untyped Zig) backend.
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
import ../../backend/preprocess
import ../../backend/postprocess


const cases_dir = currentSourcePath().parentDir()/"cases"

proc untyped_ast (source :string) :astTF.Ast=
  let root = Untyped.compile(source)
  return astTF.convert(root, astTF.Language.Zig, typed=false)

proc generate_zig (source :string) :string=
  let output = nonim.codegen.zig(untyped_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  let zig_path = cases_dir/name/"input.untyped_zig.nim"
  if fileExists(zig_path): return readFile(zig_path)
  readFile(cases_dir/name/"input.nim")

proc generate_zig_file (name :string) :string=
  let zig_input = cases_dir/name/"input.untyped_zig.nim"
  let input_path = if fileExists(zig_input): zig_input
                   else: cases_dir/name/"input.nim"
  let source = preprocess.processIncludes(readFile(input_path), input_path)
  var definitions = nonim.codegen.zig(untyped_ast(source)).modules[0].definitions
  return postprocess.processZigIncludes(definitions, input_path)

proc case_expected (name :string) :string=
  let untyped_path = cases_dir/name/"expected.untyped.zig"
  if fileExists(untyped_path): return readFile(untyped_path)
  readFile(cases_dir/name/"expected.zig")


describe "nonim.minz | astTF Phase Landmarks":
  it "must generate a complete Phase 0 program", proc() =
    let result = generate_zig(case_input("phase0"))
    result.eq case_expected("phase0")

  it "must pass zig ast-check on Phase 0 output", proc() =
    let code = execShellCmd("zig ast-check " & cases_dir/"phase0"/"expected.untyped.zig")
    code.eq 0

describe "nonim.minz | Variables":
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

describe "nonim.minz | Procedures":
  it "must generate a forward declaration", proc() =
    let result = generate_zig(case_input("procedure"))
    result.eq case_expected("procedure")

  it "must generate a procedure with body", proc() =
    let result = generate_zig(case_input("procedure_body"))
    result.eq case_expected("procedure_body")

  it "must generate pub fn for exported procedure", proc() =
    let result = generate_zig(case_input("procedure_exported"))
    result.eq case_expected("procedure_exported")

  it "must generate a function call expression", proc() =
    let result = generate_zig(case_input("expression_call"))
    result.eq case_expected("expression_call")

describe "nonim.minz | Literals":
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

describe "nonim.minz | Control Flow":
  it "must generate if/else", proc() =
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

describe "nonim.minz | Statements":
  it "must generate discard as _ = expr", proc() =
    let result = generate_zig(case_input("statement_discard"))
    result.eq case_expected("statement_discard")

describe "nonim.minz | Types":
  it "must generate a struct from object type", proc() =
    let result = generate_zig(case_input("type_object"))
    result.eq case_expected("type_object")

  it "must generate a pointer type", proc() =
    let result = generate_zig(case_input("type_ptr"))
    result.eq case_expected("type_ptr")

  it "must translate primitive types correctly", proc() =
    let result = generate_zig(case_input("type_primitive"))
    result.eq case_expected("type_primitive")

describe "nonim.minz | Expressions":
  it "must generate array indexing", proc() =
    let result = generate_zig(case_input("expression_indexed"))
    result.eq case_expected("expression_indexed")

  it "must translate Nim operators to Zig operators", proc() =
    let result = generate_zig(case_input("expression_operator"))
    result.eq case_expected("expression_operator")

describe "nonim.minz | Passthrough":
  it "must emit raw code from emit pragma", proc() =
    let result = generate_zig(case_input("statement_passthrough"))
    result.eq case_expected("statement_passthrough")

describe "nonim.minz | Comments":
  it "must generate a doc comment", proc() =
    let result = generate_zig(case_input("statement_comment"))
    result.eq case_expected("statement_comment")

describe "nonim.minz | Includes":
  it "must inline a global include from a .zig file", proc() =
    let result = generate_zig_file("include_global")
    result.eq case_expected("include_global")

  it "must inline a local include from a .zig file", proc() =
    let result = generate_zig_file("include_local")
    result.eq case_expected("include_local")

  it "must inline extensionless include via preprocessor", proc() =
    let result = generate_zig_file("include_recursive")
    result.eq case_expected("include_recursive")

  it "must inline nested recursive includes", proc() =
    let result = generate_zig_file("include_nested")
    result.eq case_expected("include_nested")
