#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test data type for codegen tests.
#_______________________________________________________________|
# @deps std
from std/options import some, none
# @deps nonim
import ../../ast as astTF
import ../../ast/data
export astTF, data, some, none


type TestData * = object
  ast    *:astTF.Ast
  module *:astTF.Id
  id     *:astTF.Id

proc create *(source :string) :TestData=
  result.ast = astTF.Ast(root: 0, data: astTF.AstData(modules: @[]))
  result.module = astTF.Id(0)
  result.ast.data.modules.add(astTF.Module(path: "test.nim", source: source))
  result.id = 0
