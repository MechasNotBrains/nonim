#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/others.nim
#_______________________________________________________________|
import minitest
import ./source
import ./lexeme
import ./data
import ./whitespace
import ./others


describe "nonim.lexer | Identifiers":
  it "must lex a single-char identifier", proc()=
    var lexer = create("x ")
    lexer.ident()
    lexer.result[^1].id.eq LexemeId.ident
    lexer.result[^1].loc.start.eq 0'u64
    lexer.result[^1].loc.`end`.eq 0'u64

  it "must lex a multi-char identifier", proc()=
    var lexer = create("hello ")
    lexer.ident()
    lexer.result[^1].id.eq LexemeId.ident
    lexer.result[^1].loc.start.eq 0'u64
    lexer.result[^1].loc.`end`.eq 4'u64

  it "must lex an identifier with underscore", proc()=
    var lexer = create("my_var ")
    lexer.ident()
    lexer.result[^1].id.eq LexemeId.ident
    lexer.result[^1].`from`(lexer.src).eq "my_var"

  it "must stop at context change character", proc()=
    var lexer = create("foo(")
    lexer.ident()
    lexer.result[^1].`from`(lexer.src).eq "foo"

  it "must lex identifier at end of source", proc()=
    var lexer = create("abc")
    lexer.ident()
    lexer.result[^1].`from`(lexer.src).eq "abc"


describe "nonim.lexer | Numbers":
  it "must lex a single digit", proc()=
    var lexer = create("5 ")
    lexer.number()
    lexer.result[^1].id.eq LexemeId.number
    lexer.result[^1].`from`(lexer.src).eq "5"

  it "must lex a multi-digit number", proc()=
    var lexer = create("42 ")
    lexer.number()
    lexer.result[^1].id.eq LexemeId.number
    lexer.result[^1].`from`(lexer.src).eq "42"

  it "must lex a hex number", proc()=
    var lexer = create("0xFF ")
    lexer.number()
    lexer.result[^1].`from`(lexer.src).eq "0xFF"

  it "must lex a number with underscore separator", proc()=
    var lexer = create("1_000 ")
    lexer.number()
    lexer.result[^1].`from`(lexer.src).eq "1_000"

  it "must stop at context change character", proc()=
    var lexer = create("42+")
    lexer.number()
    lexer.result[^1].`from`(lexer.src).eq "42"

  it "must lex number at end of source", proc()=
    var lexer = create("99")
    lexer.number()
    lexer.result[^1].`from`(lexer.src).eq "99"


describe "nonim.lexer | EOF":
  it "must lex null byte as EOF", proc()=
    var lexer = create("\0")
    lexer.eof()
    lexer.result[^1].id.eq LexemeId.EOF

  it "must raise on non-null character", proc()=
    var lexer = create("x")
    var raised = false
    try: lexer.eof()
    except LexError: raised = true
    raised.eq true
