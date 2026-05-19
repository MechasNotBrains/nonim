#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for whitespace formatting.
#_______________________________________________________________|
import ./data


proc two_procs *() :TestData=
  const input_proc1 = "foo"
  const input_proc2 = "bar"
  const input_source = input_proc1 & "\n\n\n" & input_proc2 & "567890Z"
  result = create(input_source)
  let proc1_loc = astTF.Location(start: 0, `end`: input_proc1.len)
  let proc2_loc = astTF.Location(start: proc1_loc.`end` + 3, `end`: proc1_loc.`end` + 3 + input_proc2.len)
  let proc1_id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: proc1_loc)),
    impure: some(true),
  ))
  let proc2_id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: proc2_loc)),
    impure: some(true),
  ))
  let stmt2_id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: proc2_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: proc1_id, next: some(stmt2_id)),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc var_then_proc *() :TestData=
  const input_name = "x"
  const input_type = "int"
  const input_val = "42"
  const input_proc = "thing"
  const input_source = input_name & input_type & input_val & "\n\n\n" & input_proc & "567890Z"
  result = create(input_source)
  var pos = 0'u64
  template loc(input :static string) :astTF.Location=
    let start = pos
    pos += input.len.uint64
    astTF.Location(start: start, `end`: pos)
  template skip(n :uint64) = pos += n
  let name_loc = loc(input_name)
  let type_loc = loc(input_type)
  let val_loc = loc(input_val)
  skip(3)
  let proc_loc = loc(input_proc)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let val_id = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: val_loc)))
  let bind_id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name_loc)),
    dataType: some(type_expr),
    value: some(val_id),
    runtime: some(true),
  ))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: proc_loc)),
    impure: some(true),
  ))
  let stmt_proc = result.ast.add_statement(astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: proc_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sVariable,
    variable: astTF.StatementVariable(id: bind_id, next: some(stmt_proc)),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
