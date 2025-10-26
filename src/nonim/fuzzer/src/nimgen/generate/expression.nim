#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../random as R
import ../typetools
import ./expression/literal


func random *(
    info : TLineInfo;
    T    : string = R.typename();
  ) :PNode=
  # FIX: Choose other random expressions
  if   T.isFloat()   : return literal.float(T)
  elif T.isChar()    : return literal.char(T)
  elif T.isInteger() : return literal.integer(T)
  elif T == "bool"   : return literal.bool()
  elif T == "string" : return literal.string()
  elif T == "void"   : return literal.Nil()
  else               : return literal.random() # Generate random literal expression

