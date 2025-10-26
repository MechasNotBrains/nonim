#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast ]


#_______________________________________
# @section Characters
#_____________________________
const Chars_all * = ["char", "cchar"]
func isChar *(T :string) :bool= T in Chars_all


#_______________________________________
# @section Integers
#_____________________________
const Integers_signed_nim   * = @[ $int,    $int8,   $int16,      $int32,     $int64            ]
const Integers_unsigned_nim * = @[ $byte,   $uint,   $uint8,      $uint16,    $uint32, $uint64  ]
const Integers_signed_C     * = @[ $cschar, $cint,   $clong,      $clonglong, $cshort, $csize_t ]
const Integers_unsigned_C   * = @[ $cuint,  $culong, $culonglong, $cushort                      ]
const Integers_signed_all   * = Integers_signed_nim   & Integers_signed_C
const Integers_unsigned_all * = Integers_unsigned_nim & Integers_unsigned_C
const Integers_nim          * = Integers_signed_nim   & Integers_unsigned_nim
const Integers_C            * = Integers_signed_C     & Integers_unsigned_C
const Integers_all          * = Integers_signed_nim   & Integers_unsigned_nim & Integers_signed_C & Integers_unsigned_C
#_____________________________
func isInteger_signed   *(T :string) :bool= T in Integers_signed_all
func isInteger_unsigned *(T :string) :bool= T in Integers_unsigned_all
func isInteger_nim      *(T :string) :bool= T in Integers_nim
func isInteger_C        *(T :string) :bool= T in Integers_C
func isInteger          *(T :string) :bool= T in Integers_all


#_______________________________________
# @section Floats
#_____________________________
const Floats_nim * = @[ $float,  $float32, $float64     ]
const Floats_C   * = @[ $cfloat, $cdouble, $clongdouble ]
const Floats_all * = Floats_nim & Floats_C
#_____________________________
func isFloat_nim *(T :string) :bool= T in Floats_nim
func isFloat_C   *(T :string) :bool= T in Floats_C
func isFloat     *(T :string) :bool= T in Floats_all


#_______________________________________
# @section Strings
#_____________________________
const Strings_nim * = @[ $string  ]
const Strings_C   * = @[ $cstring ]
const Strings_all * = Strings_nim & Strings_C
#_____________________________
func isString_nim *(T :string) :bool= T in Strings_nim
func isString_C   *(T :string) :bool= T in Strings_C
func isString     *(T :string) :bool= T in Strings_all


#_______________________________________
# @section Conversion
#_____________________________
func toNodeKind *(T :string) :TNodeKind= result = case T
  # bool
  of "bool"      : nkIdent
  # Chars
  of Chars_all   : nkCharLit
  # Strings
  of Strings_all : nkStrLit
  # Signed Int
  of "int"       : nkIntLit
  of "int8"      : nkInt8Lit
  of "int16"     : nkInt16Lit
  of "int32"     : nkInt32Lit
  of "int64"     : nkInt64Lit
  of "Positive"  : nkIntLit
  of "Natural"   : nkIntLit
  of Integers_signed_C: nkIntLit
  # Unsigned Int
  of "uint"      : nkUIntLit
  of "uint8"     : nkUInt8Lit
  of "uint16"    : nkUInt16Lit
  of "uint32"    : nkUInt32Lit
  of "uint64"    : nkUInt64Lit
  of "byte"      : nkUInt8Lit
  of Integers_unsigned_C: nkIntLit
  # Floats
  of "float"     : nkFloatLit
  of "float32"   : nkFloat32Lit
  of "float64"   : nkFloat64Lit
  of Floats_C    : nkFloatLit
  # Unknown or TODO
  of "void"      : nkNilLit
  else: doAssert false, "unreachable " & $T; nkEmpty

