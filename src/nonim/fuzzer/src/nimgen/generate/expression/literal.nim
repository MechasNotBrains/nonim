#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast ]
# @deps nim.gen
import ../../random as R
import ../../typetools


#_______________________________________
# @section Node Generation: Entry Point
#_____________________________
func integer *(T :string= R.integer_lit()) :PNode=
  ## @descr Generates a random integer literal node of the given type
  let min :BiggestInt= case T
    of "uint8"      :  uint8.low.BiggestInt
    of "uint16"     : uint16.low.BiggestInt
    of "uint32"     : uint32.low.BiggestInt
    of "uint64"     : uint32.low.BiggestInt
    of "uint"       : uint32.low.BiggestInt
    of "int8"       :   int8.low.BiggestInt
    of "int16"      :  int16.low.BiggestInt
    of "int32"      :  int32.low.BiggestInt
    of "int64"      :  int64.low.BiggestInt
    # C types
    of "cchar"      : cchar.low.BiggestInt
    of "cschar"     : cschar.low.BiggestInt
    of "cint"       : cint.low.BiggestInt
    of "clong"      : clong.low.BiggestInt
    of "clonglong"  : clonglong.low.BiggestInt
    of "cshort"     : cshort.low.BiggestInt
    of "csize_t"    : csize_t.low.BiggestInt
    of "cuint"      : cuint.low.BiggestInt
    of "culong"     : culong.low.BiggestInt
    of "culonglong" : culonglong.low.BiggestInt
    of "cushort"    : cushort.low.BiggestInt
    # Default
    else            : int.low.BiggestInt
  let max :BiggestInt= case T
    of "uint8"      :  uint8.high.BiggestInt
    of "uint16"     : uint16.high.BiggestInt
    of "uint32"     : uint32.high.BiggestInt
    of "uint64"     : uint32.high.BiggestInt  # Doesn't fit in BiggestInt
    of "uint"       : uint32.high.BiggestInt  # Doesn't fit in BiggestInt
    of "int8"       :   int8.high.BiggestInt
    of "int16"      :  int16.high.BiggestInt
    of "int32"      :  int32.high.BiggestInt
    of "int64"      :  int64.high.BiggestInt
    # C types
    of "cchar"      : cchar.high.BiggestInt
    of "cschar"     : cschar.high.BiggestInt
    of "cint"       : cint.high.BiggestInt
    of "clong"      : clong.high.BiggestInt
    of "clonglong"  : clonglong.high.BiggestInt
    of "cshort"     : cshort.high.BiggestInt
    of "cuint"      : cuint.high.BiggestInt
    of "csize_t"    : uint32.high.BiggestInt  # Doesn't fit in BiggestInt
    of "culong"     : uint32.high.BiggestInt  # Doesn't fit in BiggestInt
    of "culonglong" : uint32.high.BiggestInt  # Doesn't fit in BiggestInt
    of "cushort"    : cushort.high.BiggestInt
    # Default
    else            : int.high
  newIntNode(T.toNodeKind(), R.integer(min..max))
#___________________
func float *(T :string= R.float_lit()) :PNode=
  ## @descr Generates a random float literal node of the given type
  let high :BiggestFloat= case T
    of "float32" : float32.high.BiggestFloat
    of "float64" : float64.high.BiggestFloat
    of "cfloat"  :  cfloat.high.BiggestFloat
    of "cdouble" : cdouble.high.BiggestFloat
    else         : system.float.high.BiggestFloat
  newFloatNode(T.toNodeKind(), R.float(high))
#___________________
func random *() :PNode=
  case R.integer(2)
  of 0: literal.float()
  # of 1: newStrNode(nkStrLit, literal.string(min, max))  # TODO: Proper String nodes with different kinds
  else: literal.integer()

