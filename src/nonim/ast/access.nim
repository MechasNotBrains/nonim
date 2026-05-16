#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/options import isSome, get, Option
# @deps nonim
import astTF


func pragm      *(atf :astTF.astTF; id :astTF.Id) :astTF.Pragma= atf.data.pragmas.get[id]
func link       *(atf :astTF.astTF; id :astTF.Id) :astTF.Link= atf.data.links.get[id]
func typ        *(atf :astTF.astTF; id :astTF.Id) :astTF.Type= atf.data.types.get[id]
func binding    *(atf :astTF.astTF; id :astTF.Id) :astTF.Binding= atf.data.bindings.get[id]
func procedure  *(atf :astTF.astTF; id :astTF.Id) :astTF.Procedure= atf.data.procedures.get[id]
func expression *(atf :astTF.astTF; id :astTF.Id) :astTF.Expression= atf.data.expressions.get[id]
func statement  *(atf :astTF.astTF; id :astTF.Id) :astTF.Statement= atf.data.statements.get[id]
func comment    *(atf :astTF.astTF; id :astTF.Id) :astTF.Comment= atf.data.comments.get[id]
func alias      *(atf :astTF.astTF; id :astTF.Id) :astTF.Alias= atf.data.aliases.get[id]

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

func statement_next *(atf :astTF.astTF; id :astTF.Id) :Option[astTF.Id]=
  let S = atf.data.statements.get[id]
  result = case S.kind
    of astTF.sVariable:    S.variable.next
    of astTF.sType:        S.`type`.next
    of astTF.sAlias:       S.alias.next
    of astTF.sProcedure:   S.procedure.next
    of astTF.sComment:     S.comment.next
    of astTF.sImport:      S.`import`.next
    of astTF.sPassthrough: S.passthrough.next
    of astTF.sPragma:      S.pragma.next
    of astTF.sExpression:  S.expression.next
    of astTF.sKeyword:     S.keyword.next
    of astTF.sBranch:      S.branch.next

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

