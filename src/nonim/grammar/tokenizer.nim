#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Grammar Tokenizer: converts Lexemes into grammar-specific Tokens.
#_______________________________________________________________|
import ../lexer/source
import ../lexer/lexeme
import ../lexer/data as lexer_data
import ./token


type TokenizerError * = object of CatchableError

type Tokenizer * = object
  pos    * :uint64
  buffer * :seq[Lexeme]
  src    * :Code
  result * :seq[Token]

func create *(_: typedesc[Tokenizer]; lexer :lexer_data.Lexer) :Tokenizer=
  Tokenizer(pos: 0, buffer: lexer.result, src: lexer.src, result: @[])

func lx *(tokenizer :Tokenizer) :Lexeme= tokenizer.buffer[tokenizer.pos]

func add *(tokenizer :var Tokenizer; id :TokenId; location :Location) =
  tokenizer.result.add(token.create(id, location))


proc identifier *(tokenizer :var Tokenizer) =
  let text = tokenizer.lx().`from`(tokenizer.src)
  if text == "grammar":
    tokenizer.add(TokenId.kw_grammar, tokenizer.lx().loc)
  else:
    tokenizer.add(TokenId.identifier, tokenizer.lx().loc)

proc number *(tokenizer :var Tokenizer) =
  tokenizer.add(TokenId.number, tokenizer.lx().loc)

proc symbol *(tokenizer :var Tokenizer) =
  case tokenizer.lx().id
  of LexemeId.eq:        tokenizer.add(TokenId.sp_assignment, tokenizer.lx().loc)
  of LexemeId.dollar:    tokenizer.add(TokenId.sp_argument, tokenizer.lx().loc)
  of LexemeId.dot:       tokenizer.add(TokenId.sp_dot, tokenizer.lx().loc)
  of LexemeId.comma:     tokenizer.add(TokenId.sp_comma, tokenizer.lx().loc)
  of LexemeId.colon:     tokenizer.add(TokenId.sp_colon, tokenizer.lx().loc)
  of LexemeId.semicolon: tokenizer.add(TokenId.sp_semicolon, tokenizer.lx().loc)
  of LexemeId.quote_D:   tokenizer.add(TokenId.sp_string, tokenizer.lx().loc)
  of LexemeId.quote_S:   tokenizer.add(TokenId.sp_char, tokenizer.lx().loc)
  of LexemeId.bracket_L: tokenizer.add(TokenId.sp_bracket_L, tokenizer.lx().loc)
  of LexemeId.bracket_R: tokenizer.add(TokenId.sp_bracket_R, tokenizer.lx().loc)
  of LexemeId.brace_L:   tokenizer.add(TokenId.sp_brace_L, tokenizer.lx().loc)
  of LexemeId.brace_R:   tokenizer.add(TokenId.sp_brace_R, tokenizer.lx().loc)
  of LexemeId.paren_L:   tokenizer.add(TokenId.sp_paren_L, tokenizer.lx().loc)
  of LexemeId.paren_R:   tokenizer.add(TokenId.sp_paren_R, tokenizer.lx().loc)
  of LexemeId.hash:      tokenizer.add(TokenId.sp_hash, tokenizer.lx().loc)
  of LexemeId.EOF:       tokenizer.add(TokenId.sp_EOF, tokenizer.lx().loc)
  else: raise newException(TokenizerError, "Unmapped symbol lexeme '" & $tokenizer.lx().id & "'")

proc process *(tokenizer :var Tokenizer) =
  while tokenizer.pos < uint64(tokenizer.buffer.len):
    let lexeme = tokenizer.lx()
    case lexeme.id
    of LexemeId.space, LexemeId.newline, LexemeId.tab: discard
    of LexemeId.ident: tokenizer.identifier()
    of LexemeId.number: tokenizer.number()
    of LexemeId.colon, LexemeId.semicolon,
       LexemeId.dot, LexemeId.comma, LexemeId.dollar,
       LexemeId.quote_S, LexemeId.quote_D,
       LexemeId.bracket_L, LexemeId.bracket_R,
       LexemeId.brace_L, LexemeId.brace_R,
       LexemeId.paren_L, LexemeId.paren_R,
       LexemeId.eq, LexemeId.hash, LexemeId.EOF: tokenizer.symbol()
    else: raise newException(TokenizerError, "Unknown first lexeme '" & $lexeme.id & "'")
    tokenizer.pos += 1
