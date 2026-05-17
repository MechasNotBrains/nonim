#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/char.nim
#_______________________________________________________________|
import minitest
import ./char


describe "nonim.lexer | char.is_eof":
  it "must return true for null byte", proc()=
    is_eof('\0').eq true

  it "must return false for non-null", proc()=
    is_eof('a').eq false


describe "nonim.lexer | char.is_numeric":
  it "must return true for digits", proc()=
    is_numeric('0').eq true
    is_numeric('9').eq true

  it "must return true for hex letters", proc()=
    is_numeric('a').eq true
    is_numeric('F').eq true

  it "must return true for numeric prefixes", proc()=
    is_numeric('x').eq true
    is_numeric('b').eq true
    is_numeric('o').eq true

  it "must return true for underscore separator", proc()=
    is_numeric('_').eq true

  it "must return false for non-numeric", proc()=
    is_numeric('g').eq false
    is_numeric(' ').eq false


describe "nonim.lexer | char.is_ident":
  it "must return true for letters", proc()=
    is_ident('a').eq true
    is_ident('Z').eq true

  it "must return true for underscore", proc()=
    is_ident('_').eq true

  it "must return true for digits", proc()=
    is_ident('0').eq true

  it "must return false for operators", proc()=
    is_ident('+').eq false
    is_ident(' ').eq false


describe "nonim.lexer | char.is_context_change":
  it "must return true for whitespace", proc()=
    is_context_change(' ').eq true
    is_context_change('\n').eq true

  it "must return true for operators", proc()=
    is_context_change('+').eq true
    is_context_change('=').eq true

  it "must return true for quotes", proc()=
    is_context_change('"').eq true

  it "must return true for parentheses", proc()=
    is_context_change('(').eq true

  it "must return true for null byte", proc()=
    is_context_change('\0').eq true

  it "must return false for identifier chars", proc()=
    is_context_change('a').eq false
    is_context_change('5').eq false
