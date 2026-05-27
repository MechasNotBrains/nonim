#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Procedures.
#_______________________________________________________________|
import ./data


proc public_impure *() :TestData=
  const input_name = "thing"
  const input_arg = "a"
  const input_type = "int"
  const input_source = input_name & input_arg & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let arg_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_arg.len)
  let type_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let args_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    arguments: some(args_id),
    returnType: some(type_expr),
    impure: some(true),
  ))


proc private_impure *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_source = input_name & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    returnType: some(type_expr),
    impure: some(true),
    private: some(true),
  ))


proc public_pure *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_source = input_name & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    returnType: some(type_expr),
  ))


proc no_return_type *() :TestData=
  const input_name = "thing"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
  ))


proc with_pragmas *() :TestData=
  const input_name = "thing"
  const input_type = "int"
  const input_pragma = "cdecl"
  const input_source = input_name & input_type & input_pragma & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let type_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_type.len)
  let pragma_loc = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + input_pragma.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let pragma_key = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: pragma_loc))))
  let pragma_id = result.ast.add_pragma(astTF.Pragma(key: pragma_key))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    returnType: some(type_expr),
    pragmas: some(pragma_id),
  ))


proc callable_template *() :TestData=
  const input_name = "thing"
  const input_callable = "template"
  const input_source = input_name & input_callable & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let call_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_callable.len)
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    callable: some(astTF.Identifier(location: call_loc)),
  ))


proc callable_method *() :TestData=
  const input_name = "thing"
  const input_callable = "method"
  const input_arg = "a"
  const input_type = "int"
  const input_source = input_name & input_callable & input_arg & input_type & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let call_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_callable.len)
  let arg_loc = astTF.Location(start: call_loc.`end`, `end`: call_loc.`end` + input_arg.len)
  let type_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let args_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    callable: some(astTF.Identifier(location: call_loc)),
    arguments: some(args_id),
    returnType: some(type_expr),
    impure: some(true),
  ))


proc as_type *() :TestData=
  const input_arg = "a"
  const input_type = "int"
  const input_source = input_arg & input_type & "567890Z"
  result = create(input_source)
  let arg_loc = astTF.Location(start: 0, `end`: input_arg.len)
  let type_loc = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + input_type.len)
  let type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr = result.ast.add_expression_type(type_id)
  let args_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: astTF.Location(start: 0, `end`: 1))),
    arguments: some(args_id),
    returnType: some(type_expr),
    impure: some(true),
  ))


proc generic *() :TestData=
  const input_name = "clamp"
  const input_param = "T"
  const input_arg1 = "value"
  const input_arg2 = "low"
  const input_arg3 = "high"
  const input_source = input_name & input_param & input_arg1 & input_arg2 & input_arg3 & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let param_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_param.len)
  let arg1_loc = astTF.Location(start: param_loc.`end`, `end`: param_loc.`end` + input_arg1.len)
  let arg2_loc = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + input_arg2.len)
  let arg3_loc = astTF.Location(start: arg2_loc.`end`, `end`: arg2_loc.`end` + input_arg3.len)
  let generic_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param_loc)), private: some(true)))
  let param_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: param_loc))))
  let param_type_expr = result.ast.add_expression_type(param_type_id)
  let arg3_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg3_loc)), dataType: some(param_type_expr), private: some(true)))
  let arg2_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg2_loc)), dataType: some(param_type_expr), private: some(true), next: some(arg3_id)))
  let arg1_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg1_loc)), dataType: some(param_type_expr), private: some(true), next: some(arg2_id)))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    generics: some(generic_id),
    arguments: some(arg1_id),
    returnType: some(param_type_expr),
    impure: some(true),
  ))


proc generic_multi *() :TestData=
  const input_name = "map"
  const input_k = "K"
  const input_v = "V"
  const input_arg1 = "key"
  const input_arg2 = "value"
  const input_source = input_name & input_k & input_v & input_arg1 & input_arg2 & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let k_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_k.len)
  let v_loc = astTF.Location(start: k_loc.`end`, `end`: k_loc.`end` + input_v.len)
  let arg1_loc = astTF.Location(start: v_loc.`end`, `end`: v_loc.`end` + input_arg1.len)
  let arg2_loc = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + input_arg2.len)
  let generic_v = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: v_loc)), private: some(true)))
  let generic_k = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: k_loc)), private: some(true), next: some(generic_v)))
  let k_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: k_loc))))
  let v_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: v_loc))))
  let k_type_expr = result.ast.add_expression_type(k_type_id)
  let v_type_expr = result.ast.add_expression_type(v_type_id)
  let arg2_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg2_loc)), dataType: some(v_type_expr), private: some(true)))
  let arg1_id = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg1_loc)), dataType: some(k_type_expr), private: some(true), next: some(arg2_id)))
  result.id = result.ast.add_procedure(astTF.Procedure(
    name: some(astTF.Identifier(location: name_loc)),
    generics: some(generic_k),
    arguments: some(arg1_id),
    returnType: some(v_type_expr),
    impure: some(true),
  ))
