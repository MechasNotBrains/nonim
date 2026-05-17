#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/lexeme.nim
#_______________________________________________________________|
import minitest
import ./source
import ./lexeme


describe "nonim.lexer | Lexeme.create":
  it "must create a lexeme with id and location", proc()=
    let location = Location(start: 0, `end`: 4)
    let result = create(LexemeId.ident, location)
    result.id.eq LexemeId.ident
    result.loc.start.eq 0'u64
    result.loc.`end`.eq 4'u64

  it "must create a lexeme with id and start/end positions", proc()=
    let result = create(LexemeId.number, 3'u64, 7'u64)
    result.id.eq LexemeId.number
    result.loc.start.eq 3'u64
    result.loc.`end`.eq 7'u64


describe "nonim.lexer | Lexeme.from":
  it "must extract the source text of the lexeme", proc()=
    let result = create(LexemeId.ident, 0'u64, 4'u64)
    result.`from`("hello world").eq "hello"

  it "must extract a single character", proc()=
    let result = create(LexemeId.star, 2'u64, 2'u64)
    result.`from`("ab*cd").eq "*"
