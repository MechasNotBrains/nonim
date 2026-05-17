#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Procedures with bodies.
#_______________________________________________________________|
import ./data


proc return_literal *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_value = "42"
  const input_keyword = "return"
  const input_source = input_name & input_type & input_value & input_keyword & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let value_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_value.len)
  let keyw_loc = astTF.Location(start: value_loc.`end`, `end`: value_loc.`end` + input_keyword.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let value_id = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: value_loc)))
  let depth_id = result.ast.add_depth(astTF.Depth(indent: some(1'u64)))
  let body_id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sKeyword,
    keyword: astTF.StatementKeyword(
      keyword: astTF.Identifier(location: keyw_loc),
      value: some(value_id),
      depth: some(depth_id),
    ),
  ))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    returnType: some(type_expr),
    impure: some(true),
    private: some(true),
    body: some(body_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc return_affix *() :TestData=
  const input_name = "add"
  const input_arg1 = "x"
  const input_arg2 = "y"
  const input_type = "int"
  const input_op = "+"
  const input_keyword = "return"
  const input_source = input_name & input_arg1 & input_arg2 & input_type & input_op & input_keyword & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let arg1_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_arg1.len)
  let arg2_loc = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + input_arg2.len)
  let type_loc = astTF.Location(start: arg2_loc.`end`, `end`: arg2_loc.`end` + input_type.len)
  let op_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_op.len)
  let keyw_loc = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + input_keyword.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let arg2_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg2_loc)), dataType: some(type_expr), private: some(true)))
  let arg1_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg1_loc)), dataType: some(type_expr), private: some(true), next: some(arg2_id)))
  let left_id = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: arg1_loc))))
  let right_id = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: arg2_loc))))
  let affix_id = result.ast.add_expression(astTF.Expression(kind: astTF.eAffix, affix: astTF.ExpressionAffix(
    left: some(left_id),
    operator: op_loc,
    right: some(right_id),
  )))
  let depth_id = result.ast.add_depth(astTF.Depth(indent: some(1'u64)))
  let body_id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sKeyword,
    keyword: astTF.StatementKeyword(
      keyword: astTF.Identifier(location: keyw_loc),
      value: some(affix_id),
      depth: some(depth_id),
    ),
  ))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    arguments: some(arg1_id),
    returnType: some(type_expr),
    impure: some(true),
    private: some(true),
    body: some(body_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
