#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type.Pointer.
#_______________________________________________________________|
import ./data


proc immutable *() :TestData=
  const input_name   = "Foo"
  const input_target = "int"
  const input_source = input_name & input_target & "567890Z"
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let target_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: target_loc))))
  let ptr_type_id    = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(target: target_type_id)))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: ptr_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name             : some(astTF.Identifier(location: name_loc)),
    target           : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc mutable *() :TestData=
  const input_name   = "Foo"
  const input_target = "int"
  const input_source = input_name & input_target & "567890Z"
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let target_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: target_loc))))
  let ptr_type_id    = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(target: target_type_id, mutable: some(true))))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: ptr_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name             : some(astTF.Identifier(location: name_loc)),
    target           : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)
