#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ./shared
import ./statement/any as statement_any


func random *(info :TLineInfo) :PNode=
  result = statement_any.generate(info, R.sample(Statements_toplevel))

