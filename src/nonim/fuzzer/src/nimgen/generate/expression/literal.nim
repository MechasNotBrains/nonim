#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, idents ]
# @deps std
from std/strutils import PrintableChars, replace, escape
# @deps nim.gen
import ../../random as R
import ../../typetools
import ../shared


#_______________________________________
# @section Expression Generation: Literals
#_____________________________
func integer *(T :string= R.integer_lit()) :PNode=
  ## @descr Generates a random integer literal node of the given type
  let min :BiggestInt= case T
    of "byte"       :   byte.low.BiggestInt
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
    of "byte"       :   byte.high.BiggestInt
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
    of "cuchar"     : cuchar.low.BiggestInt
    of "cschar"     : cschar.low.BiggestInt
    of "cint"       : cint.high.BiggestInt
    of "clong"      : clong.high.BiggestInt
    of "clonglong"  : clonglong.high.BiggestInt
    of "cshort"     : cshort.high.BiggestInt
    of "cuint"      : uint16.high.BiggestInt
    of "csize_t"    : uint16.high.BiggestInt  # Doesn't fit in BiggestInt
    of "culong"     : uint16.high.BiggestInt  # Doesn't fit in BiggestInt
    of "culonglong" : uint16.high.BiggestInt  # Doesn't fit in BiggestInt
    of "cushort"    : cushort.high.BiggestInt
    # Default
    else            : int.high
  # TODO: PNode.flags : nfBase2, nfBase8, nfBase16
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
func char *(T :string= R.char_lit()) :PNode=
  ## @descr Generates a random char literal node of the given type
  result = newNode(T.toNodeKind())
  result.intVal = R.char[system.char]().BiggestInt
#___________________
func string *(
    len  : int     = R.integer(0..255);
    kind : TNodeKind = R.sample({nkStrLit..nkTripleStrLit});
  ) :PNode=
  ## @descr Generates a random string literal node with the given `len`
  ## strVal stores raw content; the renderer handles escaping per kind:
  ##   nkStrLit:       renderer calls addQuoted (escapes special chars)
  ##   nkRStrLit:      renderer doubles `"` only
  ##   nkTripleStrLit: renderer dumps strVal as-is between `"""`
  var value :string= ""
  for _ in 0..<len: value.add(R.sample(PrintableChars))
  # Per-kind sanitization
  case kind
  of nkRStrLit:
    # Raw strings cannot contain newlines or invalid lexer tokens
    value = value.replace("\n", "").replace("\r", "").replace("\v", "").replace("\f", "")
  of nkTripleStrLit:
    # Triple strings cannot contain `"""` in content or invalid lexer tokens
    value = value.replace("\"\"\"", "\"\"").replace("\v", "").replace("\f", "")
  else: discard
  result = newStrNode(kind, value)
#___________________
func Nil *() :PNode=
  ## @descr Generates a random nil literal node
  result = newNode(nkNilLit)
#___________________
func bool *() :PNode=
  ## @descr Generates a random bool literal node
  result = newNode(nkIdent)
  {.cast(noSideEffect).}: # Access to gIdentCache is safe
    result.ident = gIdentCache.getIdent(R.sample([$true, $false]))
#___________________
func random *(T :string= R.typename()) :PNode=
  case T
  of Chars_all    : literal.char(T)
  of Floats_all   : literal.float(T)
  of Integers_all : literal.integer(T)
  of Strings_all  : literal.string()
  of "pointer"    : literal.Nil()
  of "bool"       : literal.bool()
  of "void"       : newNode(nkEmpty)
  else            : newNode(nkEmpty)

