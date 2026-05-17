#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Literal.
#_______________________________________________________________|
import ./data


proc integer *() :TestData=
  const input_value = "42"
  const input_source = input_value & "567890Z"
  result = create(input_source)
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 0, `end`: input_value.len),
    ),
  ))

proc large_integer *() :TestData=
  const input_value = "2147483648"
  const input_source = input_value & "567890Z"
  result = create(input_source)
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 0, `end`: input_value.len),
    ),
  ))
