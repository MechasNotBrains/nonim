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
    kind      : astTF.eLiteral,
    literal   : astTF.ExpressionLiteral(
      kind    : astTF.LiteralKind.integer,
      value   : astTF.Location(start: 3, `end`: 4),
    ),
  ))
  let arg2_id = result.ast.add_expression(astTF.Expression(
    kind    : astTF.eLiteral,
    literal : astTF.ExpressionLiteral(
      kind  : astTF.LiteralKind.integer,
      value : astTF.Location(start: 4, `end`: 5),
    ),
  ))
  let bind1 = result.ast.add_binding(astTF.Binding(value: some(arg1_id), runtime: some(true)))
  let bind2 = result.ast.add_binding(astTF.Binding(value: some(arg2_id), runtime: some(true)))
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


proc with_generics *() :TestData=
  const input_source = "newSeqint42"
  result = create(input_source)
  let func_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: 6)),
    ),
  ))
  let generic_type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: astTF.Location(start: 6, `end`: 9))),
  ))
  let generic_type_expr = result.ast.add_expression_type(generic_type_id)
  let generic_binding = result.ast.add_binding(astTF.Binding(dataType: some(generic_type_expr), runtime: some(true)))
  let arg_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.integer,
      value: astTF.Location(start: 9, `end`: 11),
    ),
  ))
  let arg_binding = result.ast.add_binding(astTF.Binding(value: some(arg_id), runtime: some(true)))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: func_id,
      generics: some(generic_binding),
      arguments: some(arg_binding),
    ),
  ))


proc with_multi_generics *() :TestData=
  const input_source = "mapintstring"
  result = create(input_source)
  let func_id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: astTF.Location(start: 0, `end`: 3)),
    ),
  ))
  let generic_type1 = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: astTF.Location(start: 3, `end`: 6))),
  ))
  let generic_type2 = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: astTF.Location(start: 6, `end`: 12))),
  ))
  let generic_expr1 = result.ast.add_expression_type(generic_type1)
  let generic_expr2 = result.ast.add_expression_type(generic_type2)
  let generic_bind2 = result.ast.add_binding(astTF.Binding(dataType: some(generic_expr2), runtime: some(true)))
  let generic_bind1 = result.ast.add_binding(astTF.Binding(dataType: some(generic_expr1), runtime: some(true), next: some(generic_bind2)))
  result.id = result.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: func_id,
      generics: some(generic_bind1),
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
