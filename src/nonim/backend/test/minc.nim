#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the minc (untyped C) backend.
#_______________________________________________________________|
# @deps std
from std/os import `/`, parentDir, fileExists, execShellCmd, createDir
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

proc generate_h (source :string) :string=
  let output = nonim.codegen.C(untyped_ast(source))
  return output.modules[0].declarations

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

proc generate_h_file (name :string) :string=
  let untyped_c = cases_dir/name/"input.untyped_c.nim"
  let c_path = cases_dir/name/"input.c.nim"
  let input_path = if fileExists(untyped_c): untyped_c
                   elif fileExists(c_path): c_path
                   else: cases_dir/name/"input.nim"
  let source = preprocess.processIncludes(readFile(input_path), input_path)
  let output = nonim.codegen.C(untyped_ast(source))
  return output.modules[0].declarations

proc case_expected_c (name :string) :string=
  let untyped_path = cases_dir/name/"expected.untyped.c"
  if fileExists(untyped_path): return readFile(untyped_path)
  readFile(cases_dir/name/"expected.c")

proc case_expected_h (name :string) :string=
  let untyped_path = cases_dir/name/"expected.untyped.h"
  if fileExists(untyped_path): return readFile(untyped_path)
  readFile(cases_dir/name/"expected.h")


describe "nonim.minc | astTF Phase Landmarks":
  it "must generate a complete Phase 0 program", proc() =
    let result = generate_c(case_input("phase0"))
    result.eq case_expected_c("phase0")
    generate_h(case_input("phase0")).eq case_expected_h("phase0")

  it "must pass clang syntax check on Phase 0 output", proc() =
    let dir = "./bin/.tests/minc/phase0"
    createDir(dir)
    writeFile(dir/"input.h", case_expected_h("phase0"))
    writeFile(dir/"input.c", case_expected_c("phase0"))
    let code = execShellCmd("clang -fsyntax-only " & dir/"input.c")
    code.eq 0

describe "nonim.minc | Variables":
  it "must generate a public const int from let binding", proc() =
    let result = generate_c(case_input("variable"))
    result.eq case_expected_c("variable")
    generate_h(case_input("variable")).eq case_expected_h("variable")

  it "must generate a public mutable int from var binding", proc() =
    let result = generate_c(case_input("variable_var"))
    result.eq case_expected_c("variable_var")
    generate_h(case_input("variable_var")).eq case_expected_h("variable_var")

  it "must omit static for exported let binding", proc() =
    let result = generate_c(case_input("variable_exported"))
    result.eq case_expected_c("variable_exported")
    generate_h(case_input("variable_exported")).eq case_expected_h("variable_exported")

  it "must generate multiple bindings", proc() =
    let result = generate_c(case_input("variable_multi"))
    result.eq case_expected_c("variable_multi")
    generate_h(case_input("variable_multi")).eq case_expected_h("variable_multi")

  it "must generate a declaration without initializer from an underscore value", proc() =
    let result = generate_c(case_input("variable_undefined"))
    result.eq case_expected_c("variable_undefined")
    generate_h(case_input("variable_undefined")).eq case_expected_h("variable_undefined")

describe "nonim.minc | Procedures":
  it "must generate a public forward declaration", proc() =
    let result = generate_c(case_input("procedure"))
    result.eq case_expected_c("procedure")
    generate_h(case_input("procedure")).eq case_expected_h("procedure")

  it "must generate a procedure with body", proc() =
    let result = generate_c(case_input("procedure_body"))
    result.eq case_expected_c("procedure_body")
    generate_h(case_input("procedure_body")).eq case_expected_h("procedure_body")

  it "must omit static for exported procedure", proc() =
    let result = generate_c(case_input("procedure_exported"))
    result.eq case_expected_c("procedure_exported")
    generate_h(case_input("procedure_exported")).eq case_expected_h("procedure_exported")

  it "must generate a function call expression", proc() =
    let result = generate_c(case_input("expression_call"))
    result.eq case_expected_c("expression_call")
    generate_h(case_input("expression_call")).eq case_expected_h("expression_call")

  it "must generate inline procedure", proc() =
    let result = generate_c(case_input("procedure_inline"))
    result.eq case_expected_c("procedure_inline")
    generate_h(case_input("procedure_inline")).eq case_expected_h("procedure_inline")

  it "must generate extern forward declaration", proc() =
    let result = generate_c(case_input("procedure_extern"))
    result.eq case_expected_c("procedure_extern")
    generate_h(case_input("procedure_extern")).eq case_expected_h("procedure_extern")

  it "must generate variadic parameter", proc() =
    let result = generate_c(case_input("procedure_varargs"))
    result.eq case_expected_c("procedure_varargs")
    generate_h(case_input("procedure_varargs")).eq case_expected_h("procedure_varargs")

describe "nonim.minc | Literals":
  it "must generate bool literals", proc() =
    let result = generate_c(case_input("literal_bool"))
    result.eq case_expected_c("literal_bool")
    generate_h(case_input("literal_bool")).eq case_expected_h("literal_bool")

  it "must generate nil as NULL", proc() =
    let result = generate_c(case_input("literal_nil"))
    result.eq case_expected_c("literal_nil")
    generate_h(case_input("literal_nil")).eq case_expected_h("literal_nil")

  it "must generate float literal", proc() =
    let result = generate_c(case_input("literal_float"))
    result.eq case_expected_c("literal_float")
    generate_h(case_input("literal_float")).eq case_expected_h("literal_float")

  it "must generate string literal", proc() =
    let result = generate_c(case_input("literal_string"))
    result.eq case_expected_c("literal_string")
    generate_h(case_input("literal_string")).eq case_expected_h("literal_string")

  it "must generate char literal", proc() =
    let result = generate_c(case_input("literal_char"))
    result.eq case_expected_c("literal_char")
    generate_h(case_input("literal_char")).eq case_expected_h("literal_char")

  it "must generate concatenated lines from raw triple-quoted string", proc() =
    let result = generate_c(case_input("literal_string_raw"))
    result.eq case_expected_c("literal_string_raw")
    generate_h(case_input("literal_string_raw")).eq case_expected_h("literal_string_raw")

  it "must generate concatenated lines from triple-quoted string", proc() =
    let result = generate_c(case_input("literal_string_triple"))
    result.eq case_expected_c("literal_string_triple")
    generate_h(case_input("literal_string_triple")).eq case_expected_h("literal_string_triple")

describe "nonim.minc | Control Flow":
  it "must generate if/else", proc() =
    let result = generate_c(case_input("control_if"))
    result.eq case_expected_c("control_if")
    generate_h(case_input("control_if")).eq case_expected_h("control_if")

  it "must generate while loop", proc() =
    let result = generate_c(case_input("control_while"))
    result.eq case_expected_c("control_while")
    generate_h(case_input("control_while")).eq case_expected_h("control_while")

  it "must generate break inside loop", proc() =
    let result = generate_c(case_input("statement_break"))
    result.eq case_expected_c("statement_break")
    generate_h(case_input("statement_break")).eq case_expected_h("statement_break")

  it "must generate continue inside loop", proc() =
    let result = generate_c(case_input("statement_continue"))
    result.eq case_expected_c("statement_continue")
    generate_h(case_input("statement_continue")).eq case_expected_h("statement_continue")

  it "must generate switch from case/of", proc() =
    let result = generate_c(case_input("control_case"))
    result.eq case_expected_c("control_case")
    generate_h(case_input("control_case")).eq case_expected_h("control_case")

  it "must generate fall-through labels from multi-value case/of", proc() =
    let result = generate_c(case_input("control_case_multi"))
    result.eq case_expected_c("control_case_multi")
    generate_h(case_input("control_case_multi")).eq case_expected_h("control_case_multi")

  it "must generate nested switch", proc() =
    let result = generate_c(case_input("control_case_nested"))
    result.eq case_expected_c("control_case_nested")
    generate_h(case_input("control_case_nested")).eq case_expected_h("control_case_nested")

  it "must generate for loop from exclusive range", proc() =
    let result = generate_c(case_input("control_for_range"))
    result.eq case_expected_c("control_for_range")
    generate_h(case_input("control_for_range")).eq case_expected_h("control_for_range")

  it "must generate for loop from inclusive range", proc() =
    let result = generate_c(case_input("control_for_range_inclusive"))
    result.eq case_expected_c("control_for_range_inclusive")
    generate_h(case_input("control_for_range_inclusive")).eq case_expected_h("control_for_range_inclusive")

  it "must generate if/elif/else from single-line branches", proc() =
    let result = generate_c(case_input("control_if_inline"))
    result.eq case_expected_c("control_if_inline")
    generate_h(case_input("control_if_inline")).eq case_expected_h("control_if_inline")

describe "nonim.minc | Statements":
  it "must generate discard as (void) cast", proc() =
    let result = generate_c(case_input("statement_discard"))
    result.eq case_expected_c("statement_discard")
    generate_h(case_input("statement_discard")).eq case_expected_h("statement_discard")

  it "must generate one discard per element from tuple discard", proc() =
    let result = generate_c(case_input("statement_discard_tuple"))
    result.eq case_expected_c("statement_discard_tuple")
    generate_h(case_input("statement_discard_tuple")).eq case_expected_h("statement_discard_tuple")

  it "must generate empty block from bare discard", proc() =
    let result = generate_c(case_input("statement_discard_bare"))
    result.eq case_expected_c("statement_discard_bare")
    generate_h(case_input("statement_discard_bare")).eq case_expected_h("statement_discard_bare")

describe "nonim.minc | Types":
  it "must generate a struct from object type", proc() =
    let result = generate_c(case_input("type_object"))
    result.eq case_expected_c("type_object")
    generate_h(case_input("type_object")).eq case_expected_h("type_object")

  it "must generate a pointer type", proc() =
    let result = generate_c(case_input("type_ptr"))
    result.eq case_expected_c("type_ptr")
    generate_h(case_input("type_ptr")).eq case_expected_h("type_ptr")

  it "must translate primitive types correctly", proc() =
    let result = generate_c(case_input("type_primitive"))
    result.eq case_expected_c("type_primitive")
    generate_h(case_input("type_primitive")).eq case_expected_h("type_primitive")

  it "must generate nested pointer type", proc() =
    let result = generate_c(case_input("type_ptr_nested"))
    result.eq case_expected_c("type_ptr_nested")
    generate_h(case_input("type_ptr_nested")).eq case_expected_h("type_ptr_nested")

  it "must generate typedef enum", proc() =
    let result = generate_c(case_input("type_enum"))
    result.eq case_expected_c("type_enum")
    generate_h(case_input("type_enum")).eq case_expected_h("type_enum")

  it "must generate typedef enum with explicit values", proc() =
    let result = generate_c(case_input("type_enum_values"))
    result.eq case_expected_c("type_enum_values")
    generate_h(case_input("type_enum_values")).eq case_expected_h("type_enum_values")

  it "must generate typedef from type alias", proc() =
    let result = generate_c(case_input("type_alias"))
    result.eq case_expected_c("type_alias")
    generate_h(case_input("type_alias")).eq case_expected_h("type_alias")

  it "must generate function pointer typedef from procedure type", proc() =
    let result = generate_c(case_input("type_procedure"))
    result.eq case_expected_c("type_procedure")
    generate_h(case_input("type_procedure")).eq case_expected_h("type_procedure")

  it "must generate function pointer struct field", proc() =
    let result = generate_c(case_input("type_object_procedure_field"))
    result.eq case_expected_c("type_object_procedure_field")
    generate_h(case_input("type_object_procedure_field")).eq case_expected_h("type_object_procedure_field")

  it "must generate array struct field with its length", proc() =
    let result = generate_c(case_input("type_object_array_field"))
    result.eq case_expected_c("type_object_array_field")
    generate_h(case_input("type_object_array_field")).eq case_expected_h("type_object_array_field")

  it "must generate array struct field with a call as its length", proc() =
    let result = generate_c(case_input("type_array_call_length"))
    result.eq case_expected_c("type_array_call_length")
    generate_h(case_input("type_array_call_length")).eq case_expected_h("type_array_call_length")

  it "must generate typedef of an existing C struct from stub object", proc() =
    let result = generate_c(case_input("type_object_stub"))
    result.eq case_expected_c("type_object_stub")
    generate_h(case_input("type_object_stub")).eq case_expected_h("type_object_stub")

  it "must generate struct fields declared in a group", proc() =
    let result = generate_c(case_input("type_object_fields_grouped"))
    result.eq case_expected_c("type_object_fields_grouped")
    generate_h(case_input("type_object_fields_grouped")).eq case_expected_h("type_object_fields_grouped")

  it "must generate typedef from multi-word type", proc() =
    let result = generate_c(case_input("type_multiword"))
    result.eq case_expected_c("type_multiword")
    generate_h(case_input("type_multiword")).eq case_expected_h("type_multiword")

describe "nonim.minc | Expressions":
  it "must generate array indexing", proc() =
    let result = generate_c(case_input("expression_indexed"))
    result.eq case_expected_c("expression_indexed")
    generate_h(case_input("expression_indexed")).eq case_expected_h("expression_indexed")

  it "must translate Nim operators to C operators", proc() =
    let result = generate_c(case_input("expression_operator"))
    result.eq case_expected_c("expression_operator")
    generate_h(case_input("expression_operator")).eq case_expected_h("expression_operator")

  it "must generate array literal", proc() =
    let result = generate_c(case_input("expression_array_literal"))
    result.eq case_expected_c("expression_array_literal")
    generate_h(case_input("expression_array_literal")).eq case_expected_h("expression_array_literal")

  it "must generate typed compound literal from anonymous object", proc() =
    let result = generate_c(case_input("expression_object"))
    result.eq case_expected_c("expression_object")
    generate_h(case_input("expression_object")).eq case_expected_h("expression_object")

  it "must generate zero-initialized compound literal from empty object", proc() =
    let result = generate_c(case_input("expression_empty_object"))
    result.eq case_expected_c("expression_empty_object")
    generate_h(case_input("expression_empty_object")).eq case_expected_h("expression_empty_object")

  it "must generate compound literal from named constructor", proc() =
    let result = generate_c(case_input("expression_named_constructor"))
    result.eq case_expected_c("expression_named_constructor")
    generate_h(case_input("expression_named_constructor")).eq case_expected_h("expression_named_constructor")

  it "must generate labeled block expression", proc() =
    let result = generate_c(case_input("expression_block"))
    result.eq case_expected_c("expression_block")
    generate_h(case_input("expression_block")).eq case_expected_h("expression_block")

  it "must generate unnamed block expression", proc() =
    let result = generate_c(case_input("expression_block_unnamed"))
    result.eq case_expected_c("expression_block_unnamed")
    generate_h(case_input("expression_block_unnamed")).eq case_expected_h("expression_block_unnamed")

  it "must generate ternary from if expression", proc() =
    let result = generate_c(case_input("expression_conditional_value"))
    result.eq case_expected_c("expression_conditional_value")
    generate_h(case_input("expression_conditional_value")).eq case_expected_h("expression_conditional_value")

  it "must generate chained ternaries from case expression", proc() =
    let result = generate_c(case_input("expression_case_value"))
    result.eq case_expected_c("expression_case_value")
    generate_h(case_input("expression_case_value")).eq case_expected_h("expression_case_value")

  it "must generate address operator from addr", proc() =
    let result = generate_c(case_input("expression_addr"))
    result.eq case_expected_c("expression_addr")
    generate_h(case_input("expression_addr")).eq case_expected_h("expression_addr")

  it "must generate prefix dereference", proc() =
    let result = generate_c(case_input("expression_deref"))
    result.eq case_expected_c("expression_deref")
    generate_h(case_input("expression_deref")).eq case_expected_h("expression_deref")

  it "must generate cast from infix @", proc() =
    let result = generate_c(case_input("expression_cast_infix"))
    result.eq case_expected_c("expression_cast_infix")
    generate_h(case_input("expression_cast_infix")).eq case_expected_h("expression_cast_infix")

  it "must generate cast from @cast builtin", proc() =
    let result = generate_c(case_input("expression_cast_builtin"))
    result.eq case_expected_c("expression_cast_builtin")
    generate_h(case_input("expression_cast_builtin")).eq case_expected_h("expression_cast_builtin")

  it "must generate cast from as", proc() =
    let result = generate_c(case_input("expression_cast_as"))
    result.eq case_expected_c("expression_cast_as")
    generate_h(case_input("expression_cast_as")).eq case_expected_h("expression_cast_as")

describe "nonim.minc | Visibility":
  it "must generate static from private var binding", proc() =
    let result = generate_c(case_input("variable_var_private"))
    result.eq case_expected_c("variable_var_private")

  it "must generate static from private procedure", proc() =
    let result = generate_c(case_input("procedure_private"))
    result.eq case_expected_c("procedure_private")

describe "nonim.minc | Comptime":
  it "must generate defines from define pragmas", proc() =
    let result = generate_c(case_input("pragma_define"))
    result.eq case_expected_c("pragma_define")
    generate_h(case_input("pragma_define")).eq case_expected_h("pragma_define")

  it "must generate comptime conditionals from when", proc() =
    let result = generate_c(case_input("statement_when"))
    result.eq case_expected_c("statement_when")
    generate_h(case_input("statement_when")).eq case_expected_h("statement_when")

describe "nonim.minc | Passthrough":
  it "must emit raw code from emit pragma", proc() =
    let result = generate_c(case_input("statement_passthrough"))
    result.eq case_expected_c("statement_passthrough")

describe "nonim.minc | Comments":
  it "must generate a doc comment", proc() =
    let result = generate_c(case_input("statement_comment"))
    result.eq case_expected_c("statement_comment")

describe "nonim.minc | Includes":
  it "must generate a global include with angle brackets", proc() =
    let result = generate_c(case_input("include_global"))
    result.eq case_expected_c("include_global")
    generate_h(case_input("include_global")).eq case_expected_h("include_global")

  it "must generate a local include with quotes", proc() =
    let result = generate_c(case_input("include_local"))
    result.eq case_expected_c("include_local")
    generate_h(case_input("include_local")).eq case_expected_h("include_local")

  it "must inline extensionless include via preprocessor", proc() =
    let result = generate_c_file("include_recursive")
    result.eq case_expected_c("include_recursive")
    generate_h_file("include_recursive").eq case_expected_h("include_recursive")

  it "must inline nested recursive includes", proc() =
    let result = generate_c_file("include_nested")
    result.eq case_expected_c("include_nested")
    generate_h_file("include_nested").eq case_expected_h("include_nested")
