#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Lexer: Entry Point.
## Processes source code into a sequence of Lexemes.
#_______________________________________________________________|
import ./lexer/source
import ./lexer/lexeme
import ./lexer/data
import ./lexer/whitespace
import ./lexer/symbols
import ./lexer/others

export source, lexeme, data, whitespace, symbols, others


proc process *(lexer :var Lexer) =
  while lexer.pos < uint64(lexer.src.len):
    case lexer.ch()
    of 'a'..'z', 'A'..'Z', '_': lexer.ident()
    of '0'..'9':                 lexer.number()
    of '*':                      lexer.star()
    of '(', ')':                 lexer.paren()
    of '{', '}':                 lexer.brace()
    of '[', ']':                 lexer.bracket()
    of ':':                      lexer.colon()
    of ';':                      lexer.semicolon()
    of '.':                      lexer.dot()
    of ',':                      lexer.comma()
    of '=':                      lexer.eq()
    of '@':                      lexer.at()
    of '?':                      lexer.question()
    of '#':                      lexer.hash()
    of '$':                      lexer.dollar()
    of '-':                      lexer.dash()
    of '+':                      lexer.plus()
    of '<':                      lexer.less()
    of '>':                      lexer.more()
    of '~':                      lexer.tilde()
    of '!':                      lexer.excl()
    of '&':                      lexer.ampersand()
    of '%':                      lexer.percent()
    of '|':                      lexer.pipe()
    of '^':                      lexer.caret()
    of '/':                      lexer.slash_F()
    of '\\':                     lexer.slash_B()
    of '\'':                     lexer.quote_S()
    of '"':                      lexer.quote_D()
    of '`':                      lexer.quote_B()
    of ' ':                      lexer.space()
    of '\r':                     discard
    of '\n':                     lexer.newline()
    of '\t':                     lexer.tab()
    of '\0':                     lexer.eof()
    else: raise newException(LexError, "Unknown first character '" & lexer.ch() & "'")
    lexer.pos += 1
