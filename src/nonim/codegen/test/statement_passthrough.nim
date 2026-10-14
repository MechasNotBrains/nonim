#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Passthrough.
#_______________________________________________________________|
import ./data


proc simple *() :TestData=
  const input_text = "__some_thing   =   42;"
  const input_source = input_text & "567890Z"
  result = create(input_source)
  let text_loc = astTF.Location(start: 0, `end`: input_text.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sPassthrough,
    passthrough: astTF.StatementPassthrough(location: text_loc),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc procedure_body *() :TestData=
  const input_name   = "thing"
  const input_type   = "void"
  const input_text   = "__some_thing   =   42;"
  const input_source = input_name & input_type & input_text & "567890Z"
  result = create(input_source)
  let name_loc  = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc  = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let text_loc  = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_text.len)
  let type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let depth_id  = result.ast.add_depth(astTF.Depth(indent: some(1'u64)))
  let body_id   = result.ast.add_statement(astTF.Statement(
    kind        : astTF.sPassthrough,
    passthrough : astTF.StatementPassthrough(
      location  : text_loc,
      depth     : some(depth_id),
    ),
  ))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    name       : some(astTF.Identifier(location: name_loc)),
    returnType : some(type_expr),
    impure     : some(true),
    private    : some(true),
    body       : some(body_id),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind      : astTF.sProcedure,
    procedure : astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc with_quotes *() :TestData=
  const input_text = "printf(\"hello world\");"
  const input_source = input_text & "567890Z"
  result = create(input_source)
  let text_loc = astTF.Location(start: 0, `end`: input_text.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sPassthrough,
    passthrough: astTF.StatementPassthrough(location: text_loc),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
