#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Lexer: State/Data Management.
#_______________________________________________________________|
import ./source
import ./lexeme


type Lexer * = object
  pos * :Position
  src * :Code
  result * :seq[Lexeme]

func create *(source :Code) :Lexer= Lexer(pos: 0, src: source, result: @[])

func ch *(lexer :Lexer) :char= lexer.src[lexer.pos]

func add_to_last *(lexer :var Lexer; character :char) =
  assert lexer.result.len > 0, "Tried to extend last lexeme but result is empty."
  lexer.result[^1].loc.`end` += 1
  assert lexer.src[lexer.result[^1].loc.`end`] == character, "Tried to append a character to the last Lexeme, but the characters do not match."

func add_one *(lexer :var Lexer; id :LexemeId; start :Position; finish :Position) =
  lexer.result.add(lexeme.create(id, start, finish))

func add_single *(lexer :var Lexer; id :LexemeId) =
  lexer.add_one(id, lexer.pos, lexer.pos)
