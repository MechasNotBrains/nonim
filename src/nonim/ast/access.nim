#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/options import isSome, get, Option, some
# @deps nonim
import astTF


func module     *(atf :astTF.astTF; id :astTF.Id) :astTF.Module= atf.data.modules[id]
func pragm      *(atf :astTF.astTF; id :astTF.Id) :astTF.Pragma= atf.data.pragmas.get[id]
func link       *(atf :astTF.astTF; id :astTF.Id) :astTF.Link= atf.data.links.get[id]
func typ        *(atf :astTF.astTF; id :astTF.Id) :astTF.Type= atf.data.types.get[id]
func binding    *(atf :astTF.astTF; id :astTF.Id) :astTF.Binding= atf.data.bindings.get[id]
func procedure  *(atf :astTF.astTF; id :astTF.Id) :astTF.Procedure= atf.data.procedures.get[id]
func expression *(atf :astTF.astTF; id :astTF.Id) :astTF.Expression= atf.data.expressions.get[id]
func statement  *(atf :astTF.astTF; id :astTF.Id) :astTF.Statement= atf.data.statements.get[id]
func comment    *(atf :astTF.astTF; id :astTF.Id) :astTF.Comment= atf.data.comments.get[id]
func alias      *(atf :astTF.astTF; id :astTF.Id) :astTF.Alias= atf.data.aliases.get[id]
func depth      *(atf :astTF.astTF; id :astTF.Id) :astTF.Depth= atf.data.depths.get[id]
func format     *(atf :astTF.astTF; id :astTF.Id) :astTF.Format= atf.data.formats.get[id]

func expression_next *(atf :astTF.astTF; id :astTF.Id) :Option[astTF.Id]=
  let E = atf.data.expressions.get[id]
  result = case E.kind
    of astTF.eIdentifier:  E.identifier.next
    of astTF.eLiteral:     E.literal.next
    of astTF.eAffix:       E.affix.next
    of astTF.eCall:        E.call.next
    of astTF.eGroup:       E.group.next
    of astTF.eIndexed:     E.indexed.next
    of astTF.eBlock:       E.block.next
    of astTF.eArray:       E.array.next
    of astTF.eObject:      E.`object`.next
    of astTF.eRange:       E.`range`.next
    of astTF.eConditional: E.conditional.next
    of astTF.eLoop:        E.loop.next
    of astTF.eType:        E.`type`.next
    of astTF.eKeyword:     E.keyword.next
    of astTF.eProcedure:   E.procedure.next

proc expression_next_set *(atf :var astTF.astTF; id :astTF.Id; next :Option[astTF.Id]) =
  var E = atf.data.expressions.get[id]
  case E.kind
  of astTF.eIdentifier  : E.identifier.next  = next
  of astTF.eLiteral     : E.literal.next     = next
  of astTF.eAffix       : E.affix.next       = next
  of astTF.eCall        : E.call.next        = next
  of astTF.eGroup       : E.group.next       = next
  of astTF.eIndexed     : E.indexed.next     = next
  of astTF.eBlock       : E.block.next       = next
  of astTF.eArray       : E.array.next       = next
  of astTF.eObject      : E.`object`.next    = next
  of astTF.eRange       : E.`range`.next     = next
  of astTF.eConditional : E.conditional.next = next
  of astTF.eLoop        : E.loop.next        = next
  of astTF.eType        : E.`type`.next      = next
  of astTF.eKeyword     : E.keyword.next     = next
  of astTF.eProcedure   : E.procedure.next   = next
  atf.data.expressions.get[id] = E

func statement_next *(atf :astTF.astTF; id :astTF.Id) :Option[astTF.Id]=
  let S = atf.statement(id)
  result = case S.kind
    of astTF.sVariable    : S.variable.next
    of astTF.sType        : S.`type`.next
    of astTF.sAlias       : S.alias.next
    of astTF.sProcedure   : S.procedure.next
    of astTF.sComment     : S.comment.next
    of astTF.sImport      : S.`import`.next
    of astTF.sPassthrough : S.passthrough.next
    of astTF.sPragma      : S.pragma.next
    of astTF.sExpression  : S.expression.next
    of astTF.sBranch      : S.branch.next


#_______________________________________
# @section Format Fields
#_____________________________
func statement_format *(atf :astTF.astTF; id :astTF.Id) :Option[astTF.Id]=
  let S = atf.statement(id)
  result = case S.kind
    of sExpression  : S.expression.fmt
    of sVariable    : S.variable.fmt
    of sProcedure   : S.procedure.fmt
    of sComment     : S.comment.fmt
    of sImport      : S.`import`.fmt
    of sPassthrough : S.passthrough.fmt
    of sBranch      : S.branch.fmt
    of sPragma      : S.pragma.fmt
    of sAlias       : S.alias.fmt
    of sType        : S.`type`.fmt


#_______________________________________
# @section Source Code
#_____________________________
func source *(
    atf       : astTF.astTF;
    module    : astTF.Id;
    location  : astTF.Location;
    synthetic : bool;
  ) :string=
  result = ""
  if synthetic and atf.data.synthetic.isSome():
    result = atf.data.synthetic.get()[location.start..<location.`end`]
  elif atf.data.modules[module].source.len >= location.`end`.int:
    result = atf.data.modules[module].source[location.start..<location.`end`]
#___________________
func source *(
    atf    : astTF.astTF;
    module : astTF.Id;
    ident  : astTF.Identifier;
  ) :string= atf.source(module, ident.location, ident.synthetic.get(false))


#_______________________________________
# @section Visibility Markers
#_____________________________
func type_private *(
    ast : astTF.astTF;
    id  : astTF.Id;
  ) :bool=
  let T = ast.typ(id)
  result = case T.kind
    of tObject      : T.`object`.private.get(false)
    of tEnumeration : T.enumeration.private.get(false)
    of tAlias       : T.alias.private.get(false)
    # TODO: The spec makes no sense for private/public marking of type declarations
    of tPrimitive   : false
    of tArray       : false
    of tPtr         : false
    of tProcedure   : false
    of tRange       : false
#___________________
func statement_private *(
    ast : astTF.astTF;
    id  : astTF.Id;
  ) :bool=
  let S = ast.statement(id)
  result = case S.kind
    of astTF.sType      : ast.type_private(S.`type`.id)
    of astTF.sVariable  : ast.binding(S.variable.id).private.get(false)
    of astTF.sProcedure : ast.binding(S.procedure.id).private.get(false)
    # TODO: Read from Pragmas
    of astTF.sImport    : false
    # TODO: The spec makes no sense for private/public marking of statements
    of astTF.sAlias,
       astTF.sPragma,
       astTF.sBranch,
       astTF.sPassthrough,
       astTF.sExpression,
       astTF.sComment   : true


#_______________________________________
# @section Identifiers
#_____________________________
func type_name *(
    ast : astTF.astTF;
    id  : astTF.Id;
  ) :Option[astTF.Identifier]=
  let T = ast.typ(id)
  result = case T.kind
    of tObject      : T.`object`.name
    of tEnumeration : T.enumeration.name
    of tAlias       : T.alias.name
    of tPrimitive   : some(T.primitive.name)
    of tArray       : T.array.name
    of tPtr         : T.`ptr`.name
    of tRange       : T.range.name
    of tProcedure   : ast.procedure(T.procedure.id).name

