#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Statement.Comment.
#_______________________________________________________________|
import ./data


proc line_from *(kind :static string) :TestData=
  const input_text = "this is a comment"
  const input_source = kind & input_text & "567890Z"
  result = create(input_source)
  let kind_loc = astTF.Location(start: 0, `end`: kind.len)
  let text_loc = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + input_text.len)
  let comment_id = result.ast.add_comment(astTF.Comment(
    kind: astTF.Identifier(location: kind_loc),
    text: text_loc,
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sComment,
    comment: astTF.StatementComment(id: comment_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc doc_from *(kind :static string) :TestData=
  const input_text = "this is a doc comment"
  const input_source = kind & input_text & "567890Z"
  result = create(input_source)
  let kind_loc = astTF.Location(start: 0, `end`: kind.len)
  let text_loc = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + input_text.len)
  let comment_id = result.ast.add_comment(astTF.Comment(
    kind: astTF.Identifier(location: kind_loc),
    text: text_loc,
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sComment,
    comment: astTF.StatementComment(id: comment_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)


proc multiline_from *(kind :static string) :TestData=
  const input_text = "first line\nsecond line\nthird line"
  const input_source = kind & input_text & "567890Z"
  result = create(input_source)
  let kind_loc = astTF.Location(start: 0, `end`: kind.len)
  let text_loc = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + input_text.len)
  let comment_id = result.ast.add_comment(astTF.Comment(
    kind: astTF.Identifier(location: kind_loc),
    text: text_loc,
  ))
  result.id = result.ast.add_statement(astTF.Statement(
    kind: astTF.sComment,
    comment: astTF.StatementComment(id: comment_id),
  ))
  result.ast.data.modules[result.module].body = some(result.id)
