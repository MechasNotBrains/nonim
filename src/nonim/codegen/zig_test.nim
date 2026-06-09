#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for Zig codegen in isolation.
#___________________________________________________________________|
# @deps tests
import minitest
# @deps nonim
import ./zig
import ./output
import ./test/expression_identifier
import ./test/expression_literal
import ./test/expression_affix
import ./test/expression_call
import ./test/statement_variable
import ./test/statement_keyword
import ./test/procedure_body
import ./test/statement_import
import ./test/statement_passthrough
import ./test/statement_comment
import ./test/format_whitespace
import ./test/statement_type
import ./test/statement_alias

const expected_dir = "./expected/zig/"
template expected (path :static system.string) :system.string= staticRead(expected_dir & path)


describe "nonim.codegen.zig | Expression.Identifier":
  it "must generate a plain identifier", proc() =
    const Expected = expected("expression_identifier_plain.zig")
    var test_case = expression_identifier.plain()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.zig | Expression.Literal":
  it "must generate an integer literal", proc() =
    const Expected = expected("expression_literal_integer.zig")
    var test_case = expression_literal.integer()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.zig | Expression.Affix":
  it "must generate a binary infix expression", proc() =
    const Expected = expected("expression_affix_binary.zig")
    var test_case = expression_affix.binary("+")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

  it "must generate prefix not as !", proc() =
    const Expected = expected("expression_affix_prefix_not.zig")
    var test_case = expression_affix.prefix("not")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

  it "must leave an infix not untouched", proc() =
    const Expected = expected("expression_affix_infix_not.zig")
    var test_case = expression_affix.binary("not")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.zig | Expression.Call":
  it "must generate a call with arguments", proc() =
    const Expected = expected("expression_call_with_arguments.zig")
    var test_case = expression_call.with_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

  it "must generate a call without arguments", proc() =
    const Expected = expected("expression_call_without_arguments.zig")
    var test_case = expression_call.without_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Variable":
  it "must generate const from immutable runtime binding", proc() =
    const Expected = expected("statement_variable_immutable_runtime.zig")
    let test_case = statement_variable.immutable_runtime("isize")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Keyword":
  it "must generate a return statement with literal", proc() =
    const Expected = expected("statement_keyword_return_literal.zig")
    let test_case = statement_keyword.return_literal()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Procedure.Body":
  it "must generate a procedure body with return literal", proc() =
    const Expected = expected("procedure_body_return_literal.zig")
    let test_case = procedure_body.return_literal("isize")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate a procedure body with return affix expression", proc() =
    const Expected = expected("procedure_body_return_affix.zig")
    let test_case = procedure_body.return_affix("isize")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Passthrough":
  it "must generate a passthrough statement", proc() =
    const Expected = expected("statement_passthrough.zig")
    let test_case = statement_passthrough.simple()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Comment":
  it "must generate a regular comment", proc() =
    const Expected = expected("statement_comment.zig")
    let test_case = statement_comment.line_from("#")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate a doc comment", proc() =
    const Expected = expected("statement_comment_doc.zig")
    let test_case = statement_comment.doc_from("##")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate a multi-line doc comment", proc() =
    const Expected = expected("statement_comment_multiline.zig")
    let test_case = statement_comment.multiline_from("##")
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Import":
  it "must generate a zig import statement", proc() =
    const Expected = expected("statement_import.zig")
    let test_case = statement_import.simple()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must use last path segment as binding name", proc() =
    const Expected = expected("statement_import_path.zig")
    let test_case = statement_import.path_import()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate pub const per symbol from from-import", proc() =
    const Expected = expected("statement_import_from_symbols.zig")
    let test_case = statement_import.from_symbols()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Format.Whitespace":
  it "must normalize whitespace between two procs", proc() =
    const Expected = expected("format_two_procs.zig")
    let test_case = format_whitespace.two_procs()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must normalize whitespace between var and proc", proc() =
    const Expected = expected("format_var_then_proc.zig")
    let test_case = format_whitespace.var_then_proc()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Type.Object":
  it "must generate object fields with default values", proc() =
    const Expected = expected("statement_type_object_field_defaults.zig")
    let test_case = statement_type.object_field_defaults()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate an empty object expression", proc() =
    const Expected = expected("expression_object_empty.zig")
    var test_case = statement_type.object_empty()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.zig | Statement.Alias":
  it "must generate a simple alias", proc() =
    const Expected = expected("statement_alias_simple.zig")
    let test_case = statement_alias.simple()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

