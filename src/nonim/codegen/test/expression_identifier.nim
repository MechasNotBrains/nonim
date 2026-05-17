#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Identifier.
#_______________________________________________________________|
import ./data


proc plain *() :TestData=
  const input_name = "thing"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: input_name.len)),
    ),
  ))

proc keyword *(word :string) :TestData=
  let input_source = word & "567890Z"
  result = create(input_source)
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: uint64(word.len))),
    ),
  ))
