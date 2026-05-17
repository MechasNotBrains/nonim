#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Bindings.
#_______________________________________________________________|
import ./data


proc named_type *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_source = input_name & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  result.id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name_loc)),
    dataType: some(type_expr),
  ))


proc named_type_value *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_value = "42"
  const input_source = input_name & input_type & input_value & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let value_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_value.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  let value_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: value_loc),
  ))
  result.id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name_loc)),
    dataType: some(type_expr),
    value: some(value_id),
  ))


proc named_pragma *() :TestData=
  const input_name = "thing"
  const input_pragma = "cdecl"
  const input_type = "int"
  const input_source = input_name & input_pragma & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let pragma_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_pragma.len)
  let type_loc = astTF.Location(start: pragma_loc.`end`, `end`: pragma_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  let pragma_key = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: pragma_loc)),
  ))
  let pragma_id = result.ast.add_pragma(astTF.Pragma(key: pragma_key))
  result.id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name_loc)),
    dataType: some(type_expr),
    pragmas: some(pragma_id),
  ))


proc multi_type_value *() :TestData=
  const input_name1 = "a"
  const input_name2 = "b"
  const input_type = "int"
  const input_value = "0"
  const input_source = input_name1 & input_name2 & input_type & input_value & "567890Z"
  result = create(input_source)
  let name1_loc = astTF.Location(start: 0, `end`: input_name1.len)
  let name2_loc = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + input_name2.len)
  let type_loc = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + input_type.len)
  let value_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_value.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  let value_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: value_loc),
  ))
  let bind2 = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name2_loc)),
    dataType: some(type_expr),
    value: some(value_id),
  ))
  result.id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: name1_loc)),
    next: some(bind2),
  ))
