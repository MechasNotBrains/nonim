#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps compiler
import "$nim"/compiler/ast
#
#_______________________________________
# @section NodeKind Groups
#_____________________________
const Char      * = {nkCharLit}
const Float     * = {nkFloatLit, nkFloat32Lit, nkFloat64Lit, nkFloat128Lit}
const Int       * = {nkIntLit, nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit}
const UInt      * = {nkUIntLit, nkUInt8Lit, nkUInt16Lit, nkUInt32Lit, nkUInt64Lit}
const Str       * = {nkStrLit, nkRStrLit, nkTripleStrLit}
const Nil       * = {nkNilLit}
const Literals  * = Char + Float + Int + UInt + Str
const SomeLit   * = Nil + Literals
const SomeCall  * = {nkCommand, nkCall, nkCallStrLit}
const SomeType  * = {nkPtrTy, nkVarTy, nkObjectTy, nkProcTy, nkIteratorTy, nkDistinctTy, nkConstTy, nkRefTy, nkStaticTy, nkOutTy}
const SomeIdent * = {nkIdent, nkEmpty}  # @note: nkEmpty is considered an ident with no value/name

