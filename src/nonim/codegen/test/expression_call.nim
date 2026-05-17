#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Expression.Call.
#_______________________________________________________________|
import ./data


proc with_arguments *() :TestData=
  const input_source = "add12"
  result = create(input_source)
  let func_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: 3)),
    ),
  ))
  let arg1_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 3, `end`: 4),
    ),
  ))
  let arg2_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 4, `end`: 5),
    ),
  ))
  let bind1 = result.ast.add_binding(astTF.Binding(value: some(arg1_id)))
  let bind2 = result.ast.add_binding(astTF.Binding(value: some(arg2_id)))
  var binding_first = result.ast.binding(bind1)
  binding_first.next = some(bind2)
  result.ast.data.bindings.get[bind1] = binding_first
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: func_id,
      arguments: some(bind1),
    ),
  ))


proc without_arguments *() :TestData=
  const input_source = "foo"
  result = create(input_source)
  let func_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: 3)),
    ),
  ))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: func_id,
    ),
  ))
