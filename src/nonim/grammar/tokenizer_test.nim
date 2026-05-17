#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Unit Tests for nonim/grammar/tokenizer.nim
#_______________________________________________________________|
import minitest
import ../lexer/data as lexer_data
import ../lexer
import ./token
import ./tokenizer


const cases_dir = "./tests/cases/"
template case_input (name :static string) :string= staticRead(cases_dir & name)


describe "nonim.grammar.tokenizer | Keywords":
  it "must tokenize 'grammar' as kw_grammar", proc()=
    const Input = case_input("single_keyword.tpeg")
    var lexer = lexer_data.create(Input)
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.kw_grammar

  it "must tokenize other identifiers as identifier", proc()=
    const Input = case_input("single_identifier.tpeg")
    var lexer = lexer_data.create(Input)
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.identifier


describe "nonim.grammar.tokenizer | Symbols":
  it "must tokenize = as sp_assignment", proc()=
    var lexer = lexer_data.create("=")
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.sp_assignment

  it "must tokenize $ as sp_argument", proc()=
    var lexer = lexer_data.create("$")
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.sp_argument

  it "must tokenize brackets", proc()=
    var lexer = lexer_data.create("[keyword]")
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.sp_bracket_L
    tok.result[1].id.eq TokenId.identifier
    tok.result[2].id.eq TokenId.sp_bracket_R


describe "nonim.grammar.tokenizer | Whitespace skipping":
  it "must skip spaces between tokens", proc()=
    const Input = case_input("keyword_identifier.tpeg")
    var lexer = lexer_data.create(Input)
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result.len.eq 2
    tok.result[0].id.eq TokenId.kw_grammar
    tok.result[1].id.eq TokenId.identifier


describe "nonim.grammar.tokenizer | Full rule":
  it "must tokenize a complete grammar rule", proc()=
    const Input = case_input("full_rule.tpeg")
    var lexer = lexer_data.create(Input)
    lexer.process()
    var tok = Tokenizer.create(lexer)
    tok.process()
    tok.result[0].id.eq TokenId.kw_grammar
    tok.result[1].id.eq TokenId.identifier
    tok.result[2].id.eq TokenId.sp_bracket_L
    tok.result[3].id.eq TokenId.identifier
    tok.result[4].id.eq TokenId.sp_bracket_R
    tok.result[5].id.eq TokenId.sp_paren_L
    tok.result[6].id.eq TokenId.sp_string
    tok.result[7].id.eq TokenId.identifier
    tok.result[8].id.eq TokenId.sp_string
    tok.result[9].id.eq TokenId.sp_paren_R
    tok.result[10].id.eq TokenId.sp_colon
    tok.result[11].id.eq TokenId.identifier
    tok.result[12].id.eq TokenId.sp_assignment
    tok.result[13].id.eq TokenId.sp_dot
    tok.result[14].id.eq TokenId.sp_paren_L
    tok.result[15].id.eq TokenId.identifier
    tok.result[16].id.eq TokenId.sp_colon
    tok.result[17].id.eq TokenId.sp_argument
    tok.result[18].id.eq TokenId.number
    tok.result[19].id.eq TokenId.sp_paren_R
