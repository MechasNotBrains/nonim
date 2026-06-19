#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/os import changeFileExt, lastPathPart
from std/options import some, none, isSome, isNone, get, Option
from std/strutils import split
import ../ast as astTF
import ./output
import ./base


#_______________________________________
# @section Error Management
#_____________________________
type ZigCodegenError = object of CatchableError
#___________________
proc fail (
    msg  : static string;
    args : varargs[string, `$`];
  ) :void {.noreturn.}= base.fail(ZigCodegenError, msg, args)


#_______________________________________
# @section Forward declarations
#_____________________________
func location (
    ast    : astTF.Ast;
    module : astTF.Id;
    loc    : astTF.Location;
    Out    : var Output;
  ) :void
#___________________
func Type (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void
#___________________
func expression *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void
#___________________
func expression_list (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void
#___________________
func statement (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    post   : Option[system.string] = none(system.string);
    last   : bool   = false;
  ) :Option[astTF.Id]
#___________________
func statement_list (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    post   : Option[system.string] = none(system.string);
  ) :void



#_______________________________________
# @section Operators
#_____________________________
type OperatorKind = enum Prefix, Affix, Postfix
#___________________
func operator_translate (operator :string) :string=
  result = case operator
    of "div" : "/"
    of "mod" : "%"
    of "shl" : "<<"
    of "shr" : ">>"
    of "xor" : "^"
    else     : operator
#___________________
func operator_spacing (
    ast      : astTF.Ast;
    module   : astTF.Id;
    operator : astTF.Location;
    kind     : OperatorKind;
  ) :tuple[before:bool, after:bool]=
  const tight = [".", "!", ".*", ".*.", ".?", ".."]
  result = (before:true, after:true)
  let op = ast.source(module, operator, synthetic=false)
  if kind == Prefix : result.before = false
  elif op in tight  : result.before = false
  if kind == Prefix : result.after  = false
  elif op in tight  : result.after  = false
#___________________
func operator (
    ast      : astTF.Ast;
    module   : astTF.Id;
    operator : astTF.Location;
    kind     : OperatorKind;
    Out      : var Output;
  ) :void=
  let op    = ast.source(module, operator, synthetic=false)
  let space = zig.operator_spacing(ast, module, operator, kind)
  #___________________
  if space.before:
    Out.string(module, " ", output.Target.definition)
  #___________________
  if kind == Prefix and op == "not":  # Prefix `not` is `!` on Zig. Infix `not` (eg. `a not b`) is left unchanged.
    Out.string(module, "!", output.Target.definition)
  else:
    Out.string(module, zig.operator_translate(op), output.Target.definition)
  #___________________
  if space.after:
    Out.string(module, " ", output.Target.definition)


#_______________________________________
# @section Base Helpers
#_____________________________
func indentation (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : Option[astTF.Id];
    Out    : var Output;
  ) :void=
  if id.isNone: return
  let D = ast.depth(id.get)
  for _ in 0..<D.indent.get(0): Out.string(module, base.format_Tab, output.Target.definition)
#___________________
func location (
    ast    : astTF.Ast;
    module : astTF.Id;
    loc    : astTF.Location;
    Out    : var Output;
  ) :void= Out.string(module, ast.source(module, loc, synthetic=false), output.Target.definition)
#___________________
func identifier (
    ast    : astTF.Ast;
    module : astTF.Id;
    ident  : astTF.Identifier;
    Out    : var Output;
  ) :void= Out.string(module, ast.source(module, ident), output.Target.definition)
#___________________
func comment (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let cmnt = ast.comment(id)
  let kind = ast.source(module, cmnt.kind)
  let doc  = kind in ["##", "///", "/**"]
  let text = ast.source(module, cmnt.text, synthetic=false)
  for (id, line) in text.split("\n").pairs():
    if id != 0: Out.string(module, "\n", output.Target.definition)
    let prefix = # FIX: The kind should have the `!` instead !!!
      if doc and line.len > 0 and line[0] == '!' : "//"
      elif doc                                   : "/// "
      else                                       : "// "
    Out.string(module, prefix, output.Target.definition)
    Out.string(module, line,   output.Target.definition)


#_______________________________________
# @section Bindings
#_____________________________
type BindingContext {.pure.}= enum other, variable, field
#___________________
func binding_pragma (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    ctx    : BindingContext;
    Out    : var Output;
  ) :Option[astTF.Id]=
  let pragma = ast.pragm(id)
  let key    = ast.source(module, ast.expression(pragma.key).identifier.name)
  case key
  of "align":
    Out.string(module, " ", output.Target.definition)
    Out.string(module, key, output.Target.definition)
    Out.string(module, "(", output.Target.definition)
    ast.expression(module, pragma.value.get, Out)
    Out.string(module, ")", output.Target.definition)
  else: discard
  result = pragma.next
#___________________
func binding_pragmas (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    ctx    : BindingContext;
    Out    : var Output;
  ) :void=
  var current = some(id)
  while current.isSome: current = zig.binding_pragma(ast, module, current.get, ctx, Out)
#___________________
func binding_type (
    ast : astTF.Ast;
    id  : astTF.Id
  ) :Option[astTF.Id]=
  var current = some(id)
  while current.isSome:
    let B = ast.binding(current.get)
    if B.dataType.isSome: return B.dataType
    current = B.next
  result = none(astTF.Id)
#___________________
func binding (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    prefix : string         = "";
    ctx    : BindingContext = other
  ) :Option[astTF.Id]=
  let B  = ast.binding(id)
  let T  = zig.binding_type(ast, id)
  result = B.next
  #___________________
  zig.indentation(ast, module, B.depth, Out)
  if not B.runtime.get(false) and ctx notin [variable, field]:
    Out.string(module, "comptime", output.Target.definition)
    Out.string(module, " ", output.Target.definition)
  #___________________
  # Name
  if B.name.isSome:
    Out.string(module, prefix, output.Target.definition)
    zig.identifier(ast, module, B.name.get, Out)
  #___________________
  # Pragmas
  if B.pragmas.isSome: zig.binding_pragmas(ast, module, B.pragmas.get, ctx, Out)
  #___________________
  # Type
  if B.name.isSome and T.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, ":", output.Target.definition) 
  if T.isSome:
    zig.expression(ast, module, T.get, Out)
  #___________________
  # Value
  if B.name.isSome and not T.isSome and B.value.isSome and prefix.len == 0:
    Out.string(module, " ", output.Target.definition)
  if (B.name.isSome or T.isSome) and B.value.isSome:
    Out.string(module, "=", output.Target.definition)
    Out.string(module, " ", output.Target.definition)
  if B.value.isSome:
    zig.expression(ast, module, B.value.get, Out)
  #___________________
  # HACK: Emit `,` for fields.
  #       Should be on statement level, but lets get this done for now.
  if ctx == field: Out.string(module, ",", output.Target.definition)
#___________________
func binding_list (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    sep    : string = ", ";
    prefix : string = "";
  ) :void=
  var current = some(id)
  if '\n' in sep: Out.string(module, "\n", output.Target.definition)
  while current.isSome:
    current = zig.binding(ast, module, current.get, Out, prefix)
    if current.isSome: Out.string(module, sep, output.Target.definition)
  if '\n' in sep: Out.string(module, "\n", output.Target.definition)


#_______________________________________
# @section Array Elements
#_____________________________
func array_element (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :Option[astTF.Id]=
  let E = ast.array_element(id)
  zig.expression(ast, module, E.element, Out)
  result = E.next
#___________________
func array_elements (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  var current = some(id)
  while current.isSome:
    current = zig.array_element(ast, module, current.get, Out)
    if current.isSome: Out.string(module, ", ", output.Target.definition)


#_______________________________________
# @section Procedures
#_____________________________
type ProcedureContext {.pure.}= enum other, p_type, statement, expression
#_____________________________
func procedure_pragmas_before (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let P = ast.procedure(id)
  var current = P.pragmas
  while current.isSome:
    let pragma = ast.pragm(current.get)
    let key    = ast.source(module, ast.expression(pragma.key).identifier.name)
    case key
    of "inline", "extern":
      Out.string(module, key, output.Target.definition)
      Out.string(module, " ", output.Target.definition)
    else: discard
    current = pragma.next
#___________________
func procedure_pragmas_after (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let P = ast.procedure(id)
  discard P
#___________________
func procedure (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    ctx    : ProcedureContext = other;
  ) :void=
  let P = ast.procedure(id)
  #___________________
  # Prefixes
  zig.procedure_pragmas_before(ast, module, id, Out)
  #___________________
  # Keyword
  Out.string(module, "fn", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  #___________________
  # Name
  if   ctx == p_type : discard  # Do not give name to procedure types
  elif P.name.isSome : zig.identifier(ast, module, P.name.get, Out)
  else               : Out.string(module, "f", output.Target.definition)
  if   ctx != p_type : Out.string(module, " ", output.Target.definition)
  #___________________
  # Arguments & Generics
  Out.string(module, "(", output.Target.definition)
  if P.generics.isSome:
    zig.binding_list(ast, module, P.generics.get, Out)
  if P.arguments.isSome and P.generics.isSome:
    Out.string(module, ", ", output.Target.definition)
  if P.arguments.isSome:
    zig.binding_list(ast, module, P.arguments.get, Out)
  Out.string(module, ")", output.Target.definition)
  #___________________
  # Return Type
  Out.string(module, " ", output.Target.definition)
  if P.returnType.isSome : zig.expression(ast, module, P.returnType.get, Out)
  else                   : Out.string(module, "void", output.Target.definition)
  #___________________
  # Pragmas
  zig.procedure_pragmas_after(ast, module, id, Out)
  #___________________
  # Body
  if P.body.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, "{", output.Target.definition)
    Out.string(module, "\n", output.Target.definition)
    zig.statement_list(ast, module, P.body.get, Out)
    Out.string(module, "}", output.Target.definition)


#_______________________________________
# @section Types
#_____________________________
func type_alias (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).alias
  zig.expression(ast, module, typ.target, Out)
#___________________
func type_primitive (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).primitive
  if typ.optional.get(false):
    Out.string(module, "?", output.Target.definition)
  zig.identifier(ast, module, typ.name, Out)
#___________________
func type_pointer (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).`ptr`
  if typ.optional.get(false):
    Out.string(module, "?", output.Target.definition)
  Out.string(module, "*", output.Target.definition)
  if not typ.mutable.get(false):
    Out.string(module, "const ", output.Target.definition)
  zig.Type(ast, module, typ.target, Out)
#___________________
func type_array (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).array
  if typ.optional.get(false):
    Out.string(module, "?", output.Target.definition)
  Out.string(module, "[", output.Target.definition)
  let name = case typ.name.isSome
    of true  : ast.source(module, typ.name.get)
    of false : ""
  let is_slice = typ.length.isNone or name == "slice"
  if not is_slice:
    zig.expression(ast, module, typ.length.get, Out)
  Out.string(module, "]", output.Target.definition)
  if not typ.mutable.get(false) and typ.length.isNone:
    Out.string(module, "const ", output.Target.definition)
  zig.Type(ast, module, typ.element, Out)
#___________________
func type_procedure (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).procedure
  zig.procedure(ast, module, typ.id, Out, ctx= p_type)
#___________________
func type_field (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :Option[astTF.Id]=
  let field = ast.binding(id)
  result = field.next
  zig.indentation(ast, module, field.depth, Out)
  base.format_before(ast, module, field.fmt, Out)
  #___________________
  # An aliased field is a struct-level declaration, not a data field.
  let is_alias = ast.pragma_has(module, field.pragmas, @["alias"])
  if is_alias:
    if not field.private.get(false):
      Out.string(module, "pub", output.Target.definition)
      Out.string(module, " ", output.Target.definition)
    let keyw = if field.mutable.get(false): "var" else: "const"
    Out.string(module, keyw, output.Target.definition)
    Out.string(module, " ", output.Target.definition)
  #___________________
  if field.name.isSome:
    zig.identifier(ast, module, field.name.get, Out)
  if field.name.isSome and (field.dataType.isSome or field.value.isSome):
    Out.string(module, " ", output.Target.definition)
  #___________________
  if field.dataType.isSome:
    Out.string(module, ":", output.Target.definition)
    zig.expression(ast, module, field.dataType.get, Out)
  #___________________
  if field.value.isSome:
    Out.string(module, "=", output.Target.definition)
    Out.string(module, " ", output.Target.definition)
    zig.expression(ast, module, field.value.get, Out)
  #___________________
  # End the field's line
  Out.string(module, if is_alias: ";" else: ",", output.Target.definition)
  Out.string(module, "\n", output.Target.definition)
#___________________
func type_object_fields (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).`object`
  var current = typ.fields
  while current.isSome: current = zig.type_field(ast, module, current.get, Out)
#___________________
func type_object_pragmas (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ     = ast.typ(id).`object`
  var current = typ.pragmas
  while current.isSome:
    let pragma = ast.pragm(current.get)
    let key    = ast.source(module, ast.expression(pragma.key).identifier.name)
    case key
    of "extern":
      Out.string(module, key, output.Target.definition)
      Out.string(module, " ", output.Target.definition)
    else: discard
    current = pragma.next
#___________________
func type_object (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).`object`
  if typ.optional.get(false):
    Out.string(module, "?", output.Target.definition)
  zig.type_object_pragmas(ast, module, id, Out)
  Out.string(module, "struct", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "{", output.Target.definition)
  Out.string(module, "\n", output.Target.definition)
  zig.type_object_fields(ast, module, id, Out)
  Out.string(module, "}", output.Target.definition)
#___________________
func type_enumeration_values (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).enumeration
  var current = typ.values
  while current.isSome: current = zig.type_field(ast, module, current.get, Out)
#___________________
func type_enumeration (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id).enumeration
  Out.string(module, "enum", output.Target.definition)
  if typ.backing.isSome:
    Out.string(module, "(", output.Target.definition)
    zig.expression(ast, module, typ.backing.get, Out)
    Out.string(module, ")", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "{", output.Target.definition)
  Out.string(module, "\n", output.Target.definition)
  zig.type_enumeration_values(ast, module, id, Out)
  Out.string(module, "}", output.Target.definition)
#___________________
func Type (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let typ = ast.typ(id)
  case typ.kind
  of tPrimitive   : zig.type_primitive(ast, module, id, Out)
  of tAlias       : zig.type_alias(ast, module, id, Out)
  of tPtr         : zig.type_pointer(ast, module, id, Out)
  of tArray       : zig.type_array(ast, module, id, Out)
  of tProcedure   : zig.type_procedure(ast, module, id, Out)
  of tEnumeration : zig.type_enumeration(ast, module, id, Out)
  of tObject      : zig.type_object(ast, module, id, Out)
  of tRange       : fail "range types are not supported in Zig"


#_______________________________________
# @section Expressions
#_____________________________
func expression_identifier (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).identifier
  zig.identifier(ast, module, expr.name, Out)
#___________________
func expression_literal_nil (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void= Out.string(module, "null", output.Target.definition)
#___________________
func expression_literal_char (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).literal
  Out.string(module, "'", output.Target.definition)
  zig.location(ast, module, expr.value, Out)
  Out.string(module, "'", output.Target.definition)
#___________________
func expression_literal_string (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).literal
  Out.string(module, "\"", output.Target.definition)
  zig.location(ast, module, expr.value, Out)
  Out.string(module, "\"", output.Target.definition)
#___________________
func expression_literal_any (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).literal
  zig.location(ast, module, expr.value, Out)
#___________________
func expression_literal (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).literal
  case expr.kind
  of LiteralKind.`nil`  : zig.expression_literal_nil(ast, module, id, Out)
  of LiteralKind.char   : zig.expression_literal_char(ast, module, id, Out)
  of LiteralKind.string : zig.expression_literal_string(ast, module, id, Out)
  else                  : zig.expression_literal_any(ast, module, id, Out)
#___________________
func expression_type (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void= zig.Type(ast, module, ast.expression(id).`type`.id, Out)
#___________________
func expression_group (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).group
  Out.string(module, "(", output.Target.definition)
  zig.expression_list(ast, module, expr.inner, Out)
  Out.string(module, ")", output.Target.definition)
#___________________
func expression_indexed (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).indexed
  zig.expression(ast, module, expr.`object`, Out)
  Out.string(module, "[", output.Target.definition)
  zig.expression(ast, module, expr.index, Out)
  Out.string(module, "]", output.Target.definition)
#___________________
func expression_call_tuple (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let name = ast.expression(ast.expression(id).call.name)
  result = name.kind == eIdentifier and ast.source(module, name.identifier.name) == "."
#___________________
func expression_call_constructor (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let expr = ast.expression(id).call
  let named_args = expr.arguments.isSome and ast.binding(expr.arguments.get).name.isSome
  result = named_args and not zig.expression_call_tuple(ast, module, id)
#___________________
func expression_call_arguments (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    prefix : string = "";
  ) :void=
  let expr = ast.expression(id).call
  if expr.generics.isSome:
    zig.binding_list(ast, module, expr.generics.get, Out, prefix=prefix)
  if expr.arguments.isSome and expr.generics.isSome:
    Out.string(module, ", ", output.Target.definition)
  if expr.arguments.isSome:
    zig.binding_list(ast, module, expr.arguments.get, Out, prefix=prefix)
#___________________
func expression_constructor (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).call
  zig.expression(ast, module, expr.name, Out)
  Out.string(module, "{", output.Target.definition)
  zig.expression_call_arguments(ast, module, id, Out, prefix=".")
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_call_function (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).call
  zig.expression(ast, module, expr.name, Out)
  Out.string(module, "(", output.Target.definition)
  zig.expression_call_arguments(ast, module, id, Out)
  Out.string(module, ")", output.Target.definition)
#___________________
func expression_call (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  if zig.expression_call_tuple(ast, module, id) or zig.expression_call_constructor(ast, module, id):
    zig.expression_constructor(ast, module, id, Out)
  else:
    zig.expression_call_function(ast, module, id, Out)
#___________________
func expression_object (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr  = ast.expression(id).`object`
  let first = ast.binding(expr.fields)
  Out.string(module, ".", output.Target.definition)
  Out.string(module, "{", output.Target.definition)
  if first.name.isSome or first.dataType.isSome or first.value.isSome:
    zig.binding_list(ast, module, expr.fields, Out, sep=",\n", prefix=".")
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_array (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).array
  Out.string(module, ".", output.Target.definition)
  Out.string(module, "{", output.Target.definition)
  if expr.elements.isSome: zig.array_elements(ast, module, expr.elements.get, Out)
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_keyword_block (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).keyword
  if expr.label.isSome:
    let label = ast.source(module, expr.label.get)
    if label != "_":
      zig.identifier(ast, module, expr.label.get, Out)
      Out.string(module, ":", output.Target.definition)
      Out.string(module, " ", output.Target.definition)
  if expr.value.isSome:
    zig.expression(ast, module, expr.value.get, Out)
#___________________
func expression_keyword_discard (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).keyword
  Out.string(module, "_", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "=", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  if expr.value.isSome:
    zig.expression(ast, module, expr.value.get, Out)
#___________________
func expression_keyword_test (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).keyword
  zig.identifier(ast, module, expr.keyword, Out)
  if expr.label.isSome:
    Out.string(module, " ", output.Target.definition)
    zig.identifier(ast, module, expr.label.get, Out)
  Out.string(module, " ", output.Target.definition)
  if expr.value.isSome:
    zig.expression(ast, module, expr.value.get, Out)
#___________________
func expression_keyword_labeled (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).keyword
  zig.identifier(ast, module, expr.keyword, Out)
  if expr.label.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, ":", output.Target.definition)
    zig.identifier(ast, module, expr.label.get, Out)
  if expr.value.isSome:
    Out.string(module, " ", output.Target.definition)
    zig.expression(ast, module, expr.value.get, Out)
#___________________
func expression_keyword (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).keyword
  let keyw = ast.source(module, expr.keyword)
  case keyw
  of "block"   : zig.expression_keyword_block(ast, module, id, Out)
  of "discard" : zig.expression_keyword_discard(ast, module, id, Out)
  of "test"    : zig.expression_keyword_test(ast, module, id, Out)
  else         : zig.expression_keyword_labeled(ast, module, id, Out)
#___________________
func expression_affix (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).affix
  let kind = if expr.left.isNone: Prefix elif expr.right.isNone: Postfix else: Affix
  #___________________
  if expr.left.isSome:
    zig.expression(ast, module, expr.left.get, Out)
  #___________________
  zig.operator(ast, module, expr.operator, kind, Out)
  #___________________
  if expr.right.isSome:
    zig.expression(ast, module, expr.right.get, Out)
#___________________
func expression_loop_header_for (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr   = ast.expression(id).loop
  Out.string(module, "for (", output.Target.definition)
  zig.expression_list(ast, module, expr.condition.get, Out)
  Out.string(module, ") |", output.Target.definition)
  zig.statement_list(ast, module, expr.sentry.get, Out, some(", "))
  Out.string(module, "|", output.Target.definition)
#___________________
func expression_loop_header_while (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).loop
  Out.string(module, "while (", output.Target.definition)
  zig.expression_list(ast, module, expr.condition.get, Out)
  Out.string(module, ")", output.Target.definition)
  # Sentry/Capture Variable
  if expr.sentry.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, "|", output.Target.definition)
    zig.statement_list(ast, module, expr.sentry.get, Out, some(", "))
    Out.string(module, "|", output.Target.definition)
  # Increment Expression
  if expr.increment.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, ":", output.Target.definition)
    Out.string(module, " ", output.Target.definition)
    Out.string(module, "(", output.Target.definition)
    zig.expression(ast, module, expr.increment.get, Out)
    Out.string(module, ")", output.Target.definition)
#___________________
func expression_conditional_body (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let next  = ast.statement_next(id)
  let depth = ast.statement_depth(id)
  Out.string(module, " ", output.Target.definition)
  if next.isSome:
    Out.string(module, "{", output.Target.definition)
    Out.string(module, "\n", output.Target.definition)
  zig.statement_list(ast, module, id, Out, post= if next.isSome: none(system.string) else: some(""))
  if next.isSome:
    zig.indentation(ast, module, depth, Out)
    Out.string(module, "}", output.Target.definition)
#___________________
func expression_conditional_switch_branch (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let branch = ast.statement(id).branch
  case branch.condition.isSome:
  of true  : ast.expression_list(module, branch.condition.get, Out)
  of false : Out.string(module, "else", output.Target.definition)
  Out.string(module, " ",  output.Target.definition)
  Out.string(module, "=>", output.Target.definition)
#___________________
func expression_conditional_switch (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).conditional
  Out.string(module, "switch", output.Target.definition)
  Out.string(module, " ",      output.Target.definition)
  Out.string(module, "(",      output.Target.definition)
  zig.expression(ast, module, expr.condition, Out)
  Out.string(module, ")",  output.Target.definition)
  Out.string(module, " ",  output.Target.definition)
  Out.string(module, "{",  output.Target.definition)
  Out.string(module, "\n", output.Target.definition)
  var current = expr.branches
  while current.isSome:
    let branch = ast.statement(current.get).branch
    zig.expression_conditional_switch_branch(ast, module, current.get, Out)
    if branch.body.isSome:
      zig.expression_conditional_body(ast, module, branch.body.get, Out)
    Out.string(module, ",",  output.Target.definition)
    Out.string(module, "\n", output.Target.definition)
    current = branch.next
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_conditional_if (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).conditional
  Out.string(module, "if (", output.Target.definition)
  zig.expression(ast, module, expr.condition, Out)
  Out.string(module, ")", output.Target.definition)
  # Sentry/Capture Variable
  if expr.sentry.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, "|", output.Target.definition)
    zig.statement_list(ast, module, expr.sentry.get, Out, some(", "))
    Out.string(module, "|", output.Target.definition)
  # Body
  if expr.body.isSome     : zig.expression_conditional_body(ast, module, expr.body.get, Out)
  if expr.branches.isSome : discard zig.statement(ast, module, expr.branches.get, Out)
#___________________
func expression_conditional (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).conditional
  case expr.keyword.isSome:
  of true  : zig.expression_conditional_switch(ast, module, id, Out)
  of false : zig.expression_conditional_if(ast, module, id, Out)
#___________________
func expression_loop (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).loop
  if expr.keyword.isNone : zig.expression_loop_header_for(ast, module, id, Out)
  else                   : zig.expression_loop_header_while(ast, module, id, Out)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "{\n", output.Target.definition)
  if expr.body.isSome: zig.statement_list(ast, module, expr.body.get, Out)
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_block (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).`block`
  Out.string(module, "{", output.Target.definition)
  if expr.body.isSome:
    Out.string(module, "\n", output.Target.definition)
    zig.statement_list(ast, module, expr.body.get, Out)
  Out.string(module, "}", output.Target.definition)
#___________________
func expression_procedure (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id).procedure
  let P    = ast.procedure(expr.id)
  Out.string(module, "struct", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "{", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  zig.procedure(ast, module, expr.id, Out)
  Out.string(module, "}", output.Target.definition)
  Out.string(module, ".", output.Target.definition)
  if P.name.isSome : zig.identifier(ast, module, P.name.get, Out)
  else             : Out.string(module, "f", output.Target.definition)
#___________________
func expression *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr = ast.expression(id)
  case expr.kind
  of eLiteral     : zig.expression_literal(ast, module, id, Out)
  of eIdentifier  : zig.expression_identifier(ast, module, id, Out)
  of eType        : zig.expression_type(ast, module, id, Out)
  of eCall        : zig.expression_call(ast, module, id, Out)
  of eAffix       : zig.expression_affix(ast, module, id, Out)
  of eKeyword     : zig.expression_keyword(ast, module, id, Out)
  of eConditional : zig.expression_conditional(ast, module, id, Out)
  of eLoop        : zig.expression_loop(ast, module, id, Out)
  of eGroup       : zig.expression_group(ast, module, id, Out)
  of eBlock       : zig.expression_block(ast, module, id, Out)
  of eIndexed     : zig.expression_indexed(ast, module, id, Out)
  of eObject      : zig.expression_object(ast, module, id, Out)
  of eArray       : zig.expression_array(ast, module, id, Out)
  of eProcedure   : zig.expression_procedure(ast, module, id, Out)
  # of eRange       : zig.expression_range(ast, module, id, Out)
  else: fail "Unsupported expression kind: ", expr.kind
#___________________
func expression_list (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  var current = some(id)
  while current.isSome:
    zig.expression(ast, module, current.get, Out)
    current = ast.expression_next(current.get)
    if current.isSome: Out.string(module, ", ", output.Target.definition)


#_______________________________________
# @section Statements
#_____________________________
func statement_variable_is_field (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let stmt = ast.statement(id).variable
  let B    = ast.binding(stmt.id)
  return ast.pragma_has(module, B.pragmas, @["field"])
#___________________
func statement_variable (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt  = ast.statement(id).variable
  let B     = ast.binding(stmt.id)
  let keyw  = if B.mutable.get(false): "var" else: "const"
  let ctx   = if zig.statement_variable_is_field(ast, module, id): field else: variable
  if ctx == variable:
    Out.string(module, keyw, output.Target.definition)
    Out.string(module, " ", output.Target.definition)
  discard zig.binding(ast, module, stmt.id, Out, ctx= ctx)
#___________________
func statement_procedure (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let proc_id = ast.statement(id).procedure.id
  zig.procedure(ast, module, proc_id, Out)
#___________________
func statement_type (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let type_id = ast.statement(id).`type`.id
  let name    = base.type_name(ast, module, type_id)
  Out.string(module, "const", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, name, output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "=", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  zig.Type(ast, module, type_id, Out)
#___________________
func statement_branch (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).branch
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "else", output.Target.definition)
  #___________________
  if stmt.condition.isSome:
    Out.string(module, " ", output.Target.definition)
    Out.string(module, "if (", output.Target.definition)
    zig.expression(ast, module, stmt.condition.get, Out)
    Out.string(module, ")", output.Target.definition)
  #___________________
  if stmt.body.isSome:
    zig.expression_conditional_body(ast, module, stmt.body.get, Out)
  #___________________
  if stmt.next.isSome:
    discard zig.statement(ast, module, stmt.next.get, Out)
#___________________
func statement_import_code (
    module  : astTF.Id;
    name    : system.string;
    path    : system.string;
    Out     : var Output;
    subpath : system.string = "";
  ) :void=
  Out.string(module, "const",    output.Target.definition)
  Out.string(module, " ",        output.Target.definition)
  Out.string(module, name,       output.Target.definition)
  Out.string(module, " ",        output.Target.definition)
  Out.string(module, "=",        output.Target.definition)
  Out.string(module, " ",        output.Target.definition)
  Out.string(module, "@import",  output.Target.definition)
  Out.string(module, "(",        output.Target.definition)
  Out.string(module, "\"",       output.Target.definition)
  Out.string(module, path,       output.Target.definition)
  Out.string(module, "\"",       output.Target.definition)
  Out.string(module, ")",        output.Target.definition)
  if subpath.len > 0:
    Out.string(module, ".",      output.Target.definition)
    Out.string(module, subpath,  output.Target.definition)
#___________________
func statement_import_withSymbols (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).`import`
  let path = ast.source(module, stmt.path, synthetic=false)
  var current = stmt.symbols
  var first   = true
  while current.isSome:
    let S      = ast.alias(current.get)
    let symbol = ast.source(module, S.name)
    let name   =
      if S.target.isSome : ast.source(module, S.target.get)
      else               : symbol.split(".")[^1]
    #___________________
    # public marker for sub-symbols only
    if not first:
      Out.string(module, "pub", output.Target.definition)
      Out.string(module, " ", output.Target.definition)
    #___________________
    zig.statement_import_code(module, name, path, Out, subpath=symbol)
    #___________________
    current = S.next
    first   = false
    if S.next.isSome:
      Out.string(module, ";", output.Target.definition)
      Out.string(module, "\n", output.Target.definition)
#___________________
func statement_import_simple (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).`import`
  let path = ast.source(module, stmt.path, synthetic=false)
  let name :string= case stmt.alias.isSome:
    of true  : ast.source(module, stmt.alias.get.location, synthetic=false)
    of false : path.lastPathPart().changeFileExt("") # Last path part should be the name
  zig.statement_import_code(module, name, path, Out)
#___________________
func statement_import (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).`import`
  if stmt.symbols.isSome : zig.statement_import_withSymbols(ast, module, id, Out)
  else                   : zig.statement_import_simple(ast, module, id, Out)
#___________________
func statement_passthrough (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).passthrough
  Out.string(module, ast.source(module, stmt.location, synthetic=false), output.Target.definition)
#___________________
func statement_comment (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt = ast.statement(id).comment
  zig.comment(ast, module, stmt.id, Out)
#___________________
func statement_alias (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let stmt  = ast.statement(id).alias
  let alias = ast.alias(stmt.id)
  Out.string(module, "const", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  zig.identifier(ast, module, alias.name, Out)
  Out.string(module, " ", output.Target.definition)
  Out.string(module, "=", output.Target.definition)
  Out.string(module, " ", output.Target.definition)
  if alias.target.isSome : zig.identifier(ast, module, alias.target.get, Out)
  else                   : Out.string(module, "?*anyopaque", output.Target.definition)
#___________________
func statement_expression (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
  ) :void=
  let expr_id = ast.statement(id).expression.id
  zig.expression(ast, module, expr_id, Out)
#___________________
func statement_needs_newline (
    ast : astTF.Ast;
    id  : astTF.Id;
  ) :bool=
  let stmt = ast.statement(id)
  result = case stmt.kind
    of astTF.sBranch : false
    else             : true
#___________________
func statement_expression_keyword_needs_semicolon (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let expr = ast.expression(id).keyword
  result = ast.source(module, expr.keyword) notin ["block", "test"]
#___________________
func statement_expression_conditional_needs_semicolon (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let expr          = ast.expression(id).conditional
  let is_last       = expr.branches.isNone
  let one_statement = expr.body.isSome and ast.statement_next(expr.body.get).isNone
  if is_last: return one_statement
  var current = expr.branches
  while current.isSome:
    let S   = ast.statement(current.get).branch
    result  = S.body.isSome and ast.statement_next(S.body.get).isNone
    current = S.next
#___________________
func statement_expression_needs_semicolon (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let expr = ast.expression(id)
  case expr.kind
  of eKeyword     : zig.statement_expression_keyword_needs_semicolon(ast, module, id)
  of eConditional : zig.statement_expression_conditional_needs_semicolon(ast, module, id)
  of eProcedure   : false
  of eLoop        : false
  of eBlock       : false
  else            : true
#___________________
func statement_procedure_needs_semicolon (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let P = ast.procedure(id)
  result = P.body.isNone
#___________________
func statement_needs_semicolon (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :bool=
  let stmt = ast.statement(id)
  result = case stmt.kind
    of sType        : true
    of sImport      : true
    of sAlias       : true
    of sPragma      : true
    of sBranch      : false
    of sPassthrough : false
    of sComment     : false
    of sVariable    : not zig.statement_variable_is_field(ast, module, id)
    of sExpression  : zig.statement_expression_needs_semicolon(ast, module, stmt.expression.id)
    of sProcedure   : zig.statement_procedure_needs_semicolon(ast, module, stmt.procedure.id)
#___________________
func statement (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    post   : Option[system.string] = none(system.string);
    last   : bool   = false;
  ) :Option[astTF.Id]=
  let stmt  = ast.statement(id)
  let depth = ast.statement_depth(id)
  let fmt   = ast.statement_format(id)
  if stmt.kind != sBranch:
    zig.indentation(ast, module, depth, Out)
  base.format_before(ast, module, fmt, Out)
  if not ast.statement_private(module, id):
    Out.string(module, "pub", output.Target.definition)
    Out.string(module, " ", output.Target.definition)
  case stmt.kind
  of sType        : zig.statement_type(ast, module, id, Out)
  of sVariable    : zig.statement_variable(ast, module, id, Out)
  of sProcedure   : zig.statement_procedure(ast, module, id, Out)
  of sExpression  : zig.statement_expression(ast, module, id, Out)
  of sBranch      : zig.statement_branch(ast, module, id, Out)
  of sImport      : zig.statement_import(ast, module, id, Out)
  of sPassthrough : zig.statement_passthrough(ast, module, id, Out)
  of sComment     : zig.statement_comment(ast, module, id, Out)
  of sAlias       : zig.statement_alias(ast, module, id, Out)
  of sPragma      : fail "Pragma Statements are not supported for Zig"
  if post.isSome:
     if not last: Out.string(module, post.get, output.Target.definition)
  else:
    if ast.statement_needs_semicolon(module, id):
      Out.string(module, ";", output.Target.definition)
    if ast.statement_needs_newline(id):
      Out.string(module, "\n", output.Target.definition)
  result = ast.statement_next(id)
#___________________
func statement_list (
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
    Out    : var Output;
    post   : Option[system.string] = none(system.string);
  ) :void=
  var current = some(id)
  while current.isSome: current = zig.statement(ast, module, current.get, Out, post, ast.statement_next(current.get).isNone)


#_______________________________________
# @section Entry Point
#_____________________________
func zig *(
    ast    : astTF.Ast;
    target : output.Target = output.Target.definition;
  ) :Output=
  result = Output()
  for id in 0 ..< ast.data.modules.len:
    let module = ast.module(astTF.Id(id))
    result.modules.add output.Module(path: module.path)
    if module.body.isSome:
      ast.statement_list(astTF.Id(id), module.body.get, result)

