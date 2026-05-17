#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Keyword.
#_______________________________________________________________|
import ./data


proc return_literal *() :TestData=
  const input_source = "return42"
  result = create(input_source)
  let value_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 6, `end`: 8),
    ),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sKeyword,
    keyword: astTF.StatementKeyword(
      keyword: astTF.Identifier(location: astTF.Location(start: 0, `end`: 6)),
      value: some(value_id),
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
