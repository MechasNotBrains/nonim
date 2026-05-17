#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type.Procedure.
#_______________________________________________________________|
import ./data


proc with_args_and_return *() :TestData=
  const input_arg = "a"
  const input_type = "cint"
  const input_pragma = "cdecl"
  const input_source = input_arg & input_type & input_pragma & "567890Z"
  result = create(input_source)
  let arg_loc = astTF.Location(start: 0, `end`: input_arg.len)
  let type_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let pragma_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_pragma.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  let args_id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: arg_loc)),
    dataType: some(type_expr),
    private: some(true),
  ))
  let pragma_key = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: pragma_loc)),
  ))
  let pragma_id = result.ast.add_pragma(astTF.Pragma(key: pragma_key))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    arguments: some(args_id),
    returnType: some(type_expr),
    pragmas: some(pragma_id),
    impure: some(true),
    private: some(true),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tProcedure,
    procedure: astTF.TypeProcedure(id: proc_id),
  ))


proc without_return *() :TestData=
  const input_arg = "a"
  const input_type = "cint"
  const input_pragma = "cdecl"
  const input_source = input_arg & input_type & input_pragma & "567890Z"
  result = create(input_source)
  let arg_loc = astTF.Location(start: 0, `end`: input_arg.len)
  let type_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let pragma_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_pragma.len)
  let type_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc)),
  ))
  let type_expr = result.ast.add_expression_type(type_id)
  let args_id = result.ast.add_binding(astTF.Binding(
    name: some(astTF.Identifier(location: arg_loc)),
    dataType: some(type_expr),
    private: some(true),
  ))
  let pragma_key = result.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: pragma_loc)),
  ))
  let pragma_id = result.ast.add_pragma(astTF.Pragma(key: pragma_key))
  let proc_id = result.ast.add_procedure(astTF.Procedure(
    arguments: some(args_id),
    pragmas: some(pragma_id),
    impure: some(true),
    private: some(true),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tProcedure,
    procedure: astTF.TypeProcedure(id: proc_id),
  ))
