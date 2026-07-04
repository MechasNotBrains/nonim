#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the minz (untyped Zig) backend.
#_______________________________________________________________|
# nim r --outDir:bin/ --path:bin/.lib/minitest/src --path:bin/.lib/astTF/spec --path:bin/.lib/minibuild/src src/nonim/backend/test/minz.nim
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

  todo_it "must generate a complete Phase 2 program", proc() =
    let result = generate_zig(case_input("phase2"))
    result.eq case_expected("phase2")

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

  it "must carry the inline pragma onto the fn", proc() =
    let result = generate_zig(case_input("procedure_inline"))
    result.eq case_expected("procedure_inline")

  it "must generate a const binding inside a procedure body", proc() =
    let result = generate_zig(case_input("procedure_body_const"))
    result.eq case_expected("procedure_body_const")

  it "must unpack a tuple into one variable per value", proc() =
    let result = generate_zig(case_input("variable_tuple_unpack"))
    result.eq case_expected("variable_tuple_unpack")

  it "must unpack a tuple into variables inside a procedure body", proc() =
    let result = generate_zig(case_input("procedure_body_tuple_unpack"))
    result.eq case_expected("procedure_body_tuple_unpack")

  it "must carry the extern pragma onto the fn", proc() =
    let result = generate_zig(case_input("procedure_extern"))
    result.eq case_expected("procedure_extern")

  it "must generate error union return type", proc() =
    let result = generate_zig(case_input("procedure_error_union"))
    result.eq case_expected("procedure_error_union")

  it "must generate explicit error union return type", proc() =
    let result = generate_zig(case_input("procedure_error_union_explicit"))
    result.eq case_expected("procedure_error_union_explicit")

  it "must generate builtin call as return type", proc() =
    let result = generate_zig(case_input("procedure_return_builtin"))
    result.eq case_expected("procedure_return_builtin")

  it "must generate a function call expression", proc() =
    let result = generate_zig(case_input("expression_call"))
    result.eq case_expected("expression_call")

  it "must generate comptime parameter from comptime pragma", proc() =
    let result = generate_zig(case_input("procedure_comptime_param"))
    result.eq case_expected("procedure_comptime_param")

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

  it "must generate multiline string literal", proc() =
    let result = generate_zig(case_input("literal_string_multiline"))
    result.eq case_expected("literal_string_multiline")

  it "must generate char literal", proc() =
    let result = generate_zig(case_input("literal_char"))
    result.eq case_expected("literal_char")

describe "nonim.minz | Control Flow":
  todo_it "must generate if/else", proc() =
    let result = generate_zig(case_input("control_if"))
    result.eq case_expected("control_if")

  todo_it "must generate while loop", proc() =
    let result = generate_zig(case_input("control_while"))
    result.eq case_expected("control_while")

  todo_it "must generate for-in loop with const slice", proc() =
    let result = generate_zig(case_input("control_for"))
    result.eq case_expected("control_for")

  todo_it "must generate for-in loop with mutable slice", proc() =
    let result = generate_zig(case_input("control_for_mutable"))
    result.eq case_expected("control_for_mutable")

  todo_it "must generate for-in loop with counter", proc() =
    let result = generate_zig(case_input("control_for_counter"))
    result.eq case_expected("control_for_counter")

  todo_it "must generate while loop with capture", proc() =
    let result = generate_zig(case_input("control_while_capture"))
    result.eq case_expected("control_while_capture")

  todo_it "must generate if with capture", proc() =
    let result = generate_zig(case_input("control_if_capture"))
    result.eq case_expected("control_if_capture")

  it "must generate mixed braced/braceless if/else", proc() =
    let result = generate_zig(case_input("control_if_mixed"))
    result.eq case_expected("control_if_mixed")

  it "must generate if/else as expression value", proc() =
    let result = generate_zig(case_input("expression_conditional_value"))
    result.eq case_expected("expression_conditional_value")

  it "must generate case as expression value", proc() =
    let result = generate_zig(case_input("expression_case_value"))
    result.eq case_expected("expression_case_value")

  it "must generate break inside loop", proc() =
    let result = generate_zig(case_input("statement_break"))
    result.eq case_expected("statement_break")

  it "must generate continue inside loop", proc() =
    let result = generate_zig(case_input("statement_continue"))
    result.eq case_expected("statement_continue")

  todo_it "must generate named block", proc() =
    let result = generate_zig(case_input("expression_block"))
    result.eq case_expected("expression_block")

  todo_it "must generate unnamed block from block _:", proc() =
    let result = generate_zig(case_input("expression_block_unnamed"))
    result.eq case_expected("expression_block_unnamed")

  todo_it "must generate case/of as switch", proc() =
    let result = generate_zig(case_input("control_case"))
    result.eq case_expected("control_case")

  todo_it "must generate multi-value case/of as switch", proc() =
    let result = generate_zig(case_input("control_case_multi"))
    result.eq case_expected("control_case_multi")

  todo_it "must generate nested case/of as switch", proc() =
    let result = generate_zig(case_input("control_case_nested"))
    result.eq case_expected("control_case_nested")

describe "nonim.minz | Statements":
  it "must generate discard as _ = expr", proc() =
    let result = generate_zig(case_input("statement_discard"))
    result.eq case_expected("statement_discard")

  it "must generate defer keyword", proc() =
    let result = generate_zig(case_input("statement_defer"))
    result.eq case_expected("statement_defer")

  it "must generate compound assignment", proc() =
    let result = generate_zig(case_input("statement_compound_assign"))
    result.eq case_expected("statement_compound_assign")

describe "nonim.minz | Types":
  it "must generate an enum type", proc() =
    let result = generate_zig(case_input("type_enum"))
    result.eq case_expected("type_enum")

  it "must generate enum with explicit values", proc() =
    let result = generate_zig(case_input("type_enum_values"))
    result.eq case_expected("type_enum_values")

  it "must generate enum with backing type", proc() =
    let result = generate_zig(case_input("type_enum_backing"))
    result.eq case_expected("type_enum_backing")

  it "must generate enum with alias field", proc() =
    let result = generate_zig(case_input("type_enum_alias"))
    result.eq case_expected("type_enum_alias")

  it "must generate a struct from object type", proc() =
    let result = generate_zig(case_input("type_object"))
    result.eq case_expected("type_object")

  it "must generate extern struct from {.extern.} object", proc() =
    let result = generate_zig(case_input("type_object_extern"))
    result.eq case_expected("type_object_extern")

  it "must generate an immutable pointer type from ptr T", proc() =
    let result = generate_zig(case_input("type_ptr"))
    result.eq case_expected("type_ptr")

  it "must generate a mutable pointer type from var ptr T", proc() =
    let result = generate_zig(case_input("type_ptr_mutable"))
    result.eq case_expected("type_ptr_mutable")

  it "must translate primitive types correctly", proc() =
    let result = generate_zig(case_input("type_primitive"))
    result.eq case_expected("type_primitive")

  it "must generate object fields with types", proc() =
    let result = generate_zig(case_input("type_object_fields"))
    result.eq case_expected("type_object_fields")

  it "must generate object fields with visibility", proc() =
    let result = generate_zig(case_input("type_object_field_visibility"))
    result.eq case_expected("type_object_field_visibility")

  it "must generate type alias", proc() =
    let result = generate_zig(case_input("type_alias"))
    result.eq case_expected("type_alias")

  it "must generate procedure type", proc() =
    let result = generate_zig(case_input("type_procedure"))
    result.eq case_expected("type_procedure")

  it "must generate optional pointer to procedure type", proc() =
    let result = generate_zig(case_input("type_optional_ptr_proc"))
    result.eq case_expected("type_optional_ptr_proc")

  it "must keep a dotted (qualified) type", proc() =
    let result = generate_zig(case_input("type_dotted"))
    result.eq case_expected("type_dotted")

  it "must generate an array-typed object field", proc() =
    let result = generate_zig(case_input("type_object_array_field"))
    result.eq case_expected("type_object_array_field")

  it "must generate an array with identifier length", proc() =
    let result = generate_zig(case_input("type_array_ident_length"))
    result.eq case_expected("type_array_ident_length")

  it "must emit an alias-pragma object field as a public const declaration", proc() =
    let result = generate_zig(case_input("type_object_alias_field"))
    result.eq case_expected("type_object_alias_field")

  it "must generate object fields with default values", proc() =
    let result = generate_zig(case_input("type_object_field_defaults"))
    result.eq case_expected("type_object_field_defaults")

  it "must make an alias private with a private pragma", proc() =
    let result = generate_zig(case_input("type_object_alias_field_private"))
    result.eq case_expected("type_object_alias_field_private")

  it "must generate pub for exported type", proc() =
    let result = generate_zig(case_input("type_visibility"))
    result.eq case_expected("type_visibility")

  it "must translate typedesc to type", proc() =
    let result = generate_zig(case_input("type_typedesc"))
    result.eq case_expected("type_typedesc")

describe "nonim.minz | Expressions":
  it "must generate pointer dereference", proc() =
    let result = generate_zig(case_input("expression_deref"))
    result.eq case_expected("expression_deref")

  it "must generate array indexing", proc() =
    let result = generate_zig(case_input("expression_indexed"))
    result.eq case_expected("expression_indexed")

  it "must translate Nim operators to Zig operators", proc() =
    let result = generate_zig(case_input("expression_operator"))
    result.eq case_expected("expression_operator")

  it "must translate ?? to orelse", proc() =
    let result = generate_zig(case_input("expression_orelse"))
    result.eq case_expected("expression_orelse")

  it "must generate .? optional call", proc() =
    let result = generate_zig(case_input("expression_optional_call"))
    result.eq case_expected("expression_optional_call")

  it "must generate .?.addr as &expr.?", proc() =
    let result = generate_zig(case_input("expression_optional_unwrap_addr"))
    result.eq case_expected("expression_optional_unwrap_addr")

  it "must generate .?.method() as expr.?.method()", proc() =
    let result = generate_zig(case_input("expression_optional_unwrap_call"))
    result.eq case_expected("expression_optional_unwrap_call")

  it "must translate addr to & prefix", proc() =
    let result = generate_zig(case_input("expression_addr"))
    result.eq case_expected("expression_addr")

  it "must translate prefix not to !", proc() =
    let result = generate_zig(case_input("expression_prefix_not"))
    result.eq case_expected("expression_prefix_not")

  it "must generate an array literal", proc() =
    let result = generate_zig(case_input("expression_array_literal"))
    result.eq case_expected("expression_array_literal")

  it "must generate a leading-dot enum literal", proc() =
    let result = generate_zig(case_input("expression_enum_literal"))
    result.eq case_expected("expression_enum_literal")

  it "must generate an anonymous tuple from positional .()", proc() =
    let result = generate_zig(case_input("expression_anon_tuple"))
    result.eq case_expected("expression_anon_tuple")

  it "must generate nested anonymous constructors", proc() =
    let result = generate_zig(case_input("expression_anon_tuple_nested"))
    result.eq case_expected("expression_anon_tuple_nested")

  it "must generate @as cast as a builtin call", proc() =
    let result = generate_zig(case_input("expression_as_cast"))
    result.eq case_expected("expression_as_cast")

  it "must generate a type expression from block @struct", proc() =
    let result = generate_zig(case_input("expression_type_block"))
    result.eq case_expected("expression_type_block")

  it "must generate from-import inside block @struct", proc() =
    let result = generate_zig(case_input("expression_type_block_import"))
    result.eq case_expected("expression_type_block_import")

  it "must generate @ prefix for Zig builtins", proc() =
    let result = generate_zig(case_input("expression_at_prefix"))
    result.eq case_expected("expression_at_prefix")

  it "must generate try prefix from try: expression", proc() =
    let result = generate_zig(case_input("expression_try_prefix"))
    result.eq case_expected("expression_try_prefix")

  it "must generate catch from inline try/except", proc() =
    let result = generate_zig(case_input("expression_catch_inline"))
    result.eq case_expected("expression_catch_inline")

  it "must generate catch from multiline try/except", proc() =
    let result = generate_zig(case_input("expression_catch_multiline"))
    result.eq case_expected("expression_catch_multiline")

  it "must generate catch from @catch special keyword", proc() =
    let result = generate_zig(case_input("expression_catch_at"))
    result.eq case_expected("expression_catch_at")

  it "must generate catch with capture from inline try/except", proc() =
    let result = generate_zig(case_input("expression_catch_capture_inline"))
    result.eq case_expected("expression_catch_capture_inline")

  it "must generate grouped try expression with parentheses", proc() =
    let result = generate_zig(case_input("expression_try_grouped"))
    result.eq case_expected("expression_try_grouped")

  todo_it "must generate anonymous struct literal from named tuple", proc() =
    let result = generate_zig(case_input("expression_object"))
    result.eq case_expected("expression_object")

  todo_it "must generate nested anonymous struct from .() syntax", proc() =
    let result = generate_zig(case_input("expression_object_nested"))
    result.eq case_expected("expression_object_nested")

  it "must generate an empty object from .() with no arguments", proc() =
    let result = generate_zig(case_input("expression_empty_object"))
    result.eq case_expected("expression_empty_object")

  it "must generate parenthesized group expression", proc() =
    let result = generate_zig(case_input("expression_group"))
    result.eq case_expected("expression_group")

  it "must generate named constructor", proc() =
    let result = generate_zig(case_input("expression_named_constructor"))
    result.eq case_expected("expression_named_constructor")

describe "nonim.minz | Visibility":
  it "must make a procedure private with a private pragma", proc() =
    let result = generate_zig(case_input("procedure_private"))
    result.eq case_expected("procedure_private")

  it "must make a const private with a private pragma", proc() =
    let result = generate_zig(case_input("variable_private"))
    result.eq case_expected("variable_private")

  it "must make a var private with a private pragma", proc() =
    let result = generate_zig(case_input("variable_var_private"))
    result.eq case_expected("variable_var_private")

  it "must make an object type private with a private pragma", proc() =
    let result = generate_zig(case_input("type_object_private"))
    result.eq case_expected("type_object_private")

  it "must make a type alias private with a private pragma", proc() =
    let result = generate_zig(case_input("type_alias_private"))
    result.eq case_expected("type_alias_private")

  it "must make a struct-block member private with a private pragma", proc() =
    let result = generate_zig(case_input("expression_type_block_private"))
    result.eq case_expected("expression_type_block_private")

  it "must generate @struct with body as struct expression", proc() =
    let result = generate_zig(case_input("expression_at_struct_body"))
    result.eq case_expected("expression_at_struct_body")

  it "must respect per-element private pragmas in a tuple unpack", proc() =
    let result = generate_zig(case_input("variable_tuple_unpack_private"))
    result.eq case_expected("variable_tuple_unpack_private")

describe "nonim.minz | Namespaces":
  it "must generate @namespace as const = struct { ... }", proc() =
    let result = generate_zig(case_input("statement_namespace"))
    result.eq case_expected("statement_namespace")

  it "must generate nested @namespace declarations", proc() =
    let result = generate_zig(case_input("statement_namespace_nested"))
    result.eq case_expected("statement_namespace_nested")

  it "must generate import inside @namespace", proc() =
    let result = generate_zig(case_input("namespace_import"))
    result.eq case_expected("namespace_import")

  it "must generate type inside @namespace", proc() =
    let result = generate_zig(case_input("namespace_type"))
    result.eq case_expected("namespace_type")

describe "nonim.minz | Passthrough":
  it "must emit raw code from emit pragma", proc() =
    let result = generate_zig(case_input("statement_passthrough"))
    result.eq case_expected("statement_passthrough")

  it "must emit raw code from emit pragma inside procedure body", proc() =
    let result = generate_zig(case_input("statement_passthrough_body"))
    result.eq case_expected("statement_passthrough_body")

describe "nonim.minz | Comments":
  it "must generate a doc comment", proc() =
    let result = generate_zig(case_input("statement_comment"))
    result.eq case_expected("statement_comment")

  it "must generate a module doc comment from ##!", proc() =
    let result = generate_zig(case_input("statement_comment_module"))
    result.eq case_expected("statement_comment_module")

describe "nonim.minz | Imports":
  it "must generate @import from import statement", proc() =
    let result = generate_zig(case_input("statement_import"))
    result.eq case_expected("statement_import")

  it "must generate pub const from from-import with symbols", proc() =
    let result = generate_zig(case_input("import_from"))
    result.eq case_expected("import_from")

  it "must generate pub const with alias from from-import with as", proc() =
    let result = generate_zig(case_input("import_from_alias"))
    result.eq case_expected("import_from_alias")

  it "must generate module import from @-prefixed path", proc() =
    let result = generate_zig(case_input("import_module"))
    result.eq case_expected("import_module")

  it "must strip the .zig extension from a bare local import name", proc() =
    let result = generate_zig(case_input("import_bare"))
    result.eq case_expected("import_bare")

  it "must keep a ../ relative import path", proc() =
    let result = generate_zig(case_input("import_relative_parent"))
    result.eq case_expected("import_relative_parent")

  it "must keep a ./ relative import path", proc() =
    let result = generate_zig(case_input("import_relative_current"))
    result.eq case_expected("import_relative_current")

  it "must generate import with as alias", proc() =
    let result = generate_zig(case_input("import_as"))
    result.eq case_expected("import_as")

  it "must generate from-import with @-prefixed module path", proc() =
    let result = generate_zig(case_input("import_from_module"))
    result.eq case_expected("import_from_module")

  it "must generate private import without pub", proc() =
    let result = generate_zig(case_input("import_private"))
    result.eq case_expected("import_private")

  it "must generate private import with alias without pub", proc() =
    let result = generate_zig(case_input("import_as_private"))
    result.eq case_expected("import_as_private")

  it "must generate private from-import without pub", proc() =
    let result = generate_zig(case_input("import_from_private"))
    result.eq case_expected("import_from_private")

  it "must generate import inside a procedure body", proc() =
    let result = generate_zig(case_input("body_import"))
    result.eq case_expected("body_import")

  it "must generate discard import from as _", proc() =
    let result = generate_zig(case_input("import_discard"))
    result.eq case_expected("import_discard")

describe "nonim.minz | Lambdas":
  it "must generate a lambda expression as struct-wrapped function", proc() =
    let result = generate_zig(case_input("expression_lambda"))
    result.eq case_expected("expression_lambda")

describe "nonim.minz | Test Blocks":
  it "must generate a test block from @test with identifier", proc() =
    let result = generate_zig(case_input("statement_test"))
    result.eq case_expected("statement_test")

  it "must generate a test block from @test with string name", proc() =
    let result = generate_zig(case_input("statement_test_string"))
    result.eq case_expected("statement_test_string")

  it "must generate a nameless test block from @test", proc() =
    let result = generate_zig(case_input("statement_test_nameless"))
    result.eq case_expected("statement_test_nameless")

  it "must generate @it as try it() with struct-wrapped lambda", proc() =
    let result = generate_zig(case_input("statement_it"))
    result.eq case_expected("statement_it")

  it "must generate @describe as var + test + begin/end + body", proc() =
    let result = generate_zig(case_input("statement_describe"))
    result.eq case_expected("statement_describe")

  it "must generate multiple @it cases inside a single @describe", proc() =
    let result = generate_zig(case_input("statement_describe_multi_it"))
    result.eq case_expected("statement_describe_multi_it")

  it "must generate two @describe blocks in sequence", proc() =
    let result = generate_zig(case_input("statement_describe_two"))
    result.eq case_expected("statement_describe_two")

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
