#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Variable.
#_______________________________________________________________|
import ./data


proc immutable_runtime *(type_name :static string = "int") :TestData=
  const input_name = "thing"
  const input_value = "42"
  const input_source = input_name & type_name & input_value & "567890Z"
  result = create(input_source)
  let name_loc  = astTF.Location(start: 0, `end`: uint64(input_name.len))
  let type_loc  = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + uint64(type_name.len))
  let value_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + uint64(input_value.len))
  let type_id   = result.ast.add_expression(astTF.Expression(
    kind       : astTF.eIdentifier,
    identifier : astTF.ExpressionIdentifier(
      name     : astTF.Identifier(location: type_loc),
    ),
  ))
  let value_id = result.ast.add_expression(astTF.Expression(
    kind    : astTF.eLiteral,
    literal : astTF.ExpressionLiteral(
      kind  : astTF.LiteralKind.integer,
      value : value_loc,
    ),
  ))
  let binding_id = result.ast.add_binding(astTF.Binding(
    name     : some(astTF.Identifier(location: name_loc)),
    mutable  : some(false),
    private  : some(true),
    runtime  : some(true),
    dataType : some(type_id),
    value    : some(value_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind     : astTF.sVariable,
    variable : astTF.StatementVariable(id: binding_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc mutable *() :TestData=
  const input_source = "thingint42"
  result = create(input_source)
  let type_id = result.ast.add_expression(astTF.Expression(
    kind       : astTF.eIdentifier,
    identifier : astTF.ExpressionIdentifier(
      name     : astTF.Identifier(location: astTF.Location(start: 5, `end`: 8)),
    ),
  ))
  let value_id = result.ast.add_expression(astTF.Expression(
    kind    : astTF.eLiteral,
    literal : astTF.ExpressionLiteral(
      kind  : astTF.LiteralKind.integer,
      value : astTF.Location(start: 8, `end`: 10),
    ),
  ))
  let binding_id = result.ast.add_binding(astTF.Binding(
    name     : some(astTF.Identifier(location: astTF.Location(start: 0, `end`: 5))),
    private  : some(true),
    mutable  : some(true),
    runtime  : some(true),
    dataType : some(type_id),
    value    : some(value_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind     : astTF.sVariable,
    variable : astTF.StatementVariable(id: binding_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc immutable_comptime *() :TestData=
  const input_source = "thingint42"
  result = create(input_source)
  let type_id = result.ast.add_expression(astTF.Expression(
    kind       : astTF.eIdentifier,
    identifier : astTF.ExpressionIdentifier(
      name     : astTF.Identifier(location: astTF.Location(start: 5, `end`: 8)),
    ),
  ))
  let value_id = result.ast.add_expression(astTF.Expression(
    kind    : astTF.eLiteral,
    literal : astTF.ExpressionLiteral(
      kind  : astTF.LiteralKind.integer,
      value : astTF.Location(start: 8, `end`: 10),
    ),
  ))
  let binding_id = result.ast.add_binding(astTF.Binding(
    name     : some(astTF.Identifier(location: astTF.Location(start: 0, `end`: 5))),
    private  : some(true),
    mutable  : some(false),
    runtime  : some(false),
    dataType : some(type_id),
    value    : some(value_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind     : astTF.sVariable,
    variable : astTF.StatementVariable(id: binding_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)

