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
import ../../backend/preprocess


const cases_dir = currentSourcePath().parentDir()/"cases"

proc untyped_ast (source :string) :astTF.Ast=
  let root = Untyped.compile(source)
  return astTF.convert(root, astTF.Language.C, typed=false)

proc generate_c (source :string) :string=
  let output = nonim.codegen.C(untyped_ast(source))
  return output.modules[0].definitions

proc case_input (name :string) :string=
  let untyped_c = cases_dir/name/"input.untyped_c.nim"
  if fileExists(untyped_c): return readFile(untyped_c)
  let c_path = cases_dir/name/"input.c.nim"
  if fileExists(c_path): return readFile(c_path)
  readFile(cases_dir/name/"input.nim")

proc generate_c_file (name :string) :string=
  let untyped_c = cases_dir/name/"input.untyped_c.nim"
  let c_path = cases_dir/name/"input.c.nim"
  let input_path = if fileExists(untyped_c): untyped_c
                   elif fileExists(c_path): c_path
                   else: cases_dir/name/"input.nim"
  let source = preprocess.processIncludes(readFile(input_path), input_path)
  let output = nonim.codegen.C(untyped_ast(source))
  return output.modules[0].definitions

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
  it "must generate a public const int from let binding", proc() =
    let result = generate_c(case_input("variable"))
    result.eq case_expected("variable")

  it "must generate a public mutable int from var binding", proc() =
    let result = generate_c(case_input("variable_var"))
    result.eq case_expected("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_c(case_input("variable_exported"))
    result.eq case_expected("variable_exported")

  it "must generate multiple bindings", proc() =
    let result = generate_c(case_input("variable_multi"))
    result.eq case_expected("variable_multi")

  it "must generate a declaration without initializer from an underscore value", proc() =
    let result = generate_c(case_input("variable_undefined"))
    result.eq case_expected("variable_undefined")

describe "nonim.minc | Procedures":
  it "must generate a public forward declaration", proc() =
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

  it "must generate inline procedure", proc() =
    let result = generate_c(case_input("procedure_inline"))
    result.eq case_expected("procedure_inline")

  it "must generate extern forward declaration", proc() =
    let result = generate_c(case_input("procedure_extern"))
    result.eq case_expected("procedure_extern")

  it "must generate variadic parameter", proc() =
    let result = generate_c(case_input("procedure_varargs"))
    result.eq case_expected("procedure_varargs")

describe "nonim.minc | Literals":
  it "must generate bool literals", proc() =
    let result = generate_c(case_input("literal_bool"))
    result.eq case_expected("literal_bool")

  it "must generate nil as NULL", proc() =
    let result = generate_c(case_input("literal_nil"))
    result.eq case_expected("literal_nil")

  it "must generate float literal", proc() =
    let result = generate_c(case_input("literal_float"))
    result.eq case_expected("literal_float")

  it "must generate string literal", proc() =
    let result = generate_c(case_input("literal_string"))
    result.eq case_expected("literal_string")

  it "must generate char literal", proc() =
    let result = generate_c(case_input("literal_char"))
    result.eq case_expected("literal_char")

  it "must generate concatenated lines from raw triple-quoted string", proc() =
    let result = generate_c(case_input("literal_string_raw"))
    result.eq case_expected("literal_string_raw")

  it "must generate concatenated lines from triple-quoted string", proc() =
    let result = generate_c(case_input("literal_string_triple"))
    result.eq case_expected("literal_string_triple")

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

  it "must generate switch from case/of", proc() =
    let result = generate_c(case_input("control_case"))
    result.eq case_expected("control_case")

  it "must generate fall-through labels from multi-value case/of", proc() =
    let result = generate_c(case_input("control_case_multi"))
    result.eq case_expected("control_case_multi")

  it "must generate nested switch", proc() =
    let result = generate_c(case_input("control_case_nested"))
    result.eq case_expected("control_case_nested")

  it "must generate for loop from exclusive range", proc() =
    let result = generate_c(case_input("control_for_range"))
    result.eq case_expected("control_for_range")

  it "must generate for loop from inclusive range", proc() =
    let result = generate_c(case_input("control_for_range_inclusive"))
    result.eq case_expected("control_for_range_inclusive")

  it "must generate if/elif/else from single-line branches", proc() =
    let result = generate_c(case_input("control_if_inline"))
    result.eq case_expected("control_if_inline")

describe "nonim.minc | Statements":
  it "must generate discard as (void) cast", proc() =
    let result = generate_c(case_input("statement_discard"))
    result.eq case_expected("statement_discard")

  it "must generate one discard per element from tuple discard", proc() =
    let result = generate_c(case_input("statement_discard_tuple"))
    result.eq case_expected("statement_discard_tuple")

  it "must generate empty block from bare discard", proc() =
    let result = generate_c(case_input("statement_discard_bare"))
    result.eq case_expected("statement_discard_bare")

describe "nonim.minc | Types":
  it "must generate a struct from object type", proc() =
    let result = generate_c(case_input("type_object"))
    result.eq case_expected("type_object")

  it "must generate a pointer type", proc() =
    let result = generate_c(case_input("type_ptr"))
    result.eq case_expected("type_ptr")

  it "must translate primitive types correctly", proc() =
    let result = generate_c(case_input("type_primitive"))
    result.eq case_expected("type_primitive")

  it "must generate nested pointer type", proc() =
    let result = generate_c(case_input("type_ptr_nested"))
    result.eq case_expected("type_ptr_nested")

  it "must generate typedef enum", proc() =
    let result = generate_c(case_input("type_enum"))
    result.eq case_expected("type_enum")

  it "must generate typedef enum with explicit values", proc() =
    let result = generate_c(case_input("type_enum_values"))
    result.eq case_expected("type_enum_values")

  it "must generate typedef from type alias", proc() =
    let result = generate_c(case_input("type_alias"))
    result.eq case_expected("type_alias")

  it "must generate function pointer typedef from procedure type", proc() =
    let result = generate_c(case_input("type_procedure"))
    result.eq case_expected("type_procedure")

  it "must generate function pointer struct field", proc() =
    let result = generate_c(case_input("type_object_procedure_field"))
    result.eq case_expected("type_object_procedure_field")

  it "must generate array struct field with its length", proc() =
    let result = generate_c(case_input("type_object_array_field"))
    result.eq case_expected("type_object_array_field")

  it "must generate typedef of an existing C struct from stub object", proc() =
    let result = generate_c(case_input("type_object_stub"))
    result.eq case_expected("type_object_stub")

  it "must generate struct fields declared in a group", proc() =
    let result = generate_c(case_input("type_object_fields_grouped"))
    result.eq case_expected("type_object_fields_grouped")

  it "must generate typedef from multi-word type", proc() =
    let result = generate_c(case_input("type_multiword"))
    result.eq case_expected("type_multiword")

describe "nonim.minc | Expressions":
  it "must generate array indexing", proc() =
    let result = generate_c(case_input("expression_indexed"))
    result.eq case_expected("expression_indexed")

  it "must translate Nim operators to C operators", proc() =
    let result = generate_c(case_input("expression_operator"))
    result.eq case_expected("expression_operator")

  it "must generate array literal", proc() =
    let result = generate_c(case_input("expression_array_literal"))
    result.eq case_expected("expression_array_literal")

  it "must generate typed compound literal from anonymous object", proc() =
    let result = generate_c(case_input("expression_object"))
    result.eq case_expected("expression_object")

  it "must generate compound literal from named constructor", proc() =
    let result = generate_c(case_input("expression_named_constructor"))
    result.eq case_expected("expression_named_constructor")

  it "must generate labeled block expression", proc() =
    let result = generate_c(case_input("expression_block"))
    result.eq case_expected("expression_block")

  it "must generate unnamed block expression", proc() =
    let result = generate_c(case_input("expression_block_unnamed"))
    result.eq case_expected("expression_block_unnamed")

  it "must generate ternary from if expression", proc() =
    let result = generate_c(case_input("expression_conditional_value"))
    result.eq case_expected("expression_conditional_value")

  it "must generate chained ternaries from case expression", proc() =
    let result = generate_c(case_input("expression_case_value"))
    result.eq case_expected("expression_case_value")

  it "must generate address operator from addr", proc() =
    let result = generate_c(case_input("expression_addr"))
    result.eq case_expected("expression_addr")

  it "must generate prefix dereference", proc() =
    let result = generate_c(case_input("expression_deref"))
    result.eq case_expected("expression_deref")

  it "must generate cast from infix @", proc() =
    let result = generate_c(case_input("expression_cast_infix"))
    result.eq case_expected("expression_cast_infix")

  it "must generate cast from @cast builtin", proc() =
    let result = generate_c(case_input("expression_cast_builtin"))
    result.eq case_expected("expression_cast_builtin")

  it "must generate cast from as", proc() =
    let result = generate_c(case_input("expression_cast_as"))
    result.eq case_expected("expression_cast_as")

describe "nonim.minc | Visibility":
  it "must generate static from private var binding", proc() =
    let result = generate_c(case_input("variable_var_private"))
    result.eq case_expected("variable_var_private")

  it "must generate static from private procedure", proc() =
    let result = generate_c(case_input("procedure_private"))
    result.eq case_expected("procedure_private")

describe "nonim.minc | Comptime":
  it "must generate defines from define pragmas", proc() =
    let result = generate_c(case_input("pragma_define"))
    result.eq case_expected("pragma_define")

  it "must generate comptime conditionals from when", proc() =
    let result = generate_c(case_input("statement_when"))
    result.eq case_expected("statement_when")

describe "nonim.minc | Passthrough":
  it "must emit raw code from emit pragma", proc() =
    let result = generate_c(case_input("statement_passthrough"))
    result.eq case_expected("statement_passthrough")

describe "nonim.minc | Comments":
  it "must generate a doc comment", proc() =
    let result = generate_c(case_input("statement_comment"))
    result.eq case_expected("statement_comment")

describe "nonim.minc | Includes":
  it "must generate a global include with angle brackets", proc() =
    let result = generate_c(case_input("include_global"))
    result.eq case_expected("include_global")

  it "must generate a local include with quotes", proc() =
    let result = generate_c(case_input("include_local"))
    result.eq case_expected("include_local")

  it "must inline extensionless include via preprocessor", proc() =
    let result = generate_c_file("include_recursive")
    result.eq case_expected("include_recursive")

  it "must inline nested recursive includes", proc() =
    let result = generate_c_file("include_nested")
    result.eq case_expected("include_nested")
