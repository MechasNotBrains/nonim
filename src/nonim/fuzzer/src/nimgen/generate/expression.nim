#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ./expression/literal
import ../typetools


func random *(
    info : TLineInfo;
    T    : string = $int;
  ) :PNode=
  # FIX: Choose other random expressions
  if   T.isFloat()   : return literal.float(T)
  elif T.isChar()    : return literal.char(T)
  elif T.isInteger() : return literal.integer(T)
  else               : return literal.random() # Generate random literal expression

