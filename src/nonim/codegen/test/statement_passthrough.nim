#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Passthrough.
#_______________________________________________________________|
import ./data


proc simple *() :TestData=
  const input_text = "# unsupported: __attribute__((packed))"
  const input_source = input_text & "567890Z"
  result = create(input_source)
  let text_loc = astTF.Location(start: 0, `end`: input_text.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sPassthrough,
    passthrough: astTF.StatementPassthrough(location: text_loc),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
