#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit tests for C codegen in isolation.
#___________________________________________________________________|
# @deps tests
import minitest
# @deps nonim
import ./C
import ./output
import ./test/expression_identifier
import ./test/expression_literal
import ./test/expression_affix
import ./test/expression_call
import ./test/statement_variable
import ./test/statement_keyword
import ./test/procedure_body
import ./test/statement_passthrough
import ./test/statement_comment
import ./test/format_whitespace

const expected_dir = "./expected/c/"
template expected (path :static system.string) :system.string= staticRead(expected_dir & path)


describe "nonim.codegen.c | Expression.Identifier":
  it "must generate a plain identifier", proc() =
    const Expected = expected("expression_identifier_plain.c")
    var test_case = expression_identifier.plain()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.c | Expression.Literal":
  it "must generate an integer literal", proc() =
    const Expected = expected("expression_literal_integer.c")
    var test_case = expression_literal.integer()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.c | Expression.Affix":
  it "must generate a binary infix expression", proc() =
    const Expected = expected("expression_affix_binary.c")
    var test_case = expression_affix.binary("+")
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.c | Expression.Call":
  it "must generate a call with arguments", proc() =
    const Expected = expected("expression_call_with_arguments.c")
    var test_case = expression_call.with_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

  it "must generate a call without arguments", proc() =
    const Expected = expected("expression_call_without_arguments.c")
    var test_case = expression_call.without_arguments()
    var Out = Output.create()
    test_case.ast.expression(test_case.module, test_case.id, Out)
    Out.modules[test_case.module].definitions.eq Expected

describe "nonim.codegen.c | Statement.Variable":
  it "must generate static const int from immutable runtime binding", proc() =
    const Expected = expected("statement_variable_immutable_runtime.c")
    let test_case = statement_variable.immutable_runtime()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.c | Statement.Keyword":
  it "must generate a return statement with literal", proc() =
    const Expected = expected("statement_keyword_return_literal.c")
    let test_case = statement_keyword.return_literal()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.c | Procedure.Body":
  it "must generate a procedure body with return literal", proc() =
    const Expected = expected("procedure_body_return_literal.c")
    let test_case = procedure_body.return_literal()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

  it "must generate a procedure body with return affix expression", proc() =
    const Expected = expected("procedure_body_return_affix.c")
    let test_case = procedure_body.return_affix()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.c | Statement.Passthrough":
  it "must generate a passthrough statement", proc() =
    const Expected = expected("statement_passthrough.c")
    let test_case = statement_passthrough.simple()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.c | Statement.Comment":
  it "must generate a regular comment", proc() =
    const Expected = expected("statement_comment.c")
    let test_case = statement_comment.line_from("#")
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

  it "must generate a doc comment", proc() =
    const Expected = expected("statement_comment_doc.c")
    let test_case = statement_comment.doc_from("##")
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

  it "must generate a multi-line doc comment", proc() =
    const Expected = expected("statement_comment_multiline.c")
    let test_case = statement_comment.multiline_from("##")
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

describe "nonim.codegen.c | Format.Whitespace":
  it "must normalize whitespace between two procs", proc() =
    const Expected = expected("format_two_procs.c")
    let test_case = format_whitespace.two_procs()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected

  it "must normalize whitespace between var and proc", proc() =
    const Expected = expected("format_var_then_proc.c")
    let test_case = format_whitespace.var_then_proc()
    let result = test_case.ast.C()
    result.modules[0].definitions.eq Expected
