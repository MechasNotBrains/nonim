#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps tests
import minitest
# @deps nonim
import ./nim
from ./test/expression_identifier import nil
import ./test/expression_literal
import ./test/expression_affix
import ./test/expression_group
import ./test/expression_call
import ./test/pragma
import ./test/binding
import ./test/procedure
import ./test/type_procedure
import ./test/type_ptr
import ./test/type_array
import ./test/statement_variable
import ./test/statement_keyword
import ./test/statement_passthrough
import ./test/statement_import
import ./test/statement_alias
import ./test/statement_comment
import ./test/statement_type
import ./test/statement_list


const expected_dir = "./expected/nim/"
const partials_dir = expected_dir & "partials/"
template expected (path :static system.string) :system.string= staticRead(expected_dir & path)
template partial  (path :static system.string) :system.string= staticRead(partials_dir & path)


#_______________________________________
# @section Keywords
#_____________________________
describe "nonim.codegen.nim | Keyword Cases":
  it "must return true for known nim keywords", proc()=
    keyword("proc").eq(true)

  it "must return false for other words", proc()=
    keyword("hello").eq(false)


#_______________________________________
# @section Identifiers
#_____________________________
describe "nonim.codegen.nim | Identifier Cases":
  it "must generate an identifier without backticks when the name is not a nim keyword", proc()=
    const Expected = partial("identifier_plain.nim")
    var test_case = expression_identifier.plain()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an identifier with backticks when the name is a nim keyword", proc()=
    const Expected = partial("identifier_keyword.nim")
    var test_case = expression_identifier.keyword("proc")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Pragmas
#_____________________________
describe "nonim.codegen.nim | Pragma Cases":
  it "must generate a single pragma", proc()=
    const Expected = partial("pragma_single.nim")
    var test_case = pragma.single()
    var Out = Output.create()
    test_case.ast.pragma(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a combined pragma", proc()=
    const Expected = partial("pragma_combined.nim")
    var test_case = pragma.combined()
    var Out = Output.create()
    test_case.ast.pragma(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Literals
#_____________________________
describe "nonim.codegen.nim | Literal Cases":
  it "must generate a literal value", proc()=
    const Expected = partial("literal_integer.nim")
    var test_case = expression_literal.integer()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must append u64 suffix to integer literals exceeding int32 range", proc()=
    const Expected = partial("literal_large_integer.nim")
    var test_case = expression_literal.large_integer()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Affix Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.affix Cases":
  it "must generate a binary infix expression", proc()=
    const Expected = partial("expression_affix_binary.nim")
    var test_case = expression_affix.binary("or")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a unary prefix expression", proc()=
    const Expected = partial("expression_affix_unary.nim")
    var test_case = expression_affix.prefix("not")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Group Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.group Cases":
  it "must generate a parenthesized expression", proc()=
    const Expected = partial("expression_group.nim")
    var test_case = expression_group.parenthesized()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Call Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.call Cases":
  it "must generate a call expression with an argument", proc()=
    const Expected = partial("expression_call.nim")
    var test_case = expression_call.with_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a call expression without arguments", proc()=
    const Expected = partial("expression_call_no_args.nim")
    var test_case = expression_call.without_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Types
#_____________________________
describe "nonim.codegen.nim | Type Cases":
  it "must generate a procedure type with args and return", proc()=
    const Expected = partial("type_procedure.nim")
    var test_case = type_procedure.with_args_and_return()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a procedure type without return", proc()=
    const Expected = partial("type_procedure_no_return.nim")
    var test_case = type_procedure.without_return()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a pointer type", proc()=
    const Expected = partial("type_ptr.nim")
    var test_case = type_ptr.simple()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a fixed-size array type", proc()=
    const Expected = partial("type_array_fixed.nim")
    var test_case = type_array.fixed()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a named array type", proc()=
    const Expected = partial("type_array_named.nim")
    var test_case = type_array.named()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a pointer to pointer type", proc()=
    const Expected = partial("type_ptr_to_ptr.nim")
    var test_case = type_ptr.to_ptr()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Bindings
#_____________________________
describe "nonim.codegen.nim | Binding Cases":
  it "must generate a single named binding with a type", proc()=
    const Expected = partial("binding_named_type.nim")
    var test_case = binding.named_type()
    var Out = Output.create()
    test_case.ast.binding(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a single named binding with a type and a default value", proc()=
    const Expected = partial("binding_named_type_value.nim")
    var test_case = binding.named_type_value()
    var Out = Output.create()
    test_case.ast.binding(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a single named binding with a pragma", proc()=
    const Expected = partial("binding_named_pragma.nim")
    var test_case = binding.named_pragma()
    var Out = Output.create()
    test_case.ast.binding(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a multi named binding with a type and a default value", proc()=
    const Expected = partial("binding_multi_type_value.nim")
    var test_case = binding.multi_type_value()
    var Out = Output.create()
    test_case.ast.binding(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Variables
#_____________________________
describe "nonim.codegen.nim | Variable Statement Cases":
  it "must generate a let variable statement", proc()=
    const Expected = expected("variable_let.nim")
    let test_case = statement_variable.immutable_runtime()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq_str(Expected)

  it "must generate a var variable statement", proc()=
    const Expected = expected("variable_var.nim")
    let test_case = statement_variable.mutable()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq_str(Expected)

  it "must generate a const variable statement", proc()=
    const Expected = expected("variable_const.nim")
    let test_case = statement_variable.immutable_comptime()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq_str(Expected)


#_______________________________________
# @section Procedures
#_____________________________
describe "nonim.codegen.nim | Procedure Cases":
  it "must generate a public impure procedure with one argument and a return type", proc()=
    const Expected = partial("procedure_public_impure.nim")
    var test_case = procedure.public_impure()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a private impure procedure", proc()=
    const Expected = partial("procedure_private_impure.nim")
    var test_case = procedure.private_impure()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a public pure procedure", proc()=
    const Expected = partial("procedure_public_pure.nim")
    var test_case = procedure.public_pure()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a public pure procedure without return type", proc()=
    const Expected = partial("procedure_no_return.nim")
    var test_case = procedure.no_return_type()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a public pure procedure with pragmas", proc()=
    const Expected = partial("procedure_with_pragmas.nim")
    var test_case = procedure.with_pragmas()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must use callable keyword when present", proc()=
    const Expected = partial("procedure_template.nim")
    var test_case = procedure.callable_template()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must use callable keyword for method with args and return", proc()=
    const Expected = partial("procedure_method.nim")
    var test_case = procedure.callable_method()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a generic procedure", proc()=
    const Expected = partial("procedure_generic.nim")
    var test_case = procedure.generic()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a procedure with multiple generic parameters", proc()=
    const Expected = partial("procedure_generic_multi.nim")
    var test_case = procedure.generic_multi()
    var Out = Output.create()
    test_case.ast.procedure(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Type Statements
#_____________________________
describe "nonim.codegen.nim | Type Statement Cases":
  it "must generate a type alias statement", proc()=
    const Expected = expected("statement_type_alias.nim")
    var test_case = statement_type.alias()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an enum type statement", proc()=
    const Expected = expected("statement_type_enum.nim")
    var test_case = statement_type.enumeration()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an object type statement", proc()=
    const Expected = expected("statement_type_object.nim")
    var test_case = statement_type.object_simple()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a generic object type statement", proc()=
    const Expected = expected("statement_type_object_generic.nim")
    var test_case = statement_type.object_generic()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an object type with inheritance", proc()=
    const Expected = expected("statement_type_object_inherit.nim")
    var test_case = statement_type.object_inherit()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an object type with multiple generic parameters", proc()=
    const Expected = expected("statement_type_object_generic_multi.nim")
    var test_case = statement_type.object_generic_multi()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must render only the first base for multiple inheritance", proc()=
    const Expected = expected("statement_type_object_inherit_multi.nim")
    var test_case = statement_type.object_inherit_multi()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a union type with keyword and pragma combined", proc()=
    const Expected = expected("statement_type_union.nim")
    var test_case = statement_type.union()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a type alias with distinct keyword on primitive", proc()=
    const Expected = expected("statement_type_primitive_keyword.nim")
    var test_case = statement_type.primitive_distinct()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a primitive type with instantiation (generics)", proc()=
    const Expected = expected("statement_type_primitive_instantiation.nim")
    var test_case = statement_type.primitive_instantiation()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a primitive type with multi-arg instantiation", proc()=
    const Expected = expected("statement_type_primitive_instantiation_multi.nim")
    var test_case = statement_type.primitive_instantiation_multi()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a ref object type (ptr with reference=true)", proc()=
    const Expected = expected("statement_type_ptr_reference.nim")
    var test_case = statement_type.ptr_reference()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must render optional ref by name, not inline object body", proc()=
    const Expected = expected("statement_type_ptr_reference_optional.nim")
    var test_case = statement_type.ptr_reference_optional()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an unnamed tuple type inline", proc()=
    const Expected = partial("type_tuple_unnamed.nim")
    var test_case = statement_type.tuple_unnamed()
    var Out = Output.create()
    test_case.ast.`type`(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a proc with unnamed tuple return type", proc()=
    const Expected = expected("procedure_tuple_return.nim")
    var test_case = statement_type.procedure_tuple_return()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Block Statements (statement_list)
#_____________________________
describe "nonim.codegen.nim | statement_list Cases":
  it "must not group a single type statement followed by a different statement kind", proc()=
    const Expected = expected("block_type_then_proc.nim")
    var test_case = statement_list.type_then_proc()
    var Out = Output.create()
    test_case.ast.statement_list(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must merge chained type statements into a type block", proc()=
    const Expected = expected("block_type.nim")
    var test_case = statement_list.type_block()
    var Out = Output.create()
    test_case.ast.statement_list(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must not group variable statements with different keywords", proc()=
    const Expected = expected("block_variable_different_keywords.nim")
    var test_case = statement_list.variable_different_keywords()
    var Out = Output.create()
    test_case.ast.statement_list(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must group same keywords and split across different keywords and procs", proc()=
    const Expected = expected("block_mixed_chain.nim")
    var test_case = statement_list.mixed_chain()
    var Out = Output.create()
    test_case.ast.statement_list(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Passthrough Statements
#_____________________________
describe "nonim.codegen.nim | Statement.passthrough Cases":
  it "must generate a passthrough statement", proc()=
    const Expected = expected("statement_passthrough.nim")
    let test_case = statement_passthrough.simple()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq_str(Expected)


#_______________________________________
# @section Import Statements
#_____________________________
describe "nonim.codegen.nim | Statement.import Cases":
  it "must generate a simple import statement", proc()=
    const Expected = expected("statement_import.nim")
    var test_case = statement_import.simple()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a from-import statement with symbols", proc()=
    const Expected = expected("statement_import_from.nim")
    var test_case = statement_import.from_symbols()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate an include statement", proc()=
    const Expected = expected("statement_include.nim")
    var test_case = statement_import.include_simple()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Alias Statements
#_____________________________
describe "nonim.codegen.nim | Statement.alias Cases":
  it "must generate an alias statement as const", proc()=
    const Expected = partial("statement_alias.nim")
    var test_case = statement_alias.simple()
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)


#_______________________________________
# @section Comment Statements
#_____________________________
describe "nonim.codegen.nim | Statement.comment Cases":
  it "must generate a regular comment from C line comment", proc()=
    const Expected = expected("statement_comment.nim")
    var test_case = statement_comment.line_from("//")
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a doc comment from C doc comment", proc()=
    const Expected = expected("statement_comment_doc.nim")
    var test_case = statement_comment.doc_from("///")
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

  it "must generate a multi-line doc comment with prefix on every line", proc()=
    const Expected = expected("statement_comment_multiline.nim")
    var test_case = statement_comment.multiline_from("/**")
    var Out = Output.create()
    test_case.ast.statement(test_case.module, test_case.id, Target.definition, Out)
    Out.modules[test_case.module].definitions.eq_str(Expected)

describe "nonim.codegen.nim | Statement.Variable":
  it "must generate let binding", proc() =
    const Expected = expected("variable_let.nim")
    let test_case = statement_variable.immutable_runtime()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.nim | Statement.Keyword":
  it "must generate a return statement with literal", proc() =
    const Expected = expected("statement_keyword_return_literal.nim")
    let test_case = statement_keyword.return_literal()
    let result = test_case.ast.nim()
    result.modules[0].definitions.eq Expected

