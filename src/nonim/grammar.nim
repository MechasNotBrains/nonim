#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Grammar: Entry Point.
## Parses grammar definition source into a Grammar object.
#_______________________________________________________________|
import ./lexer/data as lexer_data
import ./lexer
import ./grammar/token
import ./grammar/tokenizer
import ./grammar/types
import ./grammar/parser

export token, tokenizer, types, parser


proc parse *(source :string) :Grammar=
  var lex = lexer_data.create(source)
  lex.process()
  var tok = Tokenizer.create(lex)
  tok.process()
  var state = Parser.create(tok.result, source)
  state.process()
  return state.result
