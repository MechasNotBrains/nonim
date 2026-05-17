#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Lexer Process: Whitespace.
#_______________________________________________________________|
import ./lexeme
import ./data


type LexError * = object of CatchableError

proc space *(lexer :var Lexer) =
  case lexer.ch()
  of ' ': lexer.add_single(LexemeId.space)
  else: raise newException(LexError, "Unknown Space character '" & lexer.ch() & "'")

proc newline *(lexer :var Lexer) =
  case lexer.ch()
  of '\n': lexer.add_single(LexemeId.newline)
  else: raise newException(LexError, "Unknown NewLine character '" & lexer.ch() & "'")

proc tab *(lexer :var Lexer) =
  case lexer.ch()
  of '\t': lexer.add_single(LexemeId.tab)
  else: raise newException(LexError, "Unknown Tab character '" & lexer.ch() & "'")
