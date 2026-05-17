#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Affix.
#_______________________________________________________________|
import ./data


proc binary *(operator :string) :TestData=
  const left = "a"
  const right = "b"
  let input_source = left & operator & right & "567890Z"
  result = create(input_source)
  let left_loc = astTF.Location(start: 0, `end`: uint64(left.len))
  let op_loc = astTF.Location(start: left_loc.`end`, `end`: left_loc.`end` + uint64(operator.len))
  let right_loc = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + uint64(right.len))
  let left_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: left_loc),
    ),
  ))
  let right_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: right_loc),
    ),
  ))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      left: some(left_id),
      right: some(right_id),
      operator: op_loc,
    ),
  ))

proc prefix *(operator :string; right :string= "x") :TestData=
  let input_source = operator & right & "567890Z"
  result = create(input_source)
  let op_loc = astTF.Location(start: 0, `end`: uint64(operator.len))
  let right_loc = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + uint64(right.len))
  let right_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: right_loc),
    ),
  ))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      right: some(right_id),
      operator: op_loc,
    ),
  ))
