#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for statement_list (Block Statements).
#_______________________________________________________________|
import ./data


proc type_then_proc *() :TestData=
  const input_name1 = "Foo"
  const input_target = "int"
  const input_proc = "thing"
  const input_arg = "a"
  const input_type = "int"
  const input_source = input_name1 & input_target & input_proc & input_arg & input_type & "567890Z"
  result = create(input_source)
  let name1_loc = astTF.Location(start: 0, `end`: input_name1.len)
  let target_loc = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: target_loc))))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name: some(astTF.Identifier(location: name1_loc)),
    target: target_expr_id,
  )))
  let proc_loc = astTF.Location(start: target_loc.`end`, `end`: target_loc.`end` + input_proc.len)
  let arg_loc = astTF.Location(start: proc_loc.`end`, `end`: proc_loc.`end` + input_arg.len)
  let argT_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let argT_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: argT_loc))))
  let argT_expr = result.ast.add_expression_type(argT_id)
  let arg_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg_loc)), dataType: some(argT_expr), private: some(true)))
  let proc_id = result.ast.add_procedure(astTF.Procedure(name: some(astTF.Identifier(location: proc_loc)), arguments: some(arg_id), returnType: some(argT_expr), impure: some(true)))
  let statement2_id = result.ast.add_statement(astTF.Statement(kind: astTF.sProcedure, procedure: astTF.StatementProcedure(id: proc_id)))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id, next: some(statement2_id))))
  result.ast.data.modules[result.module].body = some(result.id)


proc type_block *() :TestData=
  const input_name1 = "Foo"
  const input_target = "int"
  const input_name2 = "Bar"
  const input_field = "x"
  const input_type = "int"
  const input_source = input_name1 & input_target & input_name2 & input_field & input_type & "567890Z"
  result = create(input_source)
  let name1_loc = astTF.Location(start: 0, `end`: input_name1.len)
  let target_loc = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: target_loc))))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name: some(astTF.Identifier(location: name1_loc)),
    target: target_expr_id,
  )))
  let name2_loc = astTF.Location(start: target_loc.`end`, `end`: target_loc.`end` + input_name2.len)
  let field_loc = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + input_field.len)
  let fieldT_loc = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + input_type.len)
  let fieldT_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: fieldT_loc))))
  let fieldT_expr = result.ast.add_expression_type(fieldT_id)
  let field_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field_loc)), dataType: some(fieldT_expr)))
  let obj_type_id = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name: some(astTF.Identifier(location: name2_loc)),
    fields: some(field_id),
  )))
  let statement2_id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: obj_type_id)))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id, next: some(statement2_id))))
  result.ast.data.modules[result.module].body = some(result.id)


proc variable_different_keywords *() :TestData=
  const input_name1 = "a"
  const input_name2 = "b"
  const input_type = "int"
  const input_val1 = "1"
  const input_val2 = "2"
  const input_source = input_name1 & input_name2 & input_type & input_val1 & input_val2 & "567890Z"
  result = create(input_source)
  let name1_loc = astTF.Location(start: 0, `end`: input_name1.len)
  let name2_loc = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + input_name2.len)
  let type_loc = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + input_type.len)
  let val1_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_val1.len)
  let val2_loc = astTF.Location(start: val1_loc.`end`, `end`: val1_loc.`end` + input_val2.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let val1_id = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: val1_loc)))
  let val2_id = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: val2_loc)))
  let binding1_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: name1_loc)), dataType: some(type_expr), value: some(val1_id), runtime: some(true)))
  let binding2_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: name2_loc)), dataType: some(type_expr), value: some(val2_id), runtime: some(true), mutable: some(true)))
  let statement2_id = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: binding2_id)))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: binding1_id, next: some(statement2_id))))
  result.ast.data.modules[result.module].body = some(result.id)


proc mixed_chain *() :TestData=
  const input_a = "a"
  const input_b = "b"
  const input_c = "c"
  const input_d = "d"
  const input_e = "e"
  const input_f = "f"
  const input_p1 = "thing1"
  const input_p2 = "thing2"
  const input_type = "int"
  const input_v1 = "1"
  const input_v2 = "2"
  const input_v3 = "3"
  const input_v4 = "4"
  const input_v5 = "5"
  const input_v6 = "6"
  const input_source = input_a & input_b & input_c & input_d & input_e & input_f &
                       input_p1 & input_p2 & input_type &
                       input_v1 & input_v2 & input_v3 & input_v4 & input_v5 & input_v6 & "567890Z"
  result = create(input_source)
  var pos = 0'u64
  template loc(input :static system.string) :astTF.Location=
    let start = pos
    pos += input.len.uint64
    astTF.Location(start: start, `end`: pos)
  let loc_a = loc(input_a)
  let loc_b = loc(input_b)
  let loc_c = loc(input_c)
  let loc_d = loc(input_d)
  let loc_e = loc(input_e)
  let loc_f = loc(input_f)
  let loc_p1 = loc(input_p1)
  let loc_p2 = loc(input_p2)
  let loc_type = loc(input_type)
  let loc_v1 = loc(input_v1)
  let loc_v2 = loc(input_v2)
  let loc_v3 = loc(input_v3)
  let loc_v4 = loc(input_v4)
  let loc_v5 = loc(input_v5)
  let loc_v6 = loc(input_v6)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: loc_type))))
  let type_expr = result.ast.add_expression_type(type_id)
  let expr1 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v1)))
  let expr2 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v2)))
  let expr3 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v3)))
  let expr4 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v4)))
  let expr5 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v5)))
  let expr6 = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: loc_v6)))
  let bind_a = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_a)), dataType: some(type_expr), value: some(expr1), runtime: some(true)))
  let bind_b = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_b)), dataType: some(type_expr), value: some(expr2), runtime: some(true)))
  let bind_c = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_c)), dataType: some(type_expr), value: some(expr3), runtime: some(true), mutable: some(true)))
  let bind_d = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_d)), dataType: some(type_expr), value: some(expr4), runtime: some(true), mutable: some(true)))
  let bind_e = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_e)), dataType: some(type_expr), value: some(expr5)))
  let bind_f = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: loc_f)), dataType: some(type_expr), value: some(expr6)))
  let proc1 = result.ast.add_procedure(astTF.Procedure(name: some(astTF.Identifier(location: loc_p1)), impure: some(true)))
  let proc2 = result.ast.add_procedure(astTF.Procedure(name: some(astTF.Identifier(location: loc_p2)), impure: some(true)))
  let stmt_f = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_f)))
  let stmt_e = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_e, next: some(stmt_f))))
  let stmt_p2 = result.ast.add_statement(astTF.Statement(kind: astTF.sProcedure, procedure: astTF.StatementProcedure(id: proc2, next: some(stmt_e))))
  let stmt_p1 = result.ast.add_statement(astTF.Statement(kind: astTF.sProcedure, procedure: astTF.StatementProcedure(id: proc1, next: some(stmt_p2))))
  let stmt_d = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_d, next: some(stmt_p1))))
  let stmt_c = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_c, next: some(stmt_d))))
  let stmt_b = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_b, next: some(stmt_c))))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sVariable, variable: astTF.StatementVariable(id: bind_a, next: some(stmt_b))))
  result.ast.data.modules[result.module].body = some(result.id)
