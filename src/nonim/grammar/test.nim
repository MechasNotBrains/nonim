#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Integration tests for the grammar processor.
#_______________________________________________________________|
import minitest
import ../grammar
import ./types


const cases_dir = "./tests/cases/"
template case_input (name :static string) :string= staticRead(cases_dir & name)


describe "nonim.grammar | Integration":
  it "must parse a complete grammar with multiple rules", proc()=
    const Input = case_input("simple.tpeg")
    let result = parse(Input)
    result.rules.len.eq 2
    result.rules[0].name.eq "hello"
    result.rules[0].category.eq "keyword"
    result.rules[0].pattern[0].kind.eq ekValue
    result.rules[0].pattern[0].value.eq "hello"
    result.rules[0].node_type.eq "Literal"
    result.rules[1].name.eq "one"
    result.rules[1].category.eq "somechar"
    result.rules[1].pattern[0].value.eq "1"

  it "must parse a grammar rule with string pattern", proc()=
    const Input = case_input("commented.tpeg")
    let result = parse(Input)
    result.rules.len.eq 1
    result.rules[0].name.eq "some_commented"
    result.rules[0].category.eq "commented"
    result.rules[0].pattern[0].value.eq "cmmnt"
    result.rules[0].node_type.eq "Literal"
