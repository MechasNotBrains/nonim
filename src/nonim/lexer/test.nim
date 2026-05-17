#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the lexer.
#_______________________________________________________________|
import minitest
import ../lexer


describe "nonim.lexer | Integration":
  it "must lex a simple identifier", proc()=
    var lexer = create("hello")
    lexer.process()
    lexer.result.len.eq 1
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[0].loc.start.eq 0'u64
    lexer.result[0].loc.`end`.eq 4'u64

  it "must lex a number", proc()=
    var lexer = create("42")
    lexer.process()
    lexer.result.len.eq 1
    lexer.result[0].id.eq LexemeId.number
    lexer.result[0].loc.start.eq 0'u64
    lexer.result[0].loc.`end`.eq 1'u64

  it "must lex identifier followed by paren and number", proc()=
    var lexer = create("foo(42)")
    lexer.process()
    lexer.result.len.eq 4
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[1].id.eq LexemeId.paren_L
    lexer.result[2].id.eq LexemeId.number
    lexer.result[3].id.eq LexemeId.paren_R

  it "must lex whitespace between tokens", proc()=
    var lexer = create("a b")
    lexer.process()
    lexer.result.len.eq 3
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[1].id.eq LexemeId.space
    lexer.result[2].id.eq LexemeId.ident

  it "must lex a variable declaration pattern", proc()=
    var lexer = create("let x:int=42")
    lexer.process()
    lexer.result.len.eq 7
    lexer.result[0].id.eq LexemeId.ident    # let
    lexer.result[1].id.eq LexemeId.space
    lexer.result[2].id.eq LexemeId.ident    # x
    lexer.result[3].id.eq LexemeId.colon
    lexer.result[4].id.eq LexemeId.ident    # int
    lexer.result[5].id.eq LexemeId.eq
    lexer.result[6].id.eq LexemeId.number   # 42

  it "must lex operators", proc()=
    var lexer = create("a+b")
    lexer.process()
    lexer.result.len.eq 3
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[1].id.eq LexemeId.plus
    lexer.result[2].id.eq LexemeId.ident

  it "must skip carriage return", proc()=
    var lexer = create("a\r\nb")
    lexer.process()
    lexer.result.len.eq 3
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[1].id.eq LexemeId.newline
    lexer.result[2].id.eq LexemeId.ident

  it "must extract source text from lexeme location", proc()=
    var lexer = create("hello")
    lexer.process()
    lexer.result[0].`from`(lexer.src).eq "hello"

