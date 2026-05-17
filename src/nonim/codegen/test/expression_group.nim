#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Group.
#_______________________________________________________________|
import ./data


proc parenthesized *() :TestData=
  const input_left = "a"
  const input_operator = "or"
  const input_right = "b"
  const input_source = input_left & input_operator & input_right & "567890Z"
  result = create(input_source)
  let left_loc = astTF.Location(start: 0, `end`: input_left.len)
  let op_loc = astTF.Location(start: left_loc.`end`, `end`: left_loc.`end` + input_operator.len)
  let right_loc = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + input_right.len)
  let left_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: left_loc)),
  ))
  let right_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: right_loc)),
  ))
  let affix_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(left: some(left_id), right: some(right_id), operator: op_loc),
  ))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eGroup,
    group: astTF.ExpressionGroup(inner: affix_id),
  ))
