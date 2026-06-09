#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Procedure arguments.
#_______________________________________________________________|
import ./data


proc shared_type *() :TestData=
  const input_name   = "step"
  const input_param1 = "val"
  const input_param2 = "target"
  const input_param3 = "amount"
  const input_type   = "anytype"
  const input_source = input_name & input_param1 & input_param2 & input_param3 & input_type & "567890Z"
  result = create(input_source)
  let name_loc   = astTF.Location(start: 0, `end`: input_name.len)
  var offset     = name_loc.`end`
  let param1_loc = astTF.Location(start: offset, `end`: offset + input_param1.len); offset += input_param1.len
  let param2_loc = astTF.Location(start: offset, `end`: offset + input_param2.len); offset += input_param2.len
  let param3_loc = astTF.Location(start: offset, `end`: offset + input_param3.len); offset += input_param3.len
  let type_loc   = astTF.Location(start: offset, `end`: offset + input_type.len); offset += input_type.len
  let type_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let type_expr  = result.ast.add_expression_type(type_id)
  let ret_expr   = result.ast.add_expression_type(type_id)
  let param3_id  = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param3_loc)), dataType: some(type_expr), private: some(true), runtime: some(true)))
  let param2_id  = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param2_loc)), private: some(true), runtime: some(true), next: some(param3_id)))
  let param1_id  = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param1_loc)), private: some(true), runtime: some(true), next: some(param2_id)))
  let proc_id    = result.ast.add_procedure(astTF.Procedure(
    name         : some(astTF.Identifier(location: name_loc)),
    arguments    : some(param1_id),
    returnType   : some(ret_expr),
    impure       : some(true),
    private      : some(true),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind      : astTF.sProcedure,
    procedure : astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc const_pointer *() :TestData=
  const input_name   = "destroy"
  const input_param1 = "self"
  const input_type1  = "Type"
  const input_param2 = "gpu"
  const input_type2  = "Gpu"
  const input_source = input_name & input_param1 & input_type1 & input_param2 & input_type2 & "567890Z"
  result = create(input_source)
  let name_loc    = astTF.Location(start: 0, `end`: input_name.len)
  var offset      = name_loc.`end`
  let param1_loc  = astTF.Location(start: offset, `end`: offset + input_param1.len); offset += input_param1.len
  let type1_loc   = astTF.Location(start: offset, `end`: offset + input_type1.len); offset += input_type1.len
  let param2_loc  = astTF.Location(start: offset, `end`: offset + input_param2.len); offset += input_param2.len
  let type2_loc   = astTF.Location(start: offset, `end`: offset + input_type2.len); offset += input_type2.len
  let type1_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type1_loc))))
  let ptr1_id     = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(target: type1_id)))
  let ptr1_expr   = result.ast.add_expression_type(ptr1_id)
  let type2_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type2_loc))))
  let ptr2_id     = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(target: type2_id)))
  let ptr2_expr   = result.ast.add_expression_type(ptr2_id)
  let param2_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param2_loc)), dataType: some(ptr2_expr), private: some(true), runtime: some(true)))
  let param1_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param1_loc)), dataType: some(ptr1_expr), private: some(true), runtime: some(true), next: some(param2_id)))
  let proc_id     = result.ast.add_procedure(astTF.Procedure(
    name          : some(astTF.Identifier(location: name_loc)),
    arguments     : some(param1_id),
    impure        : some(true),
    private       : some(true),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind      : astTF.sProcedure,
    procedure : astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc mutable_pointer *() :TestData=
  const input_name  = "update"
  const input_param = "self"
  const input_type  = "Type"
  const input_source = input_name & input_param & input_type & "567890Z"
  result = create(input_source)
  let name_loc   = astTF.Location(start: 0, `end`: input_name.len)
  var offset     = name_loc.`end`
  let param_loc  = astTF.Location(start: offset, `end`: offset + input_param.len); offset += input_param.len
  let type_loc   = astTF.Location(start: offset, `end`: offset + input_type.len); offset += input_type.len
  let type_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type_loc))))
  let ptr_id     = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(target: type_id, mutable: some(true))))
  let ptr_expr   = result.ast.add_expression_type(ptr_id)
  let param_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param_loc)), dataType: some(ptr_expr), private: some(true), runtime: some(true)))
  let proc_id    = result.ast.add_procedure(astTF.Procedure(
    name         : some(astTF.Identifier(location: name_loc)),
    arguments    : some(param_id),
    impure       : some(true),
    private      : some(true),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind      : astTF.sProcedure,
    procedure : astTF.StatementProcedure(id: proc_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
