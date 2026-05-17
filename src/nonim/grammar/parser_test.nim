#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/grammar/parser.nim
#__________________________________________|
import minitest
import ../lexer/data as lexer_data
import ../lexer
import ./token
import ./tokenizer
import ./types
import ./parser


const cases_dir = "./tests/cases/"
template case_input (name :static string) :string= staticRead(cases_dir & name)

proc tokenize (source :string) :Parser=
  var lex = lexer_data.create(source)
  lex.process()
  var tok = Tokenizer.create(lex)
  tok.process()
  result = Parser.create(tok.result, source)


describe "nonim.grammar.parser | Simple rule":
  it "must parse a grammar rule name", proc()=
    const Input = case_input("full_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules.len.eq 1
    state.result.rules[0].name.eq "hello"

  it "must parse a grammar rule category", proc()=
    const Input = case_input("full_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules[0].category.eq "keyword"

  it "must parse a grammar rule pattern", proc()=
    const Input = case_input("full_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules[0].pattern.len.eq 1
    state.result.rules[0].pattern[0].kind.eq ekValue
    state.result.rules[0].pattern[0].value.eq "hello"

  it "must parse a grammar rule node type", proc()=
    const Input = case_input("full_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules[0].node_type.eq "Literal"

  it "must parse a grammar rule constructor", proc()=
    const Input = case_input("full_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    assert state.result.rules[0].constructor.len > 0


describe "nonim.grammar.parser | Char pattern":
  it "must parse a single char pattern", proc()=
    const Input = case_input("char_rule.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules.len.eq 1
    state.result.rules[0].name.eq "one"
    state.result.rules[0].pattern[0].value.eq "1"

describe "nonim.grammar.parser | Multiple rules":
  it "must parse multiple grammar rules", proc()=
    const Input = case_input("simple.tpeg")
    var state = tokenize(Input)
    state.process()
    state.result.rules.len.eq 2
    state.result.rules[0].name.eq "hello"
    state.result.rules[1].name.eq "one"
