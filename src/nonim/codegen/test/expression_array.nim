#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Array.
#_______________________________________________________________|
import ./data


proc literal_values *() :TestData=
  const input_val1   = "0.222"
  const input_val2   = "0.333"
  const input_val3   = "0.444"
  const input_source = input_val1 & input_val2 & input_val3 & "567890Z"
  result = create(input_source)
  let val1_loc = astTF.Location(start: 0, `end`: input_val1.len)
  var offset   = val1_loc.`end`
  let val2_loc = astTF.Location(start: offset, `end`: offset + input_val2.len); offset += input_val2.len
  let val3_loc = astTF.Location(start: offset, `end`: offset + input_val3.len); offset += input_val3.len
  let expr1    = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.float, value: val1_loc)))
  let expr2    = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.float, value: val2_loc)))
  let expr3    = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.float, value: val3_loc)))
  let elem3    = result.ast.add_array_element(astTF.ArrayElement(element: expr3))
  let elem2    = result.ast.add_array_element(astTF.ArrayElement(element: expr2, next: some(elem3)))
  let elem1    = result.ast.add_array_element(astTF.ArrayElement(element: expr1, next: some(elem2)))
  result.id = result.ast.add_expression(astTF.Expression(
    kind     : astTF.eArray,
    array    : astTF.ExpressionArray(elements: some(elem1)),
  ))
