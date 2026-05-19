#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/options import some, isSome, get, Option
# @deps nonim
import astTF

#_______________________________________
# @section Forward Exports
#_____________________________
export some, isSome, get, Option
#___________________
type Ast * = astTF.astTF
export astTF.Module
export astTF.Id
export astTF.Identifier
export astTF.Location
export astTF.Format
export astTF.Pragma
export astTF.LiteralKind
export astTF.ExpressionLiteral
export astTF.ExpressionIdentifier
export astTF.ExpressionKind
export astTF.ExpressionType
export astTF.ExpressionKeyword
export astTF.ExpressionObject
export astTF.Expression
export astTF.Binding
export astTF.Procedure
export astTF.TypeKind
export astTF.TypePrimitive
export astTF.TypeAlias
export astTF.TypeEnum
export astTF.TypeObject
export astTF.Type
export astTF.Procedure
export astTF.StatementPragma
export astTF.StatementVariable
export astTF.StatementProcedure
export astTF.StatementType
export astTF.StatementImport
export astTF.StatementPassthrough
export astTF.StatementComment
export astTF.StatementAlias
export astTF.StatementBranch
export astTF.StatementExpression
export astTF.StatementKind
export astTF.Statement
export astTF.Comment
export astTF.Alias
export astTF.ExpressionAffix
export astTF.ExpressionCall
export astTF.ExpressionConditional
export astTF.ExpressionGroup
export astTF.ExpressionIndexed
export astTF.ExpressionLoop
export astTF.TypePtr
export astTF.TypeArray
export astTF.TypeProcedure
export astTF.Link
export astTF.Depth
export astTF.AstData

