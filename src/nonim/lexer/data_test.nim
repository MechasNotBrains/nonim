#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/data.nim
#_______________________________________________________________|
import minitest
import ./source
import ./lexeme
import ./data


describe "nonim.lexer | data.ch":
  it "must return the character at the current position", proc()=
    var lexer = create("arstqwfp1234")
    lexer.pos = 5
    lexer.ch().eq 'w'


describe "nonim.lexer | data.add_to_last":
  it "must increment the end of the last lexeme by 1", proc()=
    var lexer = create("ab")
    lexer.result.add(Lexeme(id: LexemeId.ident, loc: Location(start: 0, `end`: 0)))
    lexer.add_to_last('b')
    lexer.result[^1].loc.`end`.eq 1'u64


describe "nonim.lexer | data.add_one":
  it "must append a new lexeme with the given id and range", proc()=
    var lexer = create("hello")
    lexer.add_one(LexemeId.ident, 0, 4)
    lexer.result.len.eq 1
    lexer.result[0].id.eq LexemeId.ident
    lexer.result[0].loc.start.eq 0'u64
    lexer.result[0].loc.`end`.eq 4'u64


describe "nonim.lexer | data.add_single":
  it "must append a new lexeme at the current position", proc()=
    var lexer = create("(")
    lexer.pos = 0
    lexer.add_single(LexemeId.paren_L)
    lexer.result.len.eq 1
    lexer.result[0].id.eq LexemeId.paren_L
    lexer.result[0].loc.start.eq 0'u64
    lexer.result[0].loc.`end`.eq 0'u64
