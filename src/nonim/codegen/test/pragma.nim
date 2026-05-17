#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Pragmas.
#_______________________________________________________________|
import ./data


proc single *() :TestData=
  const input_name = "pop"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let key_expr = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))
  result.id = result.ast.add_pragma(astTF.Pragma(key: key_expr))


proc combined *() :TestData=
  const input_name1 = "pragma"
  const input_name2 = "header"
  const input_value = "hello.h"
  const input_source = input_name1 & input_name2 & input_value & "567890Z"
  result = create(input_source)
  let key1_loc = astTF.Location(start: 0, `end`: input_name1.len)
  let key1 = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: key1_loc)),
  ))
  let key2_loc = astTF.Location(start: key1_loc.`end`, `end`: key1_loc.`end` + input_name2.len)
  let key2 = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: key2_loc)),
  ))
  let value_loc = astTF.Location(start: key2_loc.`end`, `end`: key2_loc.`end` + input_value.len)
  let value = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.string, value: value_loc),
  ))
  let pragma2 = result.ast.add_pragma(astTF.Pragma(key: key2, value: some(value)))
  result.id = result.ast.add_pragma(astTF.Pragma(key: key1, next: some(pragma2)))
