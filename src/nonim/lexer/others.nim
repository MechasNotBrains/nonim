#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Lexer Process: Identifiers & Literals.
#_______________________________________________________________|
import ./source
import ./lexeme
import ./char
import ./data
import ./whitespace


proc ident *(lexer :var Lexer) =
  let start = lexer.pos
  var finish = lexer.pos
  while true:
    if lexer.pos >= uint64(lexer.src.len):
      finish -= 1
      break
    let character = lexer.ch()
    if is_ident(character):
      finish += 1
      lexer.pos += 1
    elif is_context_change(character):
      finish -= 1
      break
    else:
      raise newException(LexError, "Unknown Identifier character '" & character & "'")
  lexer.add_one(LexemeId.ident, start, finish)
  lexer.pos = finish


proc number *(lexer :var Lexer) =
  let start = lexer.pos
  var finish = lexer.pos
  while true:
    if lexer.pos >= uint64(lexer.src.len):
      finish -= 1
      break
    let character = lexer.ch()
    if is_numeric(character):
      finish += 1
      lexer.pos += 1
    elif is_context_change(character):
      finish -= 1
      break
    else:
      raise newException(LexError, "Unknown Numeric character '" & character & "'")
  lexer.add_one(LexemeId.number, start, finish)
  lexer.pos = finish


proc eof *(lexer :var Lexer) =
  case lexer.ch()
  of '\0': lexer.add_single(LexemeId.EOF)
  else: raise newException(LexError, "Unknown EOF character '" & lexer.ch() & "'")
