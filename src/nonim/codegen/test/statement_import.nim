#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Import.
#_______________________________________________________________|
import ./data


proc simple *() :TestData=
  const input_keyword = "import"
  const input_path = "foo"
  const input_source = input_keyword & input_path & "567890Z"
  result = create(input_source)
  let keyw_loc = astTF.Location(start: 0, `end`: input_keyword.len)
  let path_loc = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_path.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sImport,
    `import`: astTF.StatementImport(
      keyword: some(astTF.Identifier(location: keyw_loc)),
      path: path_loc,
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc from_symbols *() :TestData=
  const input_keyword = "from"
  const input_path = "foo"
  const input_sym1 = "bar"
  const input_sym2 = "baz"
  const input_source = input_keyword & input_path & input_sym1 & input_sym2 & "567890Z"
  result = create(input_source)
  let keyw_loc = astTF.Location(start: 0, `end`: input_keyword.len)
  let path_loc = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_path.len)
  let sym1_loc = astTF.Location(start: path_loc.`end`, `end`: path_loc.`end` + input_sym1.len)
  let sym2_loc = astTF.Location(start: sym1_loc.`end`, `end`: sym1_loc.`end` + input_sym2.len)
  let alias2 = result.ast.add_alias(astTF.Alias(name: astTF.Identifier(location: sym2_loc)))
  let alias1 = result.ast.add_alias(astTF.Alias(name: astTF.Identifier(location: sym1_loc), next: some(alias2)))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sImport,
    `import`: astTF.StatementImport(
      keyword: some(astTF.Identifier(location: keyw_loc)),
      path: path_loc,
      symbols: some(alias1),
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc include_simple *() :TestData=
  const input_keyword = "include"
  const input_path = "stdio"
  const input_source = input_keyword & input_path & "567890Z"
  result = create(input_source)
  let keyw_loc = astTF.Location(start: 0, `end`: input_keyword.len)
  let path_loc = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_path.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sImport,
    `import`: astTF.StatementImport(
      keyword: some(astTF.Identifier(location: keyw_loc)),
      path: path_loc,
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc include_global *() :TestData=
  const input_path = "stdint.h"
  const input_source = input_path & "567890Z"
  result = create(input_source)
  let path_loc = astTF.Location(start: 0, `end`: input_path.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sImport,
    `import`: astTF.StatementImport(
      path: path_loc,
      global: some(true),
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc include_local *() :TestData=
  const input_path = "path/to/file.h"
  const input_source = input_path & "567890Z"
  result = create(input_source)
  let path_loc = astTF.Location(start: 0, `end`: input_path.len)
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sImport,
    `import`: astTF.StatementImport(
      path: path_loc,
      global: some(false),
    ),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
