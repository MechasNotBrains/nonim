#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Keyword.
#_______________________________________________________________|
import ./data


proc with_value *() :TestData=
  const input_source = "return42"
  result = create(input_source)
  let value_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 6, `end`: 8),
    ),
  ))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eKeyword,
    keyword: astTF.ExpressionKeyword(
      keyword: astTF.Identifier(location: astTF.Location(start: 0, `end`: 6)),
      value: some(value_id),
    ),
  ))


proc without_value *() :TestData=
  const input_source = "discard"
  result = create(input_source)
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eKeyword,
    keyword: astTF.ExpressionKeyword(
      keyword: astTF.Identifier(location: astTF.Location(start: 0, `end`: 7)),
    ),
  ))
