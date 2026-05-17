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
    let test_case = statement_variable.immutable_runtime()
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
    let test_case = procedure_body.return_literal()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected

  it "must generate a procedure body with return affix expression", proc() =
    const Expected = expected("procedure_body_return_affix.zig")
    let test_case = procedure_body.return_affix()
    let result = test_case.ast.zig()
    result.modules[0].definitions.eq Expected
