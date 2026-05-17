#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/whitespace.nim
#_______________________________________________________________|
import minitest
import ./lexeme
import ./data
import ./whitespace


describe "nonim.lexer | Whitespace":
  it "must add a space lexeme when the current character is ` `", proc()=
    var lexer = create(" ")
    lexer.ch().eq ' '
    lexer.space()
    lexer.result[^1].id.eq LexemeId.space

  it "must raise when the current character is not ` `", proc()=
    var lexer = create("o")
    assert lexer.ch() != ' '
    var raised = false
    try: lexer.space()
    except LexError: raised = true
    raised.eq true


describe "nonim.lexer | Newline":
  it "must add a newline lexeme when the current character is `\\n`", proc()=
    var lexer = create("\n")
    lexer.ch().eq '\n'
    lexer.newline()
    lexer.result[^1].id.eq LexemeId.newline

  it "must raise when the current character is not `\\n`", proc()=
    var lexer = create("p")
    assert lexer.ch() != '\n'
    var raised = false
    try: lexer.newline()
    except LexError: raised = true
    raised.eq true


describe "nonim.lexer | Tab":
  it "must add a tab lexeme when the current character is `\\t`", proc()=
    var lexer = create("\t")
    lexer.ch().eq '\t'
    lexer.tab()
    lexer.result[^1].id.eq LexemeId.tab

  it "must raise when the current character is not `\\t`", proc()=
    var lexer = create("p")
    assert lexer.ch() != '\t'
    var raised = false
    try: lexer.tab()
    except LexError: raised = true
    raised.eq true
