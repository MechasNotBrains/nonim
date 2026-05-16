#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps compiler
import "$nim"/compiler/lexer
# @deps std
from std/options import some, isSome, isNone, get
from std/strutils import split, parseBiggestUInt
# @deps nonim
import ./output except Module
import ../ast as astTF

#_______________________________________
# @section Configuration
#_____________________________
const indentation *{.strdefine.}= "  "

type BlockMode *{.pure.}= enum
  always
  groups
  none

const mergeBlocks *{.strdefine.}= "groups"
func defaultBlockMode *() :BlockMode=
  result = case mergeBlocks
    of "always" : BlockMode.always
    of "groups" : BlockMode.groups
    of "none"   : BlockMode.none
    else        : BlockMode.groups

#_______________________________________
# @section Forward Exports
#_____________________________
export output
export astTF


#_______________________________________
# @section Format Helpers
#_____________________________
func format_before *(
    module : astTF.Id;
    fmt    : astTF.Format;
    target : output.Target;
    Out    : var Output;
  ) =
  for _ in 0..<fmt.newlines.get(0): Out.string(module, "\n", target)
  for _ in 0..<fmt.indent.get(0):   Out.string(module, indentation, target)
  for _ in 0..<fmt.before.get(0):   Out.string(module, " ", target)
func format_after *(
    module : astTF.Id;
    fmt    : astTF.Format;
    target : output.Target;
    Out    : var Output;
  ) =
  for _ in 0..<fmt.after.get(0): Out.string(module, " ", target)
func format_comment *(
    module : astTF.Id;
    fmt    : astTF.Format;
    target : output.Target;
    Out    : var Output;
  ) =
  for _ in 0..<fmt.comment.get(0): Out.string(module, " ", target)


#_______________________________________
# @section Keywords
#_____________________________
func keyword *(val :string) :bool=
  for token in tkAddr..tkYield:
    if $token == val: return true
  return false
#___________________
func keyword *(
    ident   : astTF.Identifier;
    ast     : astTF.Ast;
    module  : astTF.Id;
  ) :bool= ast.source(module, ident.location, ident.synthetic.get(false)).keyword()


#_______________________________________
# @section Identifiers
#_____________________________
func identifier *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    ident   : astTF.Identifier;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let keyw = ident.keyword(ast, module)
  if keyw: Out.string(module, "`", target)
  Out.string(module, ast.source(module, ident.location, ident.synthetic.get(false)), target)
  if keyw: Out.string(module, "`", target)


#_______________________________________
# @section Literals
#_____________________________
func literal *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let E = ast.expression(id).literal
  if E.fmt.isSome: format_before(module, ast.data.formats.get[E.fmt.get], target, Out)
  let value = ast.source(module, E.value, false)
  case E.kind
  of LiteralKind.nil:
    Out.string(module, "nil", target)
  of LiteralKind.undefined:
    Out.string(module, "nil", target)
  of LiteralKind.char:
    Out.string(module, "'", target)
    Out.string(module, value, target)
    Out.string(module, "'", target)
  of LiteralKind.integer:
    Out.string(module, value, target)
    if value.len > 0 and value[0] in '0'..'9':
      try:
        let parsed = parseBiggestUInt(value)
        if parsed > high(int32).uint64: Out.string(module, "'u64", target)
      except ValueError: discard
  of LiteralKind.bool:
    if value in ["true", "false", "on", "off"]:
      Out.string(module, value, target)
    else:
      let isTrue = value in ["True", "TRUE", "On", "ON"]
      Out.string(module, if isTrue: "true" else: "false", target)
  of LiteralKind.string:
    let variant = if E.variant.isSome: ast.source(module, E.variant.get.location, E.variant.get.synthetic.get(false)) else: ""
    if variant == "\"\"\"":
      Out.string(module, "\"\"\"", target)
      Out.string(module, value, target)
      Out.string(module, "\"\"\"", target)
    elif variant.len > 0 and variant[0] == 'r':
      Out.string(module, "r\"", target)
      Out.string(module, value, target)
      Out.string(module, "\"", target)
    else:
      Out.string(module, "\"", target)
      Out.string(module, value, target)
      Out.string(module, "\"", target)
  of LiteralKind.float, LiteralKind.generic:
    Out.string(module, value, target)
  if E.fmt.isSome: format_after(module, ast.data.formats.get[E.fmt.get], target, Out)
  if E.fmt.isSome: format_comment(module, ast.data.formats.get[E.fmt.get], target, Out)


#_______________________________________
# @section Expressions
#_____________________________
func expression *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output) :void
func binding *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output) :void
func `type` *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output) :void
func procedure *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output) :void
func type_object_body *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output; base_indent :string) :void
func type_object *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output; isBlock :bool = false) :void
func type_enum *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output; isBlock :bool = false) :void
func type_alias *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; target :output.Target; Out :var Output; isBlock :bool = false) :void
#___________________
func call *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let E = ast.expression(id).call
  ast.expression(module, E.name, target, Out)
  Out.string(module, "(", target)
  if E.arguments.isSome:
    let args = E.arguments.get
    ast.binding(module, args, target, Out)
  Out.string(module, ")", target)
#___________________
func group *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let E = ast.expression(id).group
  Out.string(module, "(", target)
  ast.expression(module, E.inner, target, Out)
  Out.string(module, ")", target)
#___________________
func affix *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let E = ast.expression(id).affix
  if E.left.isSome:
    ast.expression(module, E.left.get, target, Out)
    Out.string(module, " ", target)
  Out.string(module, ast.source(module, E.operator, false), target)
  if E.right.isSome:
    Out.string(module, " ", target)
    ast.expression(module, E.right.get, target, Out)
#___________________
func expression *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let E = ast.expression(id)
  case E.kind
  of astTF.eIdentifier:
    if E.identifier.fmt.isSome: format_before(module, ast.data.formats.get[E.identifier.fmt.get], target, Out)
    ast.identifier(module, E.identifier.name, target, Out)
    if E.identifier.fmt.isSome: format_after(module, ast.data.formats.get[E.identifier.fmt.get], target, Out)
    if E.identifier.fmt.isSome: format_comment(module, ast.data.formats.get[E.identifier.fmt.get], target, Out)
  of astTF.eLiteral    : ast.literal(module, id, target, Out)
  of astTF.eAffix      : ast.affix(module, id, target, Out)
  of astTF.eGroup      : ast.group(module, id, target, Out)
  of astTF.eCall       : ast.call(module, id, target, Out)
  of astTF.eType       : ast.`type`(module, E.`type`.id, target, Out)
  else                 : raise newException(Defect, "unreachable")


#_______________________________________
# @section Pragmas
#_____________________________
func pragma_list *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  var current = some(id)
  while current.isSome:
    let pragma_id = current.get
    let P = ast.pragm(pragma_id)
    ast.expression(module, P.key, target, Out)
    if P.value.isSome:
      Out.string(module, ":", target)
      ast.expression(module, P.value.get, target, Out)
    current = P.next
    if current.isSome:
      Out.string(module, ", ", target)

func pragma *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  Out.string(module, "{.", target)
  ast.pragma_list(module, id, target, Out)
  Out.string(module, ".}", target)

# Order:
# 1. Expression.identifier — just outputs a name, wraps keywords in backticks
# 2. Expression.literal — outputs the literal value text
# 3. Pragma.render — wraps expression output in {. .}
# 4. Binding.render — name + type + value
# 5. Type.primitive — just a name with optional var/Option[]
# 6. Procedure.render — combines all of the above
#_______________________________________
# @section Types
#_____________________________
func type_primitive *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let T = ast.typ(id).primitive
  if T.mutable.get(false):  Out.string(module, "var ", target)
  if T.optional.get(false): Out.string(module, "Option[", target)
  if T.keyword.isSome:
    let keyw = T.keyword.get
    Out.string(module, ast.source(module, keyw.location, keyw.synthetic.get(false)), target)
    Out.string(module, " ", target)
  ast.identifier(module, T.name, target, Out)
  if T.instantiation.isSome:
    Out.string(module, "[", target)
    var current = T.instantiation
    while current.isSome:
      ast.expression(module, current.get, target, Out)
      current = ast.expression_next(current.get)
      if current.isSome: Out.string(module, ", ", target)
    Out.string(module, "]", target)
  if T.optional.get(false): Out.string(module, "]", target)
#___________________
func type_ptr *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let T = ast.typ(id).`ptr`
  if T.mutable.get(false):  Out.string(module, "var ", target)
  if T.optional.get(false): Out.string(module, "Option[", target)
  if T.reference.get(false): Out.string(module, "ref ", target)
  else:           Out.string(module, "ptr ", target)
  let targetIsObject = ast.typ(T.target).kind == astTF.tObject
  if targetIsObject and not T.optional.get(false) and not T.mutable.get(false): # Nim object coloring edge case: `ref object` / `ptr object`
    ast.type_object_body(module, T.target, target, Out, indentation)
  elif targetIsObject:
    let O = ast.typ(T.target).`object`
    if O.name.isSome: ast.identifier(module, O.name.get, target, Out)
  else:
    ast.`type`(module, T.target, target, Out)
  if T.optional.get(false): Out.string(module, "]", target)
#___________________
func type_array *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let T = ast.typ(id).array
  if T.mutable.get(false):  Out.string(module, "var ", target)
  if T.optional.get(false): Out.string(module, "Option[", target)
  if T.name.isSome:
    ast.identifier(module, T.name.get, target, Out)
    Out.string(module, "[", target)
    ast.`type`(module, T.element, target, Out)
    Out.string(module, "]", target)
  elif T.length.isSome:
    Out.string(module, "array[", target)
    let length = T.length.get
    ast.expression(module, length, target, Out)
    Out.string(module, ", ", target)
    ast.`type`(module, T.element, target, Out)
    Out.string(module, "]", target)
  else:
    ast.`type`(module, T.element, target, Out)
  if T.optional.get(false): Out.string(module, "]", target)
#___________________
func type_procedure *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let T = ast.typ(id).procedure
  if T.mutable.get(false):  Out.string(module, "var ", target)
  if T.optional.get(false): Out.string(module, "Option[", target)
  ast.procedure(module, T.id, target, Out)
  if T.optional.get(false): Out.string(module, "]", target)
#___________________
func `type` *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let T = ast.typ(id)
  case T.kind
  of astTF.tPrimitive   : ast.type_primitive(module, id, target, Out)
  of astTF.tPtr         : ast.type_ptr(module, id, target, Out)
  of astTF.tArray       : ast.type_array(module, id, target, Out)
  of astTF.tProcedure   : ast.type_procedure(module, id, target, Out)
  of astTF.tObject      : ast.type_object(module, id, target, Out)
  of astTF.tEnumeration : ast.type_enum(module, id, target, Out)
  of astTF.tAlias       : ast.type_alias(module, id, target, Out)
  else                  : raise newException(Defect, "unreachable")


#_______________________________________
# @section Bindings
#_____________________________
func binding_single *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    separator : string;
    target  : output.Target;
    Out     : var Output;
  ) :Option[astTF.Id]=
  let B = ast.binding(id)
  # Generate the name
  if B.name.isSome:
    ast.identifier(module, B.name.get, target, Out)
    if not B.private.get(false): Out.string(module, "*", target)
  # Generate the pragma
  if B.pragmas.isSome:
    Out.string(module, " ", target)
    ast.pragma(module, B.pragmas.get, target, Out)
  # Generate the type, or skip to next
  if B.dataType.isSome:
    Out.string(module, " :", target)
    ast.expression(module, B.dataType.get, target, Out)
  elif B.name.isSome and not B.value.isSome: # if no type, assume its a grouped binding   (a,b :type= value)
    Out.string(module, ", ", target)
    return B.next
  # Generate the value
  if B.value.isSome:
    if B.name.isSome or B.dataType.isSome:
      if B.dataType.isNone: Out.string(module, " ", target) # FIX: Formatting
      Out.string(module, "= ", target)
    ast.expression(module, B.value.get, target, Out)
  # Continue to next
  if B.next.isSome: Out.string(module, separator, target)
  return B.next
#___________________
func binding *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  var current = some(id)
  while current.isSome:
    current = ast.binding_single(module, current.get, "; ", target, Out)


#_______________________________________
# @section Procedures
#_____________________________
func procedure *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let P = ast.procedure(id)
  if P.callable.isSome:
    let callable = P.callable.get
    Out.string(module, ast.source(module, callable.location, callable.synthetic.get(false)), target)
  elif P.impure.get(false): Out.string(module, "proc", target)
  else:          Out.string(module, "func", target)
  Out.string(module, " ", target)
  if P.name.isSome: ast.identifier(module, P.name.get, target, Out)
  if not P.private.get(false): Out.string(module, "*", target)
  if P.generics.isSome:
    Out.string(module, "[", target)
    var generic_current = some(P.generics.get)
    while generic_current.isSome:
      let generic_binding = ast.binding(generic_current.get)
      if generic_binding.name.isSome: ast.identifier(module, generic_binding.name.get, target, Out)
      generic_current = generic_binding.next
      if generic_current.isSome: Out.string(module, ", ", target)
    Out.string(module, "]", target)
  Out.string(module, "(", target)
  if P.arguments.isSome: ast.binding(module, P.arguments.get, target, Out)
  Out.string(module, ")", target)
  if P.returnType.isSome:
    Out.string(module, " :", target)
    ast.expression(module, P.returnType.get, target, Out)
  if P.pragmas.isSome:
    Out.string(module, " ", target)
    ast.pragma(module, P.pragmas.get, target, Out)


#_______________________________________
# @section Block Keyword
#_____________________________
func block_keyword *(
    ast : astTF.Ast;
    id  : astTF.Id;
  ) :string=
  let S = ast.statement(id)
  result = case S.kind
    of astTF.sType: "type"
    of astTF.sVariable:
      let B = ast.binding(S.variable.id)
      if B.mutable.get(false):   "var"
      elif B.runtime.get(false): "let"
      else:           "const"
    else: ""


#_______________________________________
# @section Statements
#_____________________________
func variable *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  let V = ast.statement(id).variable
  let B = ast.binding(V.id)
  if isBlock:
    Out.string(module, indentation, target)
  else:
    Out.string(module,
      if B.mutable.get(false):   "var "
      elif B.runtime.get(false): "let "
      else:           "const ",
      target)
  ast.binding(module, V.id, target, Out)
#___________________
func type_alias *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  if isBlock: Out.string(module, indentation, target)
  let A = ast.typ(id).alias
  if A.name.isSome: ast.identifier(module, A.name.get, target, Out)
  else:             Out.string(module, "UNNAMED_TYPE_ALIAS", target)
  if not A.private.get(false): Out.string(module, "*", target)
  Out.string(module, " = ", target)
  ast.expression(module, A.target, target, Out)
#___________________
func type_enum *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  let base_indent = if isBlock: indentation & indentation else: indentation
  if isBlock: Out.string(module, indentation, target)
  let E = ast.typ(id).enumeration
  if E.name.isSome: ast.identifier(module, E.name.get, target, Out)
  else:             Out.string(module, "_", target)
  if not E.private.get(false): Out.string(module, "*", target)
  if E.pragmas.isSome:
    let pragma = E.pragmas.get
    Out.string(module, " ", target)
    ast.pragma(module, pragma, target, Out)
  Out.string(module, " = ", target)
  Out.string(module, "enum", target)
  var current = E.values
  while current.isSome:
    Out.string(module, "\n", target)
    Out.string(module, base_indent, target)
    let V = ast.binding(current.get)
    if V.name.isSome: ast.identifier(module, V.name.get, target, Out)
    else:             Out.string(module, "_", target)
    if V.value.isSome:
      Out.string(module, " = ", target)
      ast.expression(module, V.value.get, target, Out)
    if V.next.isSome: Out.string(module, ",", target)
    current = V.next
#___________________
func type_object_body *(
    ast         : astTF.Ast;
    module      : astTF.Id;
    id          : astTF.Id;
    target      : output.Target;
    Out         : var Output;
    base_indent : string;
  ) :void=
  let O = ast.typ(id).`object`
  Out.string(module, "object", target)
  if O.link.isSome:
    let link_range = O.link.get
    let first_link = ast.link(astTF.Id(link_range.start))
    Out.string(module, " of ", target)
    ast.`type`(module, first_link.`type`, target, Out)
  var current = O.fields
  while current.isSome:
    Out.string(module, "\n", target)
    Out.string(module, base_indent, target)
    current = ast.binding_single(module, current.get, "", target, Out)
#___________________
func type_object *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  let base_indent = if isBlock: indentation & indentation else: indentation
  if isBlock: Out.string(module, indentation, target)
  let O = ast.typ(id).`object`
  if O.keyword.isSome and O.name.isNone:
    let keyw = ast.source(module, O.keyword.get.location, O.keyword.get.synthetic.get(false))
    if keyw == "tuple" and O.fields.isSome:
      var hasNames = false
      var check = some(O.fields.get)
      while check.isSome:
        if ast.binding(check.get).name.isSome: hasNames = true
        check = ast.binding(check.get).next
      if hasNames:
        Out.string(module, "tuple[", target)
        var current = some(O.fields.get)
        while current.isSome:
          let field = ast.binding(current.get)
          if field.name.isSome: ast.identifier(module, field.name.get, target, Out); Out.string(module, ": ", target)
          if field.dataType.isSome: ast.expression(module, field.dataType.get, target, Out)
          current = field.next
          if current.isSome: Out.string(module, ", ", target)
        Out.string(module, "]", target)
      else:
        Out.string(module, "(", target)
        var current = some(O.fields.get)
        while current.isSome:
          let field = ast.binding(current.get)
          if field.dataType.isSome: ast.expression(module, field.dataType.get, target, Out)
          current = field.next
          if current.isSome: Out.string(module, ", ", target)
        Out.string(module, ")", target)
      return
  if O.name.isSome: ast.identifier(module, O.name.get, target, Out)
  else:             Out.string(module, "UNNAMED_TYPE_ALIAS", target)
  if not O.private.get(false): Out.string(module, "*", target)
  if O.generics.isSome:
    Out.string(module, "[", target)
    var generic_current = some(O.generics.get)
    while generic_current.isSome:
      let generic_binding = ast.binding(generic_current.get)
      if generic_binding.name.isSome: ast.identifier(module, generic_binding.name.get, target, Out)
      generic_current = generic_binding.next
      if generic_current.isSome: Out.string(module, ", ", target)
    Out.string(module, "]", target)
  if O.pragmas.isSome:
    Out.string(module, " ", target)
    Out.string(module, "{.", target)
    if O.keyword.isSome:
      ast.identifier(module, O.keyword.get, target, Out)
      Out.string(module, ", ", target)
    ast.pragma_list(module, O.pragmas.get, target, Out)
    Out.string(module, ".}", target)
  Out.string(module, " = ", target)
  ast.type_object_body(module, id, target, Out, base_indent)
#___________________
func statement_type *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  let T = ast.statement(id).`type`
  if not isBlock: Out.string(module, "type ", target)
  case ast.typ(T.id).kind
  of astTF.tAlias       : ast.type_alias(module, T.id, target, Out, isBlock)
  of astTF.tEnumeration : ast.type_enum(module, T.id, target, Out, isBlock)
  of astTF.tObject      : ast.type_object(module, T.id, target, Out, isBlock)
  else                  : raise newException(Defect, "unreachable")
#___________________
func statement_procedure *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let S = ast.statement(id).procedure
  ast.procedure(module, S.id, target, Out)
#___________________
func statement_passthrough *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let S = ast.statement(id).passthrough
  Out.string(module, ast.source(module, S.location, false), target)
#___________________
func statement_comment *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let S = ast.statement(id).comment
  let C = ast.comment(S.id)
  let kind_text = ast.source(module, C.kind.location, C.kind.synthetic.get(false))
  let prefix = if kind_text == "##" or kind_text == "///" or kind_text == "/**": "## "
               else: "# "
  let text = ast.source(module, C.text, false)
  var first = true
  for line in text.split("\n"):
    if not first: Out.string(module, "\n", target)
    Out.string(module, prefix, target)
    Out.string(module, line, target)
    first = false
#___________________
func statement_alias *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool = false;
  ) :void=
  let S = ast.statement(id).alias
  let A = ast.alias(S.id)
  if not isBlock: Out.string(module, "const ", target)
  else:           Out.string(module, indentation, target)
  ast.identifier(module, A.name, target, Out)
  Out.string(module, "* = ", target)
  if A.target.isSome:
    let t_ident = A.target.get
    ast.identifier(module, t_ident, target, Out)
#___________________
func statement_import *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let S = ast.statement(id).`import`
  if S.keyword.isSome:
    let keyw = S.keyword.get
    Out.string(module, ast.source(module, keyw.location, keyw.synthetic.get(false)), target)
    Out.string(module, " ", target)
  Out.string(module, ast.source(module, S.path, false), target)
  if S.alias.isSome:
    let a = S.alias.get
    Out.string(module, " as ", target)
    Out.string(module, ast.source(module, a.location, a.synthetic.get(false)), target)
  if S.symbols.isSome:
    Out.string(module, " import ", target)
    var current = S.symbols
    while current.isSome:
      let symbol_id = current.get
      let A = ast.alias(symbol_id)
      Out.string(module, ast.source(module, A.name.location, A.name.synthetic.get(false)), target)
      if A.target.isSome:
        let t_ident = A.target.get
        Out.string(module, " as ", target)
        Out.string(module, ast.source(module, t_ident.location, t_ident.synthetic.get(false)), target)
      current = A.next
      if current.isSome: Out.string(module, ", ", target)
#___________________
func statement *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
  ) :void=
  let S = ast.statement(id)
  case S.kind
  of astTF.sPragma      : ast.pragma(module, S.pragma.id, target, Out)
  of astTF.sVariable    : ast.variable(module, id, target, Out, isBlock = false)
  of astTF.sProcedure   : ast.statement_procedure(module, id, target, Out)
  of astTF.sType        : ast.statement_type(module, id, target, Out, isBlock = false)
  of astTF.sPassthrough : ast.statement_passthrough(module, id, target, Out)
  of astTF.sComment     : ast.statement_comment(module, id, target, Out)
  of astTF.sImport      : ast.statement_import(module, id, target, Out)
  of astTF.sAlias       : ast.statement_alias(module, id, target, Out, isBlock = false)
  else                  : raise newException(Defect, "unreachable")
  Out.string(module, "\n", target)


#_______________________________________
# @section Statement List
#_____________________________
func statement_block *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    isBlock : bool;
  ) :void=
  let S = ast.statement(id)
  case S.kind
  of astTF.sVariable    : ast.variable(module, id, target, Out, isBlock)
  of astTF.sType        : ast.statement_type(module, id, target, Out, isBlock)
  of astTF.sAlias       : ast.statement_alias(module, id, target, Out, isBlock)
  of astTF.sPragma      : ast.pragma(module, S.pragma.id, target, Out)
  of astTF.sProcedure   : ast.statement_procedure(module, id, target, Out)
  of astTF.sPassthrough : ast.statement_passthrough(module, id, target, Out)
  of astTF.sComment     : ast.statement_comment(module, id, target, Out)
  of astTF.sImport      : ast.statement_import(module, id, target, Out)
  else                  : raise newException(Defect, "unreachable")
  Out.string(module, "\n", target)
#___________________
func statement_list *(
    ast     : astTF.Ast;
    module  : astTF.Id;
    id      : astTF.Id;
    target  : output.Target;
    Out     : var Output;
    mode    : BlockMode = defaultBlockMode();
  ) :void=
  var current = some(id)
  while current.isSome:
    let current_id = current.get
    let keyword = ast.block_keyword(current_id)
    if mode == BlockMode.none or keyword.len == 0:
      ast.statement(module, current_id, target, Out)
      current = ast.statement_next(current_id)
      continue
    let next_id = ast.statement_next(current_id)
    let has_group = mode == BlockMode.always or
      (next_id.isSome and ast.block_keyword(next_id.get) == keyword)
    if not has_group:
      ast.statement(module, current_id, target, Out)
      current = next_id
      continue
    Out.string(module, keyword, target)
    Out.string(module, "\n", target)
    while current.isSome:
      let inner_id = current.get
      if ast.block_keyword(inner_id) != keyword: break
      ast.statement_block(module, inner_id, target, Out, isBlock = true)
      current = ast.statement_next(inner_id)

#_______________________________________
# @section Render
#_____________________________
func nim *(
    ast    : astTF.Ast;
    target : output.Target = output.Target.definition;
    mode   : BlockMode = defaultBlockMode();
  ) :Output=
  result = Output()
  for idx in 0..<ast.data.modules.len:
    result.modules.add output.Module(path: ast.data.modules[idx].path)
  for idx in 0..<ast.data.modules.len:
    let moduleBody = ast.data.modules[idx].body
    if moduleBody.isSome:
      ast.statement_list(astTF.Id(idx), moduleBody.get, target, result, mode)

