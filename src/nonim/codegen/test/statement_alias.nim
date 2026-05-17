#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Alias.
#_______________________________________________________________|
import ./data


proc simple *() :TestData=
  const input_name = "A"
  const input_target = "B"
  const input_source = input_name & input_target & "567890Z"
  result = create(input_source)
  let name_loc = astTF.Location(start: 0, `end`: input_name.len)
  let target_loc = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_target.len)
  let alias_id = result.ast.add_alias(astTF.Alias(
    name: astTF.Identifier(location: name_loc),
    target: some(astTF.Identifier(location: target_loc)),
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sAlias,
    alias: astTF.StatementAlias(id: alias_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
