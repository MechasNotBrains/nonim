#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/lexer/symbols.nim
#_______________________________________________________________|
import minitest
import ./lexeme
import ./data
import ./whitespace
import ./symbols


describe "nonim.lexer | Parentheses":
  it "must lex ( as paren_L", proc()=
    var lexer = create("(")
    lexer.paren()
    lexer.result[^1].id.eq LexemeId.paren_L

  it "must lex ) as paren_R", proc()=
    var lexer = create(")")
    lexer.paren()
    lexer.result[^1].id.eq LexemeId.paren_R

  it "must raise on non-paren character", proc()=
    var lexer = create("x")
    var raised = false
    try: lexer.paren()
    except LexError: raised = true
    raised.eq true


describe "nonim.lexer | Braces":
  it "must lex { as brace_L", proc()=
    var lexer = create("{")
    lexer.brace()
    lexer.result[^1].id.eq LexemeId.brace_L

  it "must lex } as brace_R", proc()=
    var lexer = create("}")
    lexer.brace()
    lexer.result[^1].id.eq LexemeId.brace_R


describe "nonim.lexer | Brackets":
  it "must lex [ as bracket_L", proc()=
    var lexer = create("[")
    lexer.bracket()
    lexer.result[^1].id.eq LexemeId.bracket_L

  it "must lex ] as bracket_R", proc()=
    var lexer = create("]")
    lexer.bracket()
    lexer.result[^1].id.eq LexemeId.bracket_R


describe "nonim.lexer | Single-char symbols":
  it "must lex = as eq", proc()=
    var lexer = create("=")
    lexer.eq()
    lexer.result[^1].id.eq LexemeId.eq

  it "must lex @ as at", proc()=
    var lexer = create("@")
    lexer.at()
    lexer.result[^1].id.eq LexemeId.at

  it "must lex * as star", proc()=
    var lexer = create("*")
    lexer.star()
    lexer.result[^1].id.eq LexemeId.star

  it "must lex : as colon", proc()=
    var lexer = create(":")
    lexer.colon()
    lexer.result[^1].id.eq LexemeId.colon

  it "must lex ; as semicolon", proc()=
    var lexer = create(";")
    lexer.semicolon()
    lexer.result[^1].id.eq LexemeId.semicolon

  it "must lex . as dot", proc()=
    var lexer = create(".")
    lexer.dot()
    lexer.result[^1].id.eq LexemeId.dot

  it "must lex , as comma", proc()=
    var lexer = create(",")
    lexer.comma()
    lexer.result[^1].id.eq LexemeId.comma

  it "must lex # as hash", proc()=
    var lexer = create("#")
    lexer.hash()
    lexer.result[^1].id.eq LexemeId.hash

  it "must lex $ as dollar", proc()=
    var lexer = create("$")
    lexer.dollar()
    lexer.result[^1].id.eq LexemeId.dollar


describe "nonim.lexer | Quotes":
  it "must lex ' as quote_S", proc()=
    var lexer = create("'")
    lexer.quote_S()
    lexer.result[^1].id.eq LexemeId.quote_S

  it "must lex \" as quote_D", proc()=
    var lexer = create("\"")
    lexer.quote_D()
    lexer.result[^1].id.eq LexemeId.quote_D

  it "must lex ` as quote_B", proc()=
    var lexer = create("`")
    lexer.quote_B()
    lexer.result[^1].id.eq LexemeId.quote_B


describe "nonim.lexer | Slashes":
  it "must lex / as slash_F", proc()=
    var lexer = create("/")
    lexer.slash_F()
    lexer.result[^1].id.eq LexemeId.slash_F

  it "must lex \\ as slash_B", proc()=
    var lexer = create("\\")
    lexer.slash_B()
    lexer.result[^1].id.eq LexemeId.slash_B


describe "nonim.lexer | Operators":
  it "must lex - as dash", proc()=
    var lexer = create("-")
    lexer.dash()
    lexer.result[^1].id.eq LexemeId.dash

  it "must lex + as plus", proc()=
    var lexer = create("+")
    lexer.plus()
    lexer.result[^1].id.eq LexemeId.plus

  it "must lex < as less", proc()=
    var lexer = create("<")
    lexer.less()
    lexer.result[^1].id.eq LexemeId.less

  it "must lex > as more", proc()=
    var lexer = create(">")
    lexer.more()
    lexer.result[^1].id.eq LexemeId.more

  it "must lex ~ as tilde", proc()=
    var lexer = create("~")
    lexer.tilde()
    lexer.result[^1].id.eq LexemeId.tilde

  it "must lex ! as excl", proc()=
    var lexer = create("!")
    lexer.excl()
    lexer.result[^1].id.eq LexemeId.excl

  it "must lex & as ampersand", proc()=
    var lexer = create("&")
    lexer.ampersand()
    lexer.result[^1].id.eq LexemeId.ampersand

  it "must lex % as percent", proc()=
    var lexer = create("%")
    lexer.percent()
    lexer.result[^1].id.eq LexemeId.percent

  it "must lex | as pipe", proc()=
    var lexer = create("|")
    lexer.pipe()
    lexer.result[^1].id.eq LexemeId.pipe

  it "must lex ^ as caret", proc()=
    var lexer = create("^")
    lexer.caret()
    lexer.result[^1].id.eq LexemeId.caret

  it "must lex ? as question", proc()=
    var lexer = create("?")
    lexer.question()
    lexer.result[^1].id.eq LexemeId.question
