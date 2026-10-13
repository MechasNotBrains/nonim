#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/strutils import toLowerAscii
# @deps tests
import minitest
# @deps nonim
import ./convert


describe "nonim.ast.convert | Language Parsing":
  it "must parse every language from its lowercase name", proc() =
    for language in Language: Language.parse(($language).toLowerAscii()).eq language

  it "must parse every language from its enum name", proc() =
    for language in Language: Language.parse($language).eq language

  it "must return the fallback for an unknown language name", proc() =
    Language.parse("unknown", Language.C).eq Language.C
