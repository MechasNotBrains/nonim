#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type.Array.
#_______________________________________________________________|
import ./data


proc fixed *() :TestData=
  const input_element = "cint"
  const input_length = "10"
  const input_source = input_element & input_length & "567890Z"
  result = create(input_source)
  let elem_loc = astTF.Location(start: 0, `end`: input_element.len)
  let len_loc = astTF.Location(start: elem_loc.`end`, `end`: elem_loc.`end` + input_length.len)
  let elem_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: elem_loc)),
  ))
  let len_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: len_loc),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tArray,
    array: astTF.TypeArray(element: elem_id, length: some(len_id)),
  ))


proc named *() :TestData=
  const input_name = "UncheckedArray"
  const input_element = "cint"
  const input_source = input_name & input_element & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let elem_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_element.len)
  let elem_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: elem_loc)),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tArray,
    array: astTF.TypeArray(element: elem_id, name: some(astTF.Identifier(location: name_loc))),
  ))
