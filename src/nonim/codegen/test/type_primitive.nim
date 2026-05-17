#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type.Primitive.
#_______________________________________________________________|
import ./data


proc named *() :TestData=
  const input_name = "cint"
  const input_source = input_name & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  result.id = result.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: name_loc)),
  ))
