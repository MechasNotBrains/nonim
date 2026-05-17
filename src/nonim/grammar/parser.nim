#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Grammar Parser: converts Tokens into a Grammar data structure.
#_______________________________________________________________|
import ../lexer/source
import ./token
import ./types


type ParserError * = object of CatchableError

type Parser * = object
  pos    * :uint64
  tokens * :seq[Token]
  src    * :Code
  result * :Grammar

func create *(_: typedesc[Parser]; tokens :seq[Token]; source :Code) :Parser=
  Parser(pos: 0, tokens: tokens, src: source, result: Grammar(rules: @[]))

func current *(parser :Parser) :Token= parser.tokens[parser.pos]
func at_end *(parser :Parser) :bool= parser.pos >= uint64(parser.tokens.len)

proc advance *(parser :var Parser) =
  parser.pos += 1

proc expect *(parser :var Parser; id :TokenId) =
  if parser.current().id != id:
    raise newException(ParserError, "Expected " & $id & " but found " & $parser.current().id)
  parser.advance()

proc consume_text *(parser :var Parser) :string=
  result = parser.current().loc.`from`(parser.src)
  parser.advance()

proc parse_category *(parser :var Parser) :string=
  parser.expect(TokenId.sp_bracket_L)
  result = parser.consume_text()
  parser.expect(TokenId.sp_bracket_R)

proc parse_pattern *(parser :var Parser) :Pattern=
  parser.expect(TokenId.sp_paren_L)
  while not parser.at_end() and parser.current().id != TokenId.sp_paren_R:
    let token = parser.current()
    case token.id
    of TokenId.sp_string:
      parser.advance()
      let text = parser.consume_text()
      parser.expect(TokenId.sp_string)
      result.add(Element(kind: ekValue, value: text))
    of TokenId.sp_char:
      parser.advance()
      let text = parser.current().loc.`from`(parser.src)
      parser.advance()
      parser.expect(TokenId.sp_char)
      result.add(Element(kind: ekValue, value: text))
    of TokenId.identifier:
      let text = parser.consume_text()
      result.add(Element(kind: ekRule, value: text))
    else:
      parser.advance()
  parser.expect(TokenId.sp_paren_R)

proc parse_node_type *(parser :var Parser) :string=
  parser.expect(TokenId.sp_colon)
  result = parser.consume_text()

proc parse_constructor *(parser :var Parser) :string=
  parser.expect(TokenId.sp_assignment)
  parser.expect(TokenId.sp_dot)
  parser.expect(TokenId.sp_paren_L)
  var depth = 1
  while not parser.at_end() and depth > 0:
    if parser.current().id == TokenId.sp_paren_L: depth += 1
    elif parser.current().id == TokenId.sp_paren_R: depth -= 1
    if depth > 0:
      result.add(parser.current().loc.`from`(parser.src))
      result.add(" ")
      parser.advance()
  if not parser.at_end():
    parser.advance()

proc parse_rule *(parser :var Parser) =
  parser.expect(TokenId.kw_grammar)
  var rule = Rule()
  rule.name = parser.consume_text()
  rule.category = parser.parse_category()
  rule.pattern = parser.parse_pattern()
  rule.node_type = parser.parse_node_type()
  rule.constructor = parser.parse_constructor()
  parser.result.rules.add(rule)

proc process *(parser :var Parser) =
  while not parser.at_end():
    case parser.current().id
    of TokenId.kw_grammar: parser.parse_rule()
    of TokenId.sp_hash, TokenId.sp_hash_double: parser.advance()
    else: parser.advance()
