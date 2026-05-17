#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Lexer Process: Symbols.
#_______________________________________________________________|
import ./lexeme
import ./data
import ./whitespace


proc paren *(lexer :var Lexer) =
  case lexer.ch()
  of '(': lexer.add_single(LexemeId.paren_L)
  of ')': lexer.add_single(LexemeId.paren_R)
  else: raise newException(LexError, "Unknown Paren character '" & lexer.ch() & "'")

proc brace *(lexer :var Lexer) =
  case lexer.ch()
  of '{': lexer.add_single(LexemeId.brace_L)
  of '}': lexer.add_single(LexemeId.brace_R)
  else: raise newException(LexError, "Unknown Brace character '" & lexer.ch() & "'")

proc bracket *(lexer :var Lexer) =
  case lexer.ch()
  of '[': lexer.add_single(LexemeId.bracket_L)
  of ']': lexer.add_single(LexemeId.bracket_R)
  else: raise newException(LexError, "Unknown Bracket character '" & lexer.ch() & "'")

proc eq *(lexer :var Lexer) =
  case lexer.ch()
  of '=': lexer.add_single(LexemeId.eq)
  else: raise newException(LexError, "Unknown Equal character '" & lexer.ch() & "'")

proc at *(lexer :var Lexer) =
  case lexer.ch()
  of '@': lexer.add_single(LexemeId.at)
  else: raise newException(LexError, "Unknown At character '" & lexer.ch() & "'")

proc star *(lexer :var Lexer) =
  case lexer.ch()
  of '*': lexer.add_single(LexemeId.star)
  else: raise newException(LexError, "Unknown Star character '" & lexer.ch() & "'")

proc colon *(lexer :var Lexer) =
  case lexer.ch()
  of ':': lexer.add_single(LexemeId.colon)
  else: raise newException(LexError, "Unknown Colon character '" & lexer.ch() & "'")

proc semicolon *(lexer :var Lexer) =
  case lexer.ch()
  of ';': lexer.add_single(LexemeId.semicolon)
  else: raise newException(LexError, "Unknown Semicolon character '" & lexer.ch() & "'")

proc dot *(lexer :var Lexer) =
  case lexer.ch()
  of '.': lexer.add_single(LexemeId.dot)
  else: raise newException(LexError, "Unknown Dot character '" & lexer.ch() & "'")

proc comma *(lexer :var Lexer) =
  case lexer.ch()
  of ',': lexer.add_single(LexemeId.comma)
  else: raise newException(LexError, "Unknown Comma character '" & lexer.ch() & "'")

proc hash *(lexer :var Lexer) =
  case lexer.ch()
  of '#': lexer.add_single(LexemeId.hash)
  else: raise newException(LexError, "Unknown Hash character '" & lexer.ch() & "'")

proc dollar *(lexer :var Lexer) =
  case lexer.ch()
  of '$': lexer.add_single(LexemeId.dollar)
  else: raise newException(LexError, "Unknown Dollar character '" & lexer.ch() & "'")

proc quote_S *(lexer :var Lexer) =
  case lexer.ch()
  of '\'': lexer.add_single(LexemeId.quote_S)
  else: raise newException(LexError, "Unknown Single Quote character '" & lexer.ch() & "'")

proc quote_D *(lexer :var Lexer) =
  case lexer.ch()
  of '"': lexer.add_single(LexemeId.quote_D)
  else: raise newException(LexError, "Unknown Double Quote character '" & lexer.ch() & "'")

proc quote_B *(lexer :var Lexer) =
  case lexer.ch()
  of '`': lexer.add_single(LexemeId.quote_B)
  else: raise newException(LexError, "Unknown Backtick Quote character '" & lexer.ch() & "'")

proc slash_F *(lexer :var Lexer) =
  case lexer.ch()
  of '/': lexer.add_single(LexemeId.slash_F)
  else: raise newException(LexError, "Unknown Forward Slash character '" & lexer.ch() & "'")

proc slash_B *(lexer :var Lexer) =
  case lexer.ch()
  of '\\': lexer.add_single(LexemeId.slash_B)
  else: raise newException(LexError, "Unknown Backward Slash character '" & lexer.ch() & "'")

proc dash *(lexer :var Lexer) =
  case lexer.ch()
  of '-': lexer.add_single(LexemeId.dash)
  else: raise newException(LexError, "Unknown Dash character '" & lexer.ch() & "'")

proc plus *(lexer :var Lexer) =
  case lexer.ch()
  of '+': lexer.add_single(LexemeId.plus)
  else: raise newException(LexError, "Unknown Plus character '" & lexer.ch() & "'")

proc less *(lexer :var Lexer) =
  case lexer.ch()
  of '<': lexer.add_single(LexemeId.less)
  else: raise newException(LexError, "Unknown Less character '" & lexer.ch() & "'")

proc more *(lexer :var Lexer) =
  case lexer.ch()
  of '>': lexer.add_single(LexemeId.more)
  else: raise newException(LexError, "Unknown More character '" & lexer.ch() & "'")

proc tilde *(lexer :var Lexer) =
  case lexer.ch()
  of '~': lexer.add_single(LexemeId.tilde)
  else: raise newException(LexError, "Unknown Tilde character '" & lexer.ch() & "'")

proc excl *(lexer :var Lexer) =
  case lexer.ch()
  of '!': lexer.add_single(LexemeId.excl)
  else: raise newException(LexError, "Unknown Exclamation character '" & lexer.ch() & "'")

proc ampersand *(lexer :var Lexer) =
  case lexer.ch()
  of '&': lexer.add_single(LexemeId.ampersand)
  else: raise newException(LexError, "Unknown Ampersand character '" & lexer.ch() & "'")

proc percent *(lexer :var Lexer) =
  case lexer.ch()
  of '%': lexer.add_single(LexemeId.percent)
  else: raise newException(LexError, "Unknown Percent character '" & lexer.ch() & "'")

proc pipe *(lexer :var Lexer) =
  case lexer.ch()
  of '|': lexer.add_single(LexemeId.pipe)
  else: raise newException(LexError, "Unknown Pipe character '" & lexer.ch() & "'")

proc caret *(lexer :var Lexer) =
  case lexer.ch()
  of '^': lexer.add_single(LexemeId.caret)
  else: raise newException(LexError, "Unknown Caret character '" & lexer.ch() & "'")

proc question *(lexer :var Lexer) =
  case lexer.ch()
  of '?': lexer.add_single(LexemeId.question)
  else: raise newException(LexError, "Unknown Question character '" & lexer.ch() & "'")
