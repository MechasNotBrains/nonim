#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/options import some, isNone, get
# @deps nonim
import astTF

#_______________________________________
# @section Data Management: Helpers
#_____________________________
func add_procedure *(
    atf : var astTF.astTF;
    P   : astTF.Procedure;
  ) :astTF.Id {.discardable.}=
  if atf.data.procedures.isNone: atf.data.procedures = some(astTF.DataList[astTF.Procedure](@[]))
  atf.data.procedures.get.add P
  return astTF.Id(atf.data.procedures.get.len-1)
#__________________
func add_type *(
    atf : var astTF.astTF;
    T   : astTF.Type;
  ) :astTF.Id {.discardable.}=
  if atf.data.types.isNone: atf.data.types = some(astTF.DataList[astTF.Type](@[]))
  atf.data.types.get.add T
  return astTF.Id(atf.data.types.get.len-1)
#__________________
func add_binding *(
    atf : var astTF.astTF;
    B   : astTF.Binding;
  ) :astTF.Id {.discardable.}=
  if atf.data.bindings.isNone: atf.data.bindings = some(astTF.DataList[astTF.Binding](@[]))
  atf.data.bindings.get.add B
  return astTF.Id(atf.data.bindings.get.len-1)
#__________________
func add_pragma *(
    atf : var astTF.astTF;
    P   : astTF.Pragma;
  ) :astTF.Id {.discardable.}=
  if atf.data.pragmas.isNone: atf.data.pragmas = some(astTF.DataList[astTF.Pragma](@[]))
  atf.data.pragmas.get.add P
  return astTF.Id(atf.data.pragmas.get.len-1)
#__________________
func add_expression *(
    atf : var astTF.astTF;
    E   : astTF.Expression;
  ) :astTF.Id {.discardable.}=
  if atf.data.expressions.isNone: atf.data.expressions = some(astTF.DataList[astTF.Expression](@[]))
  atf.data.expressions.get.add E
  return astTF.Id(atf.data.expressions.get.len-1)
#__________________
func add_expression_type *(
    atf    : var astTF.astTF;
    typeId : astTF.Id;
  ) :astTF.Id {.discardable.}=
  if atf.data.expressions.isNone: atf.data.expressions = some(astTF.DataList[astTF.Expression](@[]))
  atf.data.expressions.get.add astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: typeId))
  return astTF.Id(atf.data.expressions.get.len-1)
#__________________
func add_statement *(
    atf : var astTF.astTF;
    S   : astTF.Statement;
  ) :astTF.Id {.discardable.}=
  if atf.data.statements.isNone: atf.data.statements = some(astTF.DataList[astTF.Statement](@[]))
  atf.data.statements.get.add S
  return astTF.Id(atf.data.statements.get.len-1)
#__________________
func add_comment *(
    atf : var astTF.astTF;
    C   : astTF.Comment;
  ) :astTF.Id {.discardable.}=
  if atf.data.comments.isNone: atf.data.comments = some(astTF.DataList[astTF.Comment](@[]))
  atf.data.comments.get.add C
  return astTF.Id(atf.data.comments.get.len-1)
#__________________
func add_alias *(
    atf : var astTF.astTF;
    A   : astTF.Alias;
  ) :astTF.Id {.discardable.}=
  if atf.data.aliases.isNone: atf.data.aliases = some(astTF.DataList[astTF.Alias](@[]))
  atf.data.aliases.get.add A
  return astTF.Id(atf.data.aliases.get.len-1)
#__________________
func add_depth *(
    atf : var astTF.astTF;
    D   : astTF.Depth;
  ) :astTF.Id {.discardable.}=
  if atf.data.depths.isNone: atf.data.depths = some(astTF.DataList[astTF.Depth](@[]))
  atf.data.depths.get.add D
  return astTF.Id(atf.data.depths.get.len-1)
#__________________
func add_module *(
    atf : var astTF.astTF;
    M   : astTF.Module;
  ) :astTF.Id {.discardable.}=
  atf.data.modules.add M
  return astTF.Id(atf.data.modules.len-1)
#__________________
func add_link *(
    atf : var astTF.astTF;
    L   : astTF.Link;
  ) :astTF.Id {.discardable.}=
  if atf.data.links.isNone: atf.data.links = some(astTF.DataList[astTF.Link](@[]))
  atf.data.links.get.add L
  return astTF.Id(atf.data.links.get.len-1)

