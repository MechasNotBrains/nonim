#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, idents ]

# Statement Kinds
const Statements_toplevel * = {
  # Declarations
  nkVarSection, nkLetSection, nkConstSection,
  nkProcDef, nkFuncDef, nkMethodDef, nkConverterDef,
  nkMacroDef, nkTemplateDef, nkIteratorDef,
  nkTypeSection,
  # Expressions
  nkCall, nkCommand,
  nkAsgn,
  # Control flow
  nkIfStmt, nkWhenStmt, nkCaseStmt,
  nkForStmt, nkWhileStmt,
  nkBlockStmt,
  nkTryStmt, nkRaiseStmt,
  nkDiscardStmt,
  # Modules
  nkImportStmt, nkImportExceptStmt, nkFromStmt, nkIncludeStmt,
  nkExportStmt, nkExportExceptStmt,
  # Other
  nkCommentStmt,
  nkPragma,
  nkUsingStmt, nkBindStmt, nkMixinStmt,
}
const Statements_body * = Statements_toplevel - {
  nkImportStmt, nkImportExceptStmt, nkFromStmt, nkIncludeStmt,
  nkExportStmt, nkExportExceptStmt,
} + {
  nkReturnStmt,
  nkBreakStmt, nkContinueStmt,
  nkYieldStmt,
  nkDefer,
  nkAsmStmt,
}

# Character Sets
const VisibleChars * = {' '..'~'}

# Shared resources for the generator
var gIdentCache *{.threadvar.}: IdentCache
gIdentCache = newIdentCache()

# Define the list of type names for Nim
const basicTypes * = [
  # Integers
  "int", "int8", "int16", "int32", "int64",
  "uint", "uint8", "uint16", "uint32", "uint64",
  # Floats
  "float", "float32", "float64",
  # Other primitives
  "bool", "char", "string", "cstring", "pointer", "void",
  # C-compatible types
  "cint", "cuint", "clong", "culong", "clonglong", "culonglong",
  "cchar", "cschar", "cshort", "cushort",
  "cfloat", "cdouble", "clongdouble",
  # Additional basic types
  "byte", "Natural", "Positive"
]

# Complex types that need type parameters - not used yet
const complexTypes * = [
  "seq", "array", "openArray",
  "tuple", "set", "ref", "ptr"
]

# Type Suffixes
const floatSuffixes * = [
  "f32", "F32", "f", "F",
  "f64", "F64", "d", "D"
]

