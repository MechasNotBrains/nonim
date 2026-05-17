#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type.Ptr.
#_______________________________________________________________|
import ./data


proc simple *() :TestData=
  const input_name = "cint"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let target_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: name_loc)),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tPtr,
    `ptr`: astTF.TypePtr(target: target_id),
  ))


proc to_ptr *() :TestData=
  const input_name = "cint"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let inner_id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: name_loc)),
  ))
  let ptr_inner = result.ast.add_type(astTF.Type(
    kind: astTF.tPtr,
    `ptr`: astTF.TypePtr(target: inner_id),
  ))
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tPtr,
    `ptr`: astTF.TypePtr(target: ptr_inner),
  ))
