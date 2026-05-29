#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Converts Nim PNode AST (typed or untyped) into astTF data.
## Takes a single root PNode and walks it recursively.
#____________________________________________________________|
# @deps nimc
import "$nim"/compiler/[ast, types]
# @deps std
import std/options
# @deps nonim
import ../nimc/ergonomics
import ./types as astTF
import ./data as ast_data
import ./access


type Language * = enum
  C
  Zig
  Nim

type Needs = object
  stdint   :bool
  stdbool  :bool

type State = object
  ast            :astTF.Ast
  module         :astTF.Id
  source         :string
  previous_stmt  :Option[astTF.Id]
  target         :Language
  typed          :bool
  needs          :Needs
  next_scope     :uint64
  scope_stack    :seq[uint64]


proc scope_push (state :var State) :uint64=
  result = state.next_scope
  state.next_scope += 1
  state.scope_stack.add(result)

proc scope_pop (state :var State) =
  discard state.scope_stack.pop()

proc scope_current (state :State) :uint64=
  state.scope_stack[^1]

proc scope_depth (state :State) :uint64=
  uint64(state.scope_stack.len - 1)

proc make_depth (state :var State; node :PNode) :astTF.Id=
  state.ast.add_depth(astTF.Depth(
    line   : some(uint64(node.info.line)),
    column : some(uint64(node.info.col)),
    indent : some(state.scope_depth),
    scope  : some(state.scope_current),
  ))

proc name_add (state :var State; name :string) :astTF.Location=
  let start = uint64(state.source.len)
  state.source.add(name)
  let finish = uint64(state.source.len)
  state.ast.data.modules[state.module].source = state.source
  return astTF.Location(start: start, `end`: finish)


proc name (node :PNode) :string=
  case node.kind
  of nkSym:        node.sym.name.s
  of nkIdent:      node.ident.s
  of nkPostfix:    node[1].name()
  of nkPragmaExpr: node[0].name()
  of nkDotExpr:    node[0].name() & "." & node[1].name()
  of nkAccQuoted:  node.strValue
  else:            ""

proc translate_type_c (state :var State; nim_type :string) :string=
  result = case nim_type
    of "int":      "int64_t"
    of "int8":     "int8_t"
    of "int16":    "int16_t"
    of "int32":    "int32_t"
    of "int64":    "int64_t"
    of "uint":     "uint64_t"
    of "uint8":    "uint8_t"
    of "uint16":   "uint16_t"
    of "uint32":   "uint32_t"
    of "uint64":   "uint64_t"
    of "float":    "double"
    of "float32":  "float"
    of "float64":  "double"
    of "bool":     "bool"
    of "char":     "char"
    of "cint":     "int"
    of "cuint":    "unsigned int"
    of "clong":    "long"
    of "culong":   "unsigned long"
    of "clonglong":"long long"
    of "cfloat":   "float"
    of "cdouble":  "double"
    of "cchar":    "char"
    of "cschar":   "signed char"
    of "cuchar":   "unsigned char"
    of "cshort":   "short"
    of "cushort":  "unsigned short"
    of "csize_t":  "size_t"
    of "cstring":  "char const*"
    of "void":     "void"
    else:          nim_type
  state.needs.stdint = result in [
    "int64_t",  "int8_t",  "int16_t",  "int32_t",
    "uint64_t", "uint8_t", "uint16_t", "uint32_t",
    "size_t" ]
  state.needs.stdbool = result == "bool"

proc translate_type_zig (state :var State; nim_type :string) :string=
  result = case nim_type
    of "int":      "isize"
    of "int8":     "i8"
    of "int16":    "i16"
    of "int32":    "i32"
    of "int64":    "i64"
    of "uint":     "usize"
    of "uint8":    "u8"
    of "uint16":   "u16"
    of "uint32":   "u32"
    of "uint64":   "u64"
    of "float":    "f64"
    of "float32":  "f32"
    of "float64":  "f64"
    of "bool":     "bool"
    of "char":     "u8"
    of "cint":     "c_int"
    of "cuint":    "c_uint"
    of "clong":    "c_long"
    of "culong":   "c_ulong"
    of "clonglong":"c_longlong"
    of "cfloat":   "f32"
    of "cdouble":  "f64"
    of "cchar":    "u8"
    of "cschar":   "i8"
    of "cuchar":   "u8"
    of "cshort":   "c_short"
    of "cushort":  "c_ushort"
    of "csize_t":  "usize"
    of "cstring":  "[:0]const u8"
    of "void":     "void"
    of "any":      "anytype"
    else:          nim_type

proc translate_type_untyped (state :var State; nim_type :string) :string=
  ## Untyped backends pass type names through verbatim, except for Nim reserved
  ## keywords that have no valid identifier form and must map to the target's
  ## spelling (eg. `typedesc` → Zig `type`).
  if state.target == Language.Zig and nim_type == "typedesc": return "type"
  return nim_type

proc translate_type (state :var State; nim_type :string) :string=
  if not state.typed: return state.translate_type_untyped(nim_type)
  result = case state.target
    of Language.C   : state.translate_type_c(nim_type)
    of Language.Zig : state.translate_type_zig(nim_type)
    of Language.Nim : nim_type

proc type_from_sym (state :var State; node :PNode) :Option[astTF.Id]=
  if node.kind == nkSym and node.sym.typ != nil:
    if node.sym.typ.kind == tyPtr and node.sym.typ.len > 0:
      let target_name = state.translate_type(typeToString(node.sym.typ[0]))
      let target_loc  = state.name_add(target_name)
      let target_id   = state.ast.add_type(astTF.Type(
        kind      : astTF.tPrimitive,
        primitive : astTF.TypePrimitive(name: astTF.Identifier(location: target_loc)),
      ))
      let ptr_id = state.ast.add_type(astTF.Type(
        kind  : astTF.tPtr,
        `ptr` : astTF.TypePtr(target: target_id),
      ))
      return some(state.ast.add_expression(astTF.Expression(
        kind   : astTF.eType,
        `type` : astTF.ExpressionType(id: ptr_id),
      )))
    let type_name = state.translate_type(typeToString(node.sym.typ))
    let type_loc  = state.name_add(type_name)
    return some(state.ast.add_expression(astTF.Expression(
      kind       : astTF.eIdentifier,
      identifier : astTF.ExpressionIdentifier(name: astTF.Identifier(location: type_loc)),
    )))
  return none(astTF.Id)

proc exported (node :PNode) :bool=
  case node.kind
  of nkPostfix:    true
  of nkPragmaExpr: node[0].exported()
  of nkSym:        sfExported in node.sym.flags
  else:            false

proc alias_pragma_value (node :PNode) :PNode=
  ## For an object field name node, returns the value `V` of an `{.alias: V.}`
  ## pragma if present, else nil. The field then becomes a `const name = V;`.
  if node.kind != nkPragmaExpr or node.safeLen < 2: return nil
  let pragma = node[1]
  if pragma.kind != nkPragma: return nil
  for entry in pragma:
    if entry.kind == nkExprColonExpr and entry.safeLen >= 2 and entry[0].name() == "alias":
      return entry[1]
  return nil

proc pragma_has (pragma_node :PNode; key :string) :bool=
  ## True when a raw nkPragma node contains a `{.key.}` entry.
  if pragma_node == nil or pragma_node.kind != nkPragma: return false
  for entry in pragma_node:
    let entry_key = if entry.kind == nkExprColonExpr and entry.safeLen > 0: entry[0] else: entry
    if entry_key.name() == key: return true
  return false

proc has_private_pragma (node :PNode) :bool=
  ## True when a declaration name node (nkPragmaExpr) carries a `{.private.}` marker.
  if node.kind != nkPragmaExpr or node.safeLen < 2: return false
  return node[1].pragma_has("private")

proc declaration_private (state :State; name_node :PNode; pragma_node :PNode = nil) :bool=
  ## Visibility rule. minz (untyped Zig) makes everything public by default and
  ## ignores the `*` export postfix; only a `{.private.}` pragma marks a declaration
  ## private. Every other backend keeps Nim's `*`-export convention.
  if state.target == Language.Zig and not state.typed:
    return name_node.has_private_pragma() or pragma_node.pragma_has("private")
  return not name_node.exported()

proc is_type_block (node :PNode) :bool=
  ## Detects the `block @keyword: <body>` form that minz uses to write a type
  ## expression as a value (Nim rejects `const a = struct = ...`).
  if node.kind != nkBlockStmt: return false
  if node.safeLen < 2 or node[0].kind != nkEmpty: return false
  let body = node[1]
  if body.kind != nkStmtList or body.safeLen == 0: return false
  let head = body[0]
  return head.kind == nkPrefix and head.safeLen > 1 and head[0].name() == "@"


#_______________________________________
# @section Helpers (forward declarations)
#_____________________________
proc include_path (node :PNode) :string
proc include_is_global (node :PNode) :bool
proc symbol_path (node :PNode) :string
proc resolve_import_path (raw_path :string; is_module :bool) :string

# @section Expressions
#_____________________________
proc expression (state :var State; node :PNode) :astTF.Id
proc expression_array_type (state :var State; node :PNode) :astTF.Id
proc procedure_build (state :var State; node :PNode) :astTF.Id
proc statement_body (state :var State; node :PNode) :astTF.Id
proc is_at_prefix (node :PNode; prefix :string) :bool
proc expression_call (state :var State; node :PNode) :astTF.Id
proc expression_dot (state :var State; node :PNode) :astTF.Id
proc expression_infix (state :var State; node :PNode) :astTF.Id
proc expression_prefix (state :var State; node :PNode) :astTF.Id

proc expression_literal_nil (state :var State) :astTF.Id=
  let value_str = case state.target
    of Language.C:   "NULL"
    of Language.Zig: "null"
    of Language.Nim: "nil"
  let value_loc = state.name_add(value_str)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.nil, value: value_loc),
  ))

proc expression_literal_bool (state :var State; value :string) :astTF.Id=
  let value_loc = state.name_add(value)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.bool, value: value_loc),
  ))

proc expression_literal (state :var State; node :PNode) :astTF.Id=
  if node.kind in Nil: return state.expression_literal_nil()
  let literal_kind = case node.kind
    of Char:  astTF.LiteralKind.char
    of Int:   astTF.LiteralKind.integer
    of UInt:  astTF.LiteralKind.integer
    of Float: astTF.LiteralKind.float
    of Str:   astTF.LiteralKind.string
    else:     astTF.LiteralKind.generic
  let value_loc = state.name_add(node.strValue)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: literal_kind, value: value_loc),
  ))

proc expression_identifier (state :var State; node :PNode) :astTF.Id=
  let name = node.name()
  let name_loc = state.name_add(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc type_identifier (state :var State; node :PNode) :astTF.Id=
  let name = state.translate_type(node.name())
  let name_loc = state.name_add(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc type_node_to_type_id (state :var State; node :PNode; mutable = false) :astTF.Id=
  ## Single recursive Type builder for any type-position node. Nested element
  ## (array) and target (pointer) types recurse here too, so `array[N, ptr T]`,
  ## `array[N, array[M, T]]`, `var ptr T`, and qualified names all resolve.
  case node.kind
  of nkVarTy:
    # `var ptr T` -> mutable pointee; a bare `var T` just unwraps.
    let inner = if node.safeLen > 0: node[0] else: node
    return state.type_node_to_type_id(inner, mutable = inner.kind == nkPtrTy or mutable)
  of nkPtrTy:
    let target_id = state.type_node_to_type_id(node[0], mutable)
    return state.ast.add_type(astTF.Type(
      kind: astTF.tPtr,
      `ptr`: astTF.TypePtr(target: target_id),
    ))
  of nkBracketExpr:
    let bracket_name = node[0].name()
    if bracket_name == "array":
      let element_node = node[2]
      let is_mutable = element_node.kind == nkVarTy
      let element_id = state.type_node_to_type_id(element_node)
      var length_id = none(astTF.Id)
      if node[1].kind in SomeLit: length_id = some(state.expression_literal(node[1]))
      return state.ast.add_type(astTF.Type(
        kind: astTF.tArray,
        array: astTF.TypeArray(element: element_id, length: length_id, mutable: some(is_mutable)),
      ))
  else: discard
  let name = state.translate_type(node.name())
  let name_loc = state.name_add(name)
  state.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: name_loc), mutable: some(mutable)),
  ))

proc expression_of_type (state :var State; type_id :astTF.Id) :astTF.Id=
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eType,
    `type`: astTF.ExpressionType(id: type_id),
  ))

proc type_bracket (state :var State; node :PNode) :astTF.Id=
  if node[0].name() == "array":
    state.expression_array_type(node)
  else:
    state.type_identifier(node)

proc type_error (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of nkPrefix : result = state.expression_prefix(node)
  of nkInfix  : result = state.expression_infix(node)
  else        : assert false, "astTF.convert.type_error: Tried to convert a non-affix into an error union expression."

proc expression_type (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of nkPtrTy, nkVarTy  : state.expression_of_type(state.type_node_to_type_id(node))
  of nkBracketExpr     : state.type_bracket(node)
  of nkDotExpr         : state.expression_dot(node)
  of nkPrefix, nkInfix : state.type_error(node)
  of nkCall, nkCommand : state.expression_call(node)
  else                 : state.type_identifier(node)

proc expression_identifier (state :var State; name :string) :astTF.Id=
  let name_loc = state.name_add(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc expression_dot (state :var State; node :PNode) :astTF.Id=
  let left_id = state.expression(node[0])
  let right_id = state.expression(node[1])
  let operator_loc = state.name_add(".")
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      left: some(left_id),
      right: some(right_id),
      operator: operator_loc,
    ),
  ))

proc translate_operator (state :State; operator :string) :string=
  if state.target == Language.Zig:
    case operator
    of "??": return "orelse"
    else: discard
  return operator

proc expression_infix (state :var State; node :PNode) :astTF.Id=
  let operator_node = node[0]
  let left_node = node[1]
  let right_node = node[2]
  let operator_loc = state.name_add(state.translate_operator(operator_node.name()))
  let left_id = state.expression(left_node)
  let right_id = state.expression(right_node)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      left: some(left_id),
      right: some(right_id),
      operator: operator_loc,
    ),
  ))

proc expression_object_positional (state :var State; node :PNode; first :int) :astTF.Id=
  ## Builds a Zig anonymous literal `.{v0, v1, ...}` (an eObject whose field
  ## bindings carry values but no names) from node children `[first ..< len]`.
  var first_field = none(astTF.Id)
  var previous_field = none(astTF.Id)
  for index in first ..< node.safeLen:
    let value_id = state.expression(node[index])
    let binding_id = state.ast.add_binding(astTF.Binding(value: some(value_id)))
    if first_field.isNone:
      first_field = some(binding_id)
    if previous_field.isSome:
      var prev = state.ast.binding(previous_field.get)
      prev.next = some(binding_id)
      state.ast.data.bindings.get[previous_field.get] = prev
    previous_field = some(binding_id)
  let fields = if first_field.isSome: first_field.get
               else: state.ast.add_binding(astTF.Binding())
  state.ast.add_expression(astTF.Expression(
    kind     : astTF.eObject,
    `object` : astTF.ExpressionObject(fields: fields),
  ))

proc expression_array (state :var State; node :PNode) :astTF.Id=
  ## `[a, b, c]` -> array literal (distinct from tuples/objects): an eArray with a
  ## chain of positional ArrayElements.
  var first_element = none(astTF.Id)
  var previous_element = none(astTF.Id)
  for index in 0 ..< node.safeLen:
    let value_id = state.expression(node[index])
    let element_id = state.ast.add_array_element(astTF.ArrayElement(element: value_id))
    if first_element.isNone:
      first_element = some(element_id)
    if previous_element.isSome:
      var prev = state.ast.data.array_elements.get[previous_element.get]
      prev.next = some(element_id)
      state.ast.data.array_elements.get[previous_element.get] = prev
    previous_element = some(element_id)
  state.ast.add_expression(astTF.Expression(
    kind  : astTF.eArray,
    array : astTF.ExpressionArray(elements: first_element.get),
  ))

proc expression_dot_leading (state :var State; node :PNode) :astTF.Id=
  ## Leading-dot forms parse with an empty head node:
  ##   `.name` (nkCommand)      -> enum literal, rendered as a prefix `.` affix.
  ##   `.(a, b, c)` (nkCall)    -> anonymous tuple/struct literal `.{a, b, c}`.
  if node.kind == nkCommand and node.safeLen >= 2:
    let value_id = state.expression(node[1])
    let dot_loc  = state.name_add(".")
    return state.ast.add_expression(astTF.Expression(
      kind  : astTF.eAffix,
      affix : astTF.ExpressionAffix(right: some(value_id), operator: dot_loc),
    ))
  state.expression_object_positional(node, 1)

proc expression_call (state :var State; node :PNode) :astTF.Id=
  let function_node = node[0]
  if function_node.kind == nkEmpty:
    return state.expression_dot_leading(node)
  let function_id = state.expression(function_node)
  var first_argument = none(astTF.Id)
  var previous_binding = none(astTF.Id)
  for arg_index in 1 ..< node.safeLen:
    let arg_node = node[arg_index]
    let value_id = state.expression(arg_node)
    let binding = astTF.Binding(value: some(value_id))
    let binding_id = state.ast.add_binding(binding)
    if first_argument.isNone:
      first_argument = some(binding_id)
    if previous_binding.isSome:
      var prev = state.ast.binding(previous_binding.get)
      prev.next = some(binding_id)
      state.ast.data.bindings.get[previous_binding.get] = prev
    previous_binding = some(binding_id)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: function_id,
      arguments: first_argument,
    ),
  ))

proc expression_tuple (state :var State; node :PNode) :astTF.Id=
  let has_names = node.safeLen > 0 and node[0].kind == nkExprColonExpr
  if has_names:
    var first_field = none(astTF.Id)
    var previous_field = none(astTF.Id)
    for i in 0 ..< node.safeLen:
      let child = node[i]
      if child.kind != nkExprColonExpr or child.safeLen < 2: continue
      let name_loc = state.name_add(child[0].name())
      let value_id = state.expression(child[1])
      let binding = astTF.Binding(
        name: some(astTF.Identifier(location: name_loc)),
        value: some(value_id),
      )
      let binding_id = state.ast.add_binding(binding)
      if first_field.isNone:
        first_field = some(binding_id)
      if previous_field.isSome:
        var prev = state.ast.binding(previous_field.get)
        prev.next = some(binding_id)
        state.ast.data.bindings.get[previous_field.get] = prev
      previous_field = some(binding_id)
    return state.ast.add_expression(astTF.Expression(
      kind: astTF.eObject,
      `object`: astTF.ExpressionObject(
        fields: first_field.get,
      ),
    ))
  let dot_id = state.expression_identifier(".")
  var first_argument = none(astTF.Id)
  var previous_binding = none(astTF.Id)
  for i in 0 ..< node.safeLen:
    let value_id = state.expression(node[i])
    let binding = astTF.Binding(value: some(value_id))
    let binding_id = state.ast.add_binding(binding)
    if first_argument.isNone:
      first_argument = some(binding_id)
    if previous_binding.isSome:
      var prev = state.ast.binding(previous_binding.get)
      prev.next = some(binding_id)
      state.ast.data.bindings.get[previous_binding.get] = prev
    previous_binding = some(binding_id)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eCall,
    call: astTF.ExpressionCall(
      name: dot_id,
      arguments: first_argument,
    ),
  ))

proc expression_parenthesis (state :var State; node :PNode) :astTF.Id=
  if node.safeLen == 1 and node[0].kind != nkExprColonExpr:
    let inner_id = state.expression(node[0])
    return state.ast.add_expression(astTF.Expression(
      kind: astTF.eGroup,
      group: astTF.ExpressionGroup(inner: inner_id),
    ))
  return state.expression_tuple(node)

proc expression_obj_constr (state :var State; node :PNode) :astTF.Id=
  var first_field = none(astTF.Id)
  var previous_field = none(astTF.Id)
  for i in 1 ..< node.safeLen:
    let child = node[i]
    if child.kind != nkExprColonExpr or child.safeLen < 2: continue
    let name_loc = state.name_add(child[0].name())
    let value_id = state.expression(child[1])
    let binding = astTF.Binding(
      name: some(astTF.Identifier(location: name_loc)),
      value: some(value_id),
    )
    let binding_id = state.ast.add_binding(binding)
    if first_field.isNone:
      first_field = some(binding_id)
    if previous_field.isSome:
      var prev = state.ast.binding(previous_field.get)
      prev.next = some(binding_id)
      state.ast.data.bindings.get[previous_field.get] = prev
    previous_field = some(binding_id)
  if node[0].kind != nkEmpty:
    let function_id = state.expression(node[0])
    return state.ast.add_expression(astTF.Expression(
      kind: astTF.eCall,
      call: astTF.ExpressionCall(
        name: function_id,
        arguments: first_field,
      ),
    ))
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eObject,
    `object`: astTF.ExpressionObject(
      fields: first_field.get,
    ),
  ))

proc expression_prefix (state :var State; node :PNode) :astTF.Id=
  let operator_node = node[0]
  let right_node = node[1]
  # `@as(T, val)` parses as nkPrefix(@, nkPrefix(as, nkTupleConstr)) because `as`
  # is a Nim keyword. Lower the `as(...)` part to a call so it renders `as(T, val)`,
  # which the surrounding `@` affix wraps into the Zig builtin `@as(T, val)`.
  if operator_node.name() == "as" and right_node.kind in {nkTupleConstr, nkPar}:
    var call_node = newNodeI(nkCall, node.info)
    call_node.add operator_node
    for argument_index in 0 ..< right_node.safeLen:
      call_node.add right_node[argument_index]
    return state.expression_call(call_node)
  let operator_loc = state.name_add(operator_node.name())
  let right_id = state.expression(right_node)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      right: some(right_id),
      operator: operator_loc,
    ),
  ))

proc expression_deref (state :var State; node :PNode) :astTF.Id=
  let object_id = state.expression(node[0])
  let operator_loc = state.name_add(".*")
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      left: some(object_id),
      operator: operator_loc,
    ),
  ))

proc expression_indexed (state :var State; node :PNode) :astTF.Id=
  let object_node = node[0]
  let index_node = node[1]
  let object_id = state.expression(object_node)
  let index_id = state.expression(index_node)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIndexed,
    indexed: astTF.ExpressionIndexed(
      `object`: object_id,
      index: index_id,
    ),
  ))

proc expression_array_type (state :var State; node :PNode) :astTF.Id=
  state.expression_of_type(state.type_node_to_type_id(node))


proc expression_try (state :var State; node :PNode) :astTF.Id=
  let body        = node[0]
  let inner       = if body.kind == nkStmtList and body.safeLen > 0: body[0] else: body
  let value_id    = state.expression(inner)
  let keyword_loc = state.name_add("try")
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eKeyword,
    keyword: astTF.ExpressionKeyword(
      keyword: astTF.Identifier(location: keyword_loc),
      value: some(value_id),
    ),
  ))


proc expression_type_block (state :var State; node :PNode) :astTF.Id=
  ## `block @keyword: <decls>` builds eKeyword(keyword) + eBlock(statement list).
  let body_list  = node[1]
  let head       = body_list[0]
  let keyword_loc = state.name_add(head[1].name())
  discard state.scope_push()

  let saved_previous = state.previous_stmt
  state.previous_stmt = none(astTF.Id)
  var first_stmt = none(astTF.Id)

  proc chain_stmt (state :var State; statement_id :astTF.Id) =
    if first_stmt.isNone:
      first_stmt = some(statement_id)
    if state.previous_stmt.isSome:
      let previous_id = state.previous_stmt.get
      var previous = state.ast.statement(previous_id)
      case previous.kind
      of astTF.sVariable:    previous.variable.next = some(statement_id)
      of astTF.sProcedure:   previous.procedure.next = some(statement_id)
      of astTF.sExpression:  previous.expression.next = some(statement_id)
      of astTF.sImport:      previous.`import`.next = some(statement_id)
      of astTF.sComment:     previous.comment.next = some(statement_id)
      of astTF.sPassthrough: previous.passthrough.next = some(statement_id)
      else: discard
      state.ast.data.statements.get[previous_id] = previous
    state.previous_stmt = some(statement_id)

  if head.safeLen > 2:
    for section in head[2]:
      if section.kind == nkFromStmt:
        let is_module = section[0].include_is_global()
        let raw_name = section[0].include_path()
        if raw_name.len == 0: continue
        let module_name = if state.target == Language.Zig: resolve_import_path(raw_name, is_module)
                          else: raw_name
        let path_loc = state.name_add(module_name)
        let path_id = state.ast.add_expression(astTF.Expression(
          kind: astTF.eLiteral,
          literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.string, value: path_loc),
        ))
        let import_loc = state.name_add("@import")
        let import_name_id = state.ast.add_expression(astTF.Expression(
          kind: astTF.eIdentifier,
          identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: import_loc)),
        ))
        let arg_binding_id = state.ast.add_binding(astTF.Binding(value: some(path_id)))
        let import_call_id = state.ast.add_expression(astTF.Expression(
          kind: astTF.eCall,
          call: astTF.ExpressionCall(name: import_name_id, arguments: some(arg_binding_id)),
        ))
        for symbol_index in 1 ..< section.safeLen:
          let child = section[symbol_index]
          var symbol_name :string
          var alias_name :string
          if child.kind == nkInfix and child[0].name() == "as":
            symbol_name = child[1].symbol_path()
            alias_name = child[2].symbol_path()
          else:
            symbol_name = child.symbol_path()
          if symbol_name.len == 0: continue
          let symbol_loc = state.name_add(symbol_name)
          let symbol_id = state.ast.add_expression(astTF.Expression(
            kind: astTF.eIdentifier,
            identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: symbol_loc)),
          ))
          let dot_loc = state.name_add(".")
          let dot_id = state.ast.add_expression(astTF.Expression(
            kind: astTF.eAffix,
            affix: astTF.ExpressionAffix(
              left: some(import_call_id),
              right: some(symbol_id),
              operator: dot_loc,
            ),
          ))
          let binding_name = if alias_name.len > 0: alias_name else: symbol_name
          let member_loc = state.name_add(binding_name)
          let depth_id = some(state.make_depth(child))
          let binding_id = state.ast.add_binding(astTF.Binding(
            name    : some(astTF.Identifier(location: member_loc)),
            private : some(false),
            value   : some(dot_id),
          ))
          let stmt_id = state.ast.add_statement(astTF.Statement(
            kind: astTF.sVariable,
            variable: astTF.StatementVariable(id: binding_id, depth: depth_id),
          ))
          state.chain_stmt(stmt_id)
        continue
      if section.kind in {nkProcDef, nkFuncDef}:
        if section[0].name().len > 0:
          let procedure_id = state.procedure_build(section)
          let depth_id = some(state.make_depth(section))
          let stmt_id = state.ast.add_statement(astTF.Statement(
            kind: astTF.sProcedure,
            procedure: astTF.StatementProcedure(id: procedure_id, depth: depth_id),
          ))
          state.chain_stmt(stmt_id)
        continue
      if section.kind notin {nkVarSection, nkLetSection, nkConstSection}: continue
      let is_mutable = section.kind == nkVarSection
      let is_runtime = section.kind == nkLetSection
      for definition in section:
        if definition.kind notin {nkIdentDefs, nkConstDef}: continue
        let type_node  = definition[^2]
        let value_node = definition[^1]
        let name_count = definition.safeLen - 2
        var data_type = none(astTF.Id)
        if type_node.kind != nkEmpty:
          data_type = some(state.expression_type(type_node))
        var value = none(astTF.Id)
        if value_node.kind != nkEmpty:
          value = some(state.expression(value_node))
        for name_index in 0 ..< name_count:
          let name_node = definition[name_index]
          let name_str  = name_node.name()
          if name_str.len == 0: continue
          let member_loc = state.name_add(name_str)
          let depth_id = some(state.make_depth(name_node))
          let binding_id = state.ast.add_binding(astTF.Binding(
            name     : some(astTF.Identifier(location: member_loc)),
            private  : some(state.declaration_private(name_node)),
            mutable  : some(is_mutable),
            runtime  : some(is_runtime),
            dataType : data_type,
            value    : value,
          ))
          let stmt_id = state.ast.add_statement(astTF.Statement(
            kind: astTF.sVariable,
            variable: astTF.StatementVariable(id: binding_id, depth: depth_id),
          ))
          state.chain_stmt(stmt_id)

  state.scope_pop()
  state.previous_stmt = saved_previous

  var block_expr = astTF.Expression(kind: astTF.eBlock)
  block_expr.`block`.body = first_stmt
  let block_id = state.ast.add_expression(block_expr)
  state.ast.add_expression(astTF.Expression(
    kind    : astTF.eKeyword,
    keyword : astTF.ExpressionKeyword(
      keyword : astTF.Identifier(location: keyword_loc),
      value   : some(block_id),
    ),
  ))


proc procedure_build (state :var State; node :PNode) :astTF.Id=
  let name_node = node[0]
  let params_node = node[3]

  var name_ident = none(astTF.Identifier)
  let name_str = name_node.name()
  if name_str.len > 0:
    name_ident = some(astTF.Identifier(location: state.name_add(name_str)))

  var is_private = none(bool)
  var is_impure = none(bool)
  if name_ident.isSome:
    is_private = some(state.declaration_private(name_node, node[4]))
    is_impure = some(node.kind != nkFuncDef)

  var first_argument = none(astTF.Id)
  var previous_binding = none(astTF.Id)
  if params_node.kind == nkFormalParams and params_node.safeLen > 1:
    for param_index in 1 ..< params_node.safeLen:
      let param_group = params_node[param_index]
      if param_group.kind != nkIdentDefs: continue
      let type_index = param_group.safeLen - 2
      let type_node = param_group[type_index]
      var param_type = none(astTF.Id)
      if type_node.kind != nkEmpty:
        param_type = some(state.expression_type(type_node))

      for name_index in 0 ..< type_index:
        let param_name_node = param_group[name_index]
        let param_name = param_name_node.name()
        if param_name.len == 0: continue

        let is_last_in_group = name_index == type_index - 1
        let param_name_loc = state.name_add(param_name)
        let param_binding = astTF.Binding(
          name: some(astTF.Identifier(location: param_name_loc)),
          dataType: if is_last_in_group: param_type else: none(astTF.Id),
          private: some(true),
        )
        let binding_id = state.ast.add_binding(param_binding)
        if first_argument.isNone:
          first_argument = some(binding_id)
        if previous_binding.isSome:
          var prev = state.ast.binding(previous_binding.get)
          prev.next = some(binding_id)
          state.ast.data.bindings.get[previous_binding.get] = prev
        previous_binding = some(binding_id)

  var return_type = none(astTF.Id)
  if params_node.kind == nkFormalParams and params_node.safeLen > 0:
    let return_node = params_node[0]
    if return_node.kind != nkEmpty:
      return_type = some(state.expression_type(return_node))

  var first_pragma = none(astTF.Id)
  var previous_pragma = none(astTF.Id)
  let pragma_node = node[4]
  if pragma_node.kind == nkPragma:
    for pragma_child in pragma_node:
      let key_id = state.expression(pragma_child)
      let pragma_id = state.ast.add_pragma(astTF.Pragma(key: key_id))
      if first_pragma.isNone:
        first_pragma = some(pragma_id)
      if previous_pragma.isSome:
        var prev = state.ast.pragm(previous_pragma.get)
        prev.next = some(pragma_id)
        state.ast.data.pragmas.get[previous_pragma.get] = prev
      previous_pragma = some(pragma_id)

  var body_id = none(astTF.Id)
  let body_node = node[6]
  if body_node.kind != nkEmpty:
    let saved_stack = state.scope_stack
    state.scope_stack = @[0'u64]
    discard state.scope_push()
    body_id = some(state.statement_body(body_node))
    state.scope_pop()
    state.scope_stack = saved_stack

  state.ast.add_procedure(astTF.Procedure(
    name       : name_ident,
    private    : is_private,
    impure     : is_impure,
    arguments  : first_argument,
    returnType : return_type,
    pragmas    : first_pragma,
    body       : body_id,
  ))


proc expression_lambda (state :var State; node :PNode) :astTF.Id=
  let procedure_id = state.procedure_build(node)
  state.ast.add_expression(astTF.Expression(
    kind      : astTF.eProcedure,
    procedure : astTF.ExpressionProcedure(id: procedure_id),
  ))


proc expression (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of nkBlockStmt:
    if node.is_type_block(): return state.expression_type_block(node)
    return state.expression_identifier("")
  of SomeLit:                      state.expression_literal(node)
  of nkSym:
    let name = node.sym.name.s
    if name == "true" or name == "false":
      state.expression_literal_bool(name)
    else:
      state.expression_identifier(node)
  of SomeIdent, nkPostfix:         state.expression_identifier(node)
  of nkDotExpr:                    state.expression_dot(node)
  of nkInfix:                      state.expression_infix(node)
  of nkPrefix:                     state.expression_prefix(node)
  of nkCall, nkCommand:            state.expression_call(node)
  of nkTupleConstr, nkPar:         state.expression_parenthesis(node)
  of nkObjConstr:                  state.expression_obj_constr(node)
  of nkBracket:                    state.expression_array(node)
  of nkTryStmt:                    state.expression_try(node)
  of nkLambda:                     state.expression_lambda(node)
  of nkBracketExpr:
    if node[0].name() == "array":
      state.expression_array_type(node)
    elif node.safeLen == 1:
      state.expression_deref(node)
    else:
      state.expression_indexed(node)
  of nkHiddenStdConv, nkHiddenSubConv:
    if node.safeLen > 1 : state.expression(node[1])
    else                : state.expression_identifier("")
  of nkStmtListExpr:
    for child in node:
      if child.kind != nkEmpty: return state.expression(child)
    state.expression_identifier("")
  else:
    state.expression_identifier(node.name())


#_______________________________________
# @section Statement Chaining
#_____________________________
proc statement_chain (state :var State; statement_id :astTF.Id) =
  if state.ast.data.modules[state.module].body.isNone:
    state.ast.data.modules[state.module].body = some(statement_id)
  elif state.previous_stmt.isSome:
    let previous_id = state.previous_stmt.get
    var previous = state.ast.statement(previous_id)
    case previous.kind
    of astTF.sVariable:    previous.variable.next = some(statement_id)
    of astTF.sProcedure:   previous.procedure.next = some(statement_id)
    of astTF.sComment:     previous.comment.next = some(statement_id)
    of astTF.sPassthrough: previous.passthrough.next = some(statement_id)
    of astTF.sImport:      previous.`import`.next = some(statement_id)
    of astTF.sType:        previous.`type`.next = some(statement_id)
    of astTF.sAlias:       previous.alias.next = some(statement_id)
    of astTF.sExpression:  previous.expression.next = some(statement_id)
    else: discard
    state.ast.data.statements.get[previous_id] = previous
  state.previous_stmt = some(statement_id)


#_______________________________________
# @section Statements
#_____________________________
proc statement_top_level (state :var State; node :PNode)

proc statement_comment (state :var State; node :PNode) =
  let text = node.comment()
  let text_loc = state.name_add(text)
  let kind_loc = state.name_add("##")
  let comment_data = astTF.Comment(
    kind: astTF.Identifier(location: kind_loc),
    text: text_loc,
  )
  let comment_id = state.ast.add_comment(comment_data)
  let statement = astTF.Statement(
    kind: astTF.sComment,
    comment: astTF.StatementComment(id: comment_id),
  )
  let statement_id = state.ast.add_statement(statement)
  state.statement_chain(statement_id)


proc include_path (node :PNode) :string=
  case node.kind
  of nkIdent:    node.ident.s
  of nkSym:      node.sym.name.s
  of nkDotExpr:  node[0].include_path() & "." & node[1].include_path()
  of nkInfix:    node[1].include_path() & "/" & node[2].include_path()
  of nkPrefix:
    let pref = node[0].name()
    if pref == "@": node[1].include_path()
    else: pref & node[1].include_path()
  of nkStrLit..nkTripleStrLit: node.strVal
  else:          ""

proc include_is_global (node :PNode) :bool=
  case node.kind
  of nkPrefix:  node[0].name() == "@"
  of nkDotExpr: node[0].include_is_global()
  of nkInfix:   node[1].include_is_global()
  else:         false

proc include_has_ext (node :PNode) :bool=
  case node.kind
  of nkDotExpr: true
  of nkInfix:   node[2].include_has_ext()
  of nkPrefix:  node[1].include_has_ext()
  else:         false

proc symbol_path (node :PNode) :string=
  case node.kind
  of nkIdent:    node.ident.s
  of nkSym:      node.sym.name.s
  of nkDotExpr:  node[0].symbol_path() & "." & node[1].symbol_path()
  else:          ""

proc has_extension (path :string) :bool=
  var last_slash = -1
  for index in 0 ..< path.len:
    if path[index] == '/': last_slash = index
  let filename = if last_slash >= 0: path[last_slash + 1 .. ^1] else: path
  return '.' in filename

proc resolve_import_path (raw_path :string; is_module :bool) :string=
  if is_module: return raw_path
  var path = raw_path
  if not path.has_extension():
    path = path & ".zig"
  if path.len < 2 or path[0] != '.':
    path = "./" & path
  return path

proc statement_import (state :var State; node :PNode) =
  let keyword_text = case node.kind
    of nkImportStmt:       "import"
    of nkFromStmt:         "from"
    of nkImportExceptStmt: "import"
    of nkIncludeStmt:      "include"
    else:                  "import"
  let keyword_loc = state.name_add(keyword_text)
  let keyword = astTF.Identifier(location: keyword_loc, synthetic: some(true))
  let is_include = node.kind == nkIncludeStmt
  if node.kind == nkFromStmt:
    let is_module = node[0].include_is_global()
    let raw_name = node[0].include_path()
    if raw_name.len == 0: return
    let module_name = if state.target == Language.Zig: resolve_import_path(raw_name, is_module)
                      else: raw_name
    var first_symbol = none(astTF.Id)
    var previous_symbol = none(astTF.Id)
    for index in 1 ..< node.safeLen:
      let child = node[index]
      var symbol_name :string
      var alias_name :string
      if child.kind == nkInfix and child[0].name() == "as":
        symbol_name = child[1].symbol_path()
        alias_name = child[2].symbol_path()
      else:
        symbol_name = child.symbol_path()
      if symbol_name.len == 0: continue
      let name_loc = state.name_add(symbol_name)
      var target = none(astTF.Identifier)
      if alias_name.len > 0:
        let alias_loc = state.name_add(alias_name)
        target = some(astTF.Identifier(location: alias_loc))
      let alias_entry = astTF.Alias(
        name: astTF.Identifier(location: name_loc),
        target: target,
      )
      let alias_id = state.ast.add_alias(alias_entry)
      if first_symbol.isNone:
        first_symbol = some(alias_id)
      if previous_symbol.isSome:
        var prev = state.ast.alias(previous_symbol.get)
        prev.next = some(alias_id)
        state.ast.data.aliases.get[previous_symbol.get] = prev
      previous_symbol = some(alias_id)
    let path_loc = state.name_add(module_name)
    let statement = astTF.Statement(
      kind: astTF.sImport,
      `import`: astTF.StatementImport(
        keyword: some(keyword),
        path: path_loc,
        symbols: first_symbol,
      ),
    )
    let statement_id = state.ast.add_statement(statement)
    state.statement_chain(statement_id)
    return
  for child in node:
    var module_name :string
    var alias_name :string
    var is_global = false
    if is_include and (child.kind in {nkDotExpr, nkInfix, nkPrefix}):
      module_name = child.include_path()
      is_global = child.include_is_global()
      if not is_global and not child.include_has_ext():
        module_name = ""
    else:
      var path_node = child
      if child.kind == nkInfix and child[0].name() == "as":
        path_node = child[1]
        alias_name = child[2].name()
      let is_module = path_node.kind == nkPrefix and path_node[0].name() == "@"
      let raw_name = case path_node.kind
        of nkIdent:  path_node.ident.s
        of nkSym:    path_node.sym.name.s
        of nkInfix:  path_node[1].include_path() & "/" & path_node[2].include_path()
        of nkPrefix: path_node.include_path()
        of nkStrLit..nkTripleStrLit: path_node.strVal
        else:        ""
      module_name = if state.target == Language.Zig: resolve_import_path(raw_name, is_module)
                    else: raw_name
    if module_name.len == 0: continue
    if is_include and state.target == Language.Zig and (is_global or child.include_has_ext()):
      let passthrough_text = if is_global: "include @" & module_name
                             else: "include " & module_name
      let text_loc = state.name_add(passthrough_text)
      let statement = astTF.Statement(
        kind: astTF.sPassthrough,
        passthrough: astTF.StatementPassthrough(location: text_loc),
      )
      let statement_id = state.ast.add_statement(statement)
      state.statement_chain(statement_id)
    else:
      let name_loc = state.name_add(module_name)
      var global_opt = none(bool)
      if is_include: global_opt = some(is_global)
      var alias_ident = none(astTF.Identifier)
      if alias_name.len > 0:
        let alias_loc = state.name_add(alias_name)
        alias_ident = some(astTF.Identifier(location: alias_loc))
      let statement = astTF.Statement(
        kind: astTF.sImport,
        `import`: astTF.StatementImport(
          keyword: some(keyword),
          path: name_loc,
          global: global_opt,
          alias: alias_ident,
        ),
      )
      let statement_id = state.ast.add_statement(statement)
      state.statement_chain(statement_id)


proc variables_from_vartuple (state :var State; definition :PNode; is_mutable, is_runtime :bool; inside_body :bool = false) :seq[astTF.Id]=
  let value_node = definition[^1]
  let name_count = definition.safeLen - 2
  let rhs_is_tuple = value_node.kind in {nkTupleConstr, nkPar}
  for name_index in 0 ..< name_count:
    let name_node = definition[name_index]
    let name_str  = name_node.name()
    if name_str.len == 0: continue
    var value = none(astTF.Id)
    if rhs_is_tuple and name_index < value_node.safeLen:
      value = some(state.expression(value_node[name_index]))
    elif value_node.kind != nkEmpty:
      let object_id = state.expression(value_node)
      let index_loc = state.name_add($name_index)
      let index_id  = state.ast.add_expression(astTF.Expression(
        kind    : astTF.eLiteral,
        literal : astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: index_loc),
      ))
      value = some(state.ast.add_expression(astTF.Expression(
        kind    : astTF.eIndexed,
        indexed : astTF.ExpressionIndexed(`object`: object_id, index: index_id),
      )))
    let binding_id = state.ast.add_binding(astTF.Binding(
      name    : some(astTF.Identifier(location: state.name_add(name_str))),
      private : some(if inside_body: true else: state.declaration_private(name_node)),
      mutable : some(is_mutable),
      runtime : some(is_runtime),
      value   : value,
    ))
    let depth_id = if inside_body: some(state.make_depth(name_node))
                   else: none(astTF.Id)
    result.add state.ast.add_statement(astTF.Statement(
      kind     : astTF.sVariable,
      variable : astTF.StatementVariable(id: binding_id, depth: depth_id),
    ))

proc statement_variable (state :var State; node :PNode) =
  if node.kind notin {nkVarSection, nkLetSection, nkConstSection}: return
  let is_mutable = node.kind == nkVarSection
  let is_runtime = node.kind == nkLetSection

  for definition in node:
    if definition.kind == nkCommentStmt:
      state.statement_comment(definition)
      continue
    if definition.kind == nkVarTuple:
      for statement_id in state.variables_from_vartuple(definition, is_mutable, is_runtime):
        state.statement_chain(statement_id)
      continue
    if definition.kind notin {nkIdentDefs, nkConstDef}: continue
    let type_node = definition[^2]
    let value_node = definition[^1]
    let name_count = definition.safeLen - 2

    var data_type = none(astTF.Id)
    if type_node.kind != nkEmpty:
      data_type = some(state.expression_type(type_node))

    var value = none(astTF.Id)
    if value_node.kind != nkEmpty:
      value = some(state.expression(value_node))

    for name_index in 0 ..< name_count:
      let name_node = definition[name_index]
      let name_str = name_node.name()
      if name_str.len == 0: continue

      let is_private = state.declaration_private(name_node)
      let name_loc = state.name_add(name_str)
      let identifier = astTF.Identifier(location: name_loc)

      var binding_type = data_type
      if binding_type.isNone:
        binding_type = state.type_from_sym(name_node)

      let binding = astTF.Binding(
        name: some(identifier),
        private: some(is_private),
        mutable: some(is_mutable),
        runtime: some(is_runtime),
        dataType: binding_type,
        value: value,
      )
      let binding_id = state.ast.add_binding(binding)
      let statement = astTF.Statement(
        kind: astTF.sVariable,
        variable: astTF.StatementVariable(id: binding_id),
      )
      let statement_id = state.ast.add_statement(statement)
      state.statement_chain(statement_id)


proc statement_keyword (state :var State; node :PNode) :astTF.Id=
  let keyword_str = case node.kind
    of nkReturnStmt: "return"
    of nkBreakStmt:  "break"
    of nkContinueStmt: "continue"
    of nkDiscardStmt: "discard"
    of nkDefer: "defer"
    of nkTryStmt: "try"
    else: "unknown"
  let keyword_loc = state.name_add(keyword_str)
  var value = none(astTF.Id)
  if node.kind == nkReturnStmt and node.safeLen > 0:
    let return_content = node[0]
    if return_content.kind == nkAsgn and return_content.safeLen >= 2:
      value = some(state.expression(return_content[1]))
    elif return_content.kind != nkEmpty:
      value = some(state.expression(return_content))
  elif node.kind == nkDiscardStmt and node.safeLen > 0:
    let discard_content = node[0]
    if discard_content.kind != nkEmpty:
      value = some(state.expression(discard_content))
  elif node.kind in {nkDefer, nkTryStmt} and node.safeLen > 0:
    let body = node[0]
    if body.kind == nkStmtList and body.safeLen > 0:
      value = some(state.expression(body[0]))
    elif body.kind != nkEmpty:
      value = some(state.expression(body))
  let expr_id = state.ast.add_expression(astTF.Expression(
    kind: astTF.eKeyword,
    keyword: astTF.ExpressionKeyword(
      keyword: astTF.Identifier(location: keyword_loc),
      value: value,
    ),
  ))
  let depth_id = some(state.make_depth(node))
  state.ast.add_statement(astTF.Statement(
    kind: astTF.sExpression,
    expression: astTF.StatementExpression(
      id: expr_id,
      depth: depth_id,
    ),
  ))


proc statement_conditional (state :var State; node :PNode) :astTF.Id=
  var main_condition :astTF.Id
  var main_body = none(astTF.Id)
  var first_branch = none(astTF.Id)
  var previous_branch = none(astTF.Id)
  var is_first = true
  for branch_node in node:
    if branch_node.kind == nkElifBranch:
      let condition = state.expression(branch_node[0])
      discard state.scope_push()
      let body_id = some(state.statement_body(branch_node[1]))
      state.scope_pop()
      if is_first:
        main_condition = condition
        main_body = body_id
        is_first = false
      else:
        let branch_depth = some(state.make_depth(branch_node))
        let branch_id = state.ast.add_statement(astTF.Statement(
          kind: astTF.sBranch,
          branch: astTF.StatementBranch(condition: some(condition), body: body_id, depth: branch_depth),
        ))
        if first_branch.isNone: first_branch = some(branch_id)
        if previous_branch.isSome:
          var prev = state.ast.statement(previous_branch.get)
          prev.branch.next = some(branch_id)
          state.ast.data.statements.get[previous_branch.get] = prev
        previous_branch = some(branch_id)
    elif branch_node.kind == nkElse:
      discard state.scope_push()
      let body_id = some(state.statement_body(branch_node[0]))
      state.scope_pop()
      let branch_depth = some(state.make_depth(branch_node))
      let branch_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sBranch,
        branch: astTF.StatementBranch(body: body_id, depth: branch_depth),
      ))
      if first_branch.isNone: first_branch = some(branch_id)
      if previous_branch.isSome:
        var prev = state.ast.statement(previous_branch.get)
        prev.branch.next = some(branch_id)
        state.ast.data.statements.get[previous_branch.get] = prev
      previous_branch = some(branch_id)
  let depth_id = some(state.make_depth(node))
  let cond_expr_id = state.ast.add_expression(astTF.Expression(
    kind: astTF.eConditional,
    conditional: astTF.ExpressionConditional(
      condition: main_condition,
      body: main_body,
      branches: first_branch,
    ),
  ))
  state.ast.add_statement(astTF.Statement(
    kind: astTF.sExpression,
    expression: astTF.StatementExpression(id: cond_expr_id, depth: depth_id),
  ))

proc statement_body (state :var State; node :PNode) :astTF.Id=
  let saved_previous = state.previous_stmt
  state.previous_stmt = none(astTF.Id)
  var first_id = none(astTF.Id)

  proc body_chain (state :var State; statement_id :astTF.Id) =
    if first_id.isNone:
      first_id = some(statement_id)
    elif state.previous_stmt.isSome:
      let previous_id = state.previous_stmt.get
      var previous = state.ast.statement(previous_id)
      case previous.kind
      of astTF.sVariable:   previous.variable.next = some(statement_id)
      of astTF.sExpression: previous.expression.next = some(statement_id)
      else: discard
      state.ast.data.statements.get[previous_id] = previous
    state.previous_stmt = some(statement_id)

  proc body_variable (state :var State; child :PNode) =
    if child.kind notin {nkVarSection, nkLetSection, nkConstSection}: return
    let is_mutable = child.kind == nkVarSection
    let is_runtime = child.kind in {nkVarSection, nkLetSection}
    for definition in child:
      if definition.kind == nkVarTuple:
        for statement_id in state.variables_from_vartuple(definition, is_mutable, is_runtime, inside_body = true):
          state.body_chain(statement_id)
        continue
      if definition.kind notin {nkIdentDefs, nkConstDef}: continue
      let name_node = definition[0]
      let type_node = definition[^2]
      let value_node = definition[^1]
      let name_str = name_node.name()
      if name_str.len == 0: continue
      let name_loc = state.name_add(name_str)
      var data_type = none(astTF.Id)
      if type_node.kind != nkEmpty:
        data_type = some(state.expression_type(type_node))
      else:
        data_type = state.type_from_sym(name_node)
      var value = none(astTF.Id)
      if value_node.kind != nkEmpty:
        value = some(state.expression(value_node))
      let depth_id = some(state.make_depth(name_node))
      let binding_id = state.ast.add_binding(astTF.Binding(
        name: some(astTF.Identifier(location: name_loc)),
        private: some(true),
        mutable: some(is_mutable),
        runtime: some(is_runtime),
        dataType: data_type,
        value: value,
      ))
      let statement_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sVariable,
        variable: astTF.StatementVariable(id: binding_id, depth: depth_id),
      ))
      state.body_chain(statement_id)

  proc body_while (state :var State; child :PNode) :astTF.Id=
    let condition_node = child[0]
    let body_node = child[1]
    let condition_id = state.expression(condition_node)
    discard state.scope_push()
    let loop_body_id = some(state.statement_body(body_node))
    state.scope_pop()
    let depth_id = some(state.make_depth(child))
    let loop_expr_id = state.ast.add_expression(astTF.Expression(
      kind: astTF.eLoop,
      loop: astTF.ExpressionLoop(
        condition: some(condition_id),
        body: loop_body_id,
      ),
    ))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: loop_expr_id, depth: depth_id),
    ))

  proc body_for (state :var State; child :PNode) :astTF.Id=
    let iter_count = child.safeLen - 2
    let iterable_node = child[iter_count]
    let body_node = child[iter_count + 1]
    let iterable_id = state.expression(iterable_node)
    var sentry_id = none(astTF.Id)
    for iter_index in 0 ..< iter_count:
      let iter_node = child[iter_index]
      let iter_name = iter_node.name()
      if iter_name.len == 0: continue
      let name_loc = state.name_add(iter_name)
      let binding_id = state.ast.add_binding(astTF.Binding(
        name: some(astTF.Identifier(location: name_loc)),
        private: some(true),
      ))
      let stmt_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sVariable,
        variable: astTF.StatementVariable(id: binding_id),
      ))
      if sentry_id.isNone: sentry_id = some(stmt_id)
    discard state.scope_push()
    let loop_body_id = some(state.statement_body(body_node))
    state.scope_pop()
    let depth_id = some(state.make_depth(child))
    let loop_expr_id = state.ast.add_expression(astTF.Expression(
      kind: astTF.eLoop,
      loop: astTF.ExpressionLoop(
        sentry: sentry_id,
        condition: some(iterable_id),
        body: loop_body_id,
      ),
    ))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: loop_expr_id, depth: depth_id),
    ))

  proc body_assignment (state :var State; child :PNode) :astTF.Id=
    let left_node = child[0]
    let right_node = child[1]
    let left_id = state.expression(left_node)
    let right_id = state.expression(right_node)
    let assign_loc = state.name_add("=")
    let depth_id = some(state.make_depth(child))
    let affix_id = state.ast.add_expression(astTF.Expression(
      kind: astTF.eAffix,
      affix: astTF.ExpressionAffix(
        left: some(left_id),
        operator: assign_loc,
        right: some(right_id),
      ),
    ))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: affix_id, depth: depth_id),
    ))

  proc body_call (state :var State; child :PNode) :astTF.Id=
    let call_id = state.expression_call(child)
    let depth_id = some(state.make_depth(child))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: call_id, depth: depth_id),
    ))

  proc body_infix (state :var State; child :PNode) :astTF.Id=
    let infix_id = state.expression_infix(child)
    let depth_id = some(state.make_depth(child))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: infix_id, depth: depth_id),
    ))

  proc body_block (state :var State; child :PNode) :astTF.Id=
    let label_node    = child[0]
    let body_node     = child[1]
    discard state.scope_push()
    let block_body_id = case body_node.kind
      of nkEmpty      : none(astTF.Id)
      else            : some(state.statement_body(body_node))
    state.scope_pop()
    var block_expr    = astTF.Expression(kind: astTF.eBlock)
    block_expr.`block`.body = block_body_id
    let block_id      = state.ast.add_expression(block_expr)
    let label_name    = if label_node.kind != nkEmpty: label_node.ident.s else: "_"
    let keyword_loc   = state.name_add("block")
    let label_loc     = state.name_add(label_name)
    let keyword_id    = state.ast.add_expression(astTF.Expression(
      kind            : astTF.eKeyword,
      keyword         : astTF.ExpressionKeyword(
        keyword       : astTF.Identifier(location: keyword_loc),
        label         : some(astTF.Identifier(location: label_loc)),
        value         : some(block_id),),))
    let depth_id      = some(state.make_depth(child))
    state.ast.add_statement(astTF.Statement(
      kind       : astTF.sExpression,
      expression : astTF.StatementExpression(id: keyword_id, depth: depth_id),
    ))

  proc body_case (state :var State; child :PNode) :astTF.Id=
    let subject_id = state.expression(child[0])
    var first_branch = none(astTF.Id)
    var previous_branch = none(astTF.Id)
    for branch_index in 1 ..< child.safeLen:
      let branch_node = child[branch_index]
      var condition = none(astTF.Id)
      var body_id = none(astTF.Id)
      if branch_node.kind == nkOfBranch:
        let body_node = branch_node[branch_node.safeLen - 1]
        discard state.scope_push()
        discard state.scope_push()
        body_id = some(state.statement_body(body_node))
        state.scope_pop()
        state.scope_pop()
        var first_value = none(astTF.Id)
        var previous_value = none(astTF.Id)
        for value_index in 0 ..< branch_node.safeLen - 1:
          let value_id = state.expression(branch_node[value_index])
          if first_value.isNone: first_value = some(value_id)
          if previous_value.isSome:
            state.ast.expression_next_set(previous_value.get, some(value_id))
          previous_value = some(value_id)
        condition = first_value
      elif branch_node.kind == nkElse:
        discard state.scope_push()
        discard state.scope_push()
        body_id = some(state.statement_body(branch_node[0]))
        state.scope_pop()
        state.scope_pop()
      discard state.scope_push()
      let branch_depth = some(state.make_depth(branch_node))
      state.scope_pop()
      let branch_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sBranch,
        branch: astTF.StatementBranch(condition: condition, body: body_id, depth: branch_depth),
      ))
      if first_branch.isNone: first_branch = some(branch_id)
      if previous_branch.isSome:
        var prev = state.ast.statement(previous_branch.get)
        prev.branch.next = some(branch_id)
        state.ast.data.statements.get[previous_branch.get] = prev
      previous_branch = some(branch_id)
    let keyword_loc = state.name_add("switch")
    let depth_id = some(state.make_depth(child))
    let cond_expr_id = state.ast.add_expression(astTF.Expression(
      kind: astTF.eConditional,
      conditional: astTF.ExpressionConditional(
        keyword: some(keyword_loc),
        condition: subject_id,
        branches: first_branch,
      ),
    ))
    state.ast.add_statement(astTF.Statement(
      kind: astTF.sExpression,
      expression: astTF.StatementExpression(id: cond_expr_id, depth: depth_id),
    ))

  proc body_it (state :var State; child :PNode) =
    let name_node     = child[1]
    let lambda_node   = child[2]
    let name_str      = if name_node.kind in {nkStrLit..nkTripleStrLit}: name_node.strVal
                        else: name_node.name()
    let name_lit_loc  = state.name_add(name_str)
    let name_lit_id   = state.ast.add_expression(astTF.Expression(
      kind            : astTF.eLiteral,
      literal         : astTF.ExpressionLiteral(
        kind          : astTF.LiteralKind.string,
        value         : name_lit_loc,),))
    let lambda_id     = state.expression_lambda(lambda_node)
    let lambda_bind   = state.ast.add_binding(astTF.Binding(value: some(lambda_id)))
    let name_bind     = state.ast.add_binding(astTF.Binding(
      value           : some(name_lit_id),
      next            : some(lambda_bind),))
    let it_loc        = state.name_add("it")
    let it_id         = state.ast.add_expression(astTF.Expression(
      kind            : astTF.eIdentifier,
      identifier      : astTF.ExpressionIdentifier(name: astTF.Identifier(location: it_loc)),))
    let call_id       = state.ast.add_expression(astTF.Expression(
      kind            : astTF.eCall,
      call            : astTF.ExpressionCall(
        name          : it_id,
        arguments     : some(name_bind),),))
    let try_loc       = state.name_add("try")
    let try_kw_id     = state.ast.add_expression(astTF.Expression(
      kind            : astTF.eKeyword,
      keyword         : astTF.ExpressionKeyword(
        keyword       : astTF.Identifier(location: try_loc),
        value         : some(call_id),),))
    let depth_id      = some(state.make_depth(child))
    let stmt_id       = state.ast.add_statement(astTF.Statement(
      kind            : astTF.sExpression,
      expression      : astTF.StatementExpression(id: try_kw_id, depth: depth_id),))
    state.body_chain(stmt_id)

  proc body_statement (state :var State; child :PNode) =
    let statement_id = case child.kind
      of nkReturnStmt, nkBreakStmt, nkContinueStmt, nkDiscardStmt, nkDefer, nkTryStmt:
        state.statement_keyword(child)
      of nkIfStmt:
        state.statement_conditional(child)
      of nkWhileStmt:
        state.body_while(child)
      of nkForStmt:
        state.body_for(child)
      of nkAsgn:
        state.body_assignment(child)
      of nkInfix:
        state.body_infix(child)
      of nkBlockStmt:
        state.body_block(child)
      of nkCaseStmt:
        state.body_case(child)
      of nkCall, nkCommand:
        if state.target == Language.Zig and not state.typed and child.is_at_prefix("it"):
          state.body_it(child)
          return
        state.body_call(child)
      of nkVarSection, nkLetSection, nkConstSection:
        state.body_variable(child)
        return
      else:
        return
    state.body_chain(statement_id)

  if node.kind == nkStmtList:
    for child in node:
      state.body_statement(child)
  elif node.kind == nkIfStmt:
    let statement_id = state.statement_conditional(node)
    state.body_chain(statement_id)
  else:
    state.body_statement(node)

  state.previous_stmt = saved_previous
  return first_id.get


proc statement_procedure (state :var State; node :PNode) =
  if node.kind notin {nkProcDef, nkFuncDef}: return
  if node[0].name().len == 0: return

  let procedure_id = state.procedure_build(node)
  let statement_id = state.ast.add_statement(astTF.Statement(
    kind      : astTF.sProcedure,
    procedure : astTF.StatementProcedure(id: procedure_id),
  ))
  state.statement_chain(statement_id)


proc statement_type (state :var State; node :PNode) =
  if node.kind != nkTypeDef: return
  let name_node = node[0]
  let body_node = node[2]
  let name_str = name_node.name()
  if name_str.len == 0: return
  let is_private = state.declaration_private(name_node)
  let name_loc = state.name_add(name_str)
  if body_node.kind == nkObjectTy:
    let rec_list = body_node[2]
    var first_field = none(astTF.Id)
    var previous_field = none(astTF.Id)
    if rec_list.kind == nkRecList:
      for field_def in rec_list:
        if field_def.kind != nkIdentDefs: continue
        let type_index = field_def.safeLen - 2
        let type_node = field_def[type_index]
        var field_type = none(astTF.Id)
        if type_node.kind != nkEmpty:
          field_type = some(state.expression_type(type_node))
        for name_index in 0 ..< type_index:
          let field_name_node = field_def[name_index]
          # A field may carry an `{.alias: X.}` pragma. It is not a data field but a
          # struct-level declaration `const name = X;`, so the name node is wrapped in
          # an nkPragmaExpr and the binding carries the alias value instead of a type.
          let alias_value = field_name_node.alias_pragma_value()
          let field_name_str = field_name_node.name()
          if field_name_str.len == 0: continue
          let field_name_loc = state.name_add(field_name_str)
          let is_last_in_group = name_index == type_index - 1
          var field_binding = astTF.Binding(
            name: some(astTF.Identifier(location: field_name_loc)),
          )
          if alias_value != nil:
            field_binding.value = some(state.expression(alias_value))
            field_binding.private = some(state.declaration_private(field_name_node))
          else:
            field_binding.private = some(state.declaration_private(field_name_node))
            field_binding.dataType = if is_last_in_group: field_type else: none(astTF.Id)
            let default_node = field_def[field_def.safeLen - 1]
            if default_node.kind != nkEmpty:
              field_binding.value = some(state.expression(default_node))
          let field_id = state.ast.add_binding(field_binding)
          if first_field.isNone:
            first_field = some(field_id)
          if previous_field.isSome:
            var prev = state.ast.binding(previous_field.get)
            prev.next = some(field_id)
            state.ast.data.bindings.get[previous_field.get] = prev
          previous_field = some(field_id)
    let type_id = state.ast.add_type(astTF.Type(
      kind: astTF.tObject,
      `object`: astTF.TypeObject(
        name: some(astTF.Identifier(location: name_loc)),
        fields: first_field,
        private: some(is_private),
      ),
    ))
    let statement_id = state.ast.add_statement(astTF.Statement(
      kind: astTF.sType,
      `type`: astTF.StatementType(id: type_id),
    ))
    state.statement_chain(statement_id)
  elif body_node.kind == nkProcTy:
    let params_node = body_node[0]
    var first_argument = none(astTF.Id)
    var previous_binding = none(astTF.Id)
    if params_node.kind == nkFormalParams and params_node.safeLen > 1:
      for param_index in 1 ..< params_node.safeLen:
        let param_group = params_node[param_index]
        if param_group.kind != nkIdentDefs: continue
        let type_index = param_group.safeLen - 2
        let type_node = param_group[type_index]
        var param_type = none(astTF.Id)
        if type_node.kind != nkEmpty:
          param_type = some(state.expression_type(type_node))
        for param_name_index in 0 ..< type_index:
          let param_name_node = param_group[param_name_index]
          let param_name_str = param_name_node.name()
          if param_name_str.len == 0: continue
          let is_last_in_group = param_name_index == type_index - 1
          let param_name_loc = state.name_add(param_name_str)
          let param_binding = astTF.Binding(
            name: some(astTF.Identifier(location: param_name_loc)),
            dataType: if is_last_in_group: param_type else: none(astTF.Id),
          )
          let binding_id = state.ast.add_binding(param_binding)
          if first_argument.isNone:
            first_argument = some(binding_id)
          if previous_binding.isSome:
            var prev = state.ast.binding(previous_binding.get)
            prev.next = some(binding_id)
            state.ast.data.bindings.get[previous_binding.get] = prev
          previous_binding = some(binding_id)
    var return_type = none(astTF.Id)
    if params_node.kind == nkFormalParams and params_node.safeLen > 0:
      let return_node = params_node[0]
      if return_node.kind != nkEmpty:
        return_type = some(state.expression_type(return_node))
    let proc_data = astTF.Procedure(
      name: some(astTF.Identifier(location: name_loc)),
      private: some(is_private),
      arguments: first_argument,
      returnType: return_type,
    )
    let procedure_id = state.ast.add_procedure(proc_data)
    let type_id = state.ast.add_type(astTF.Type(
      kind: astTF.tProcedure,
      procedure: astTF.TypeProcedure(id: procedure_id),
    ))
    let statement_id = state.ast.add_statement(astTF.Statement(
      kind: astTF.sType,
      `type`: astTF.StatementType(id: type_id),
    ))
    state.statement_chain(statement_id)
  else:
    let target_id = state.expression(body_node)
    let type_id = state.ast.add_type(astTF.Type(
      kind: astTF.tAlias,
      alias: astTF.TypeAlias(
        name: some(astTF.Identifier(location: name_loc)),
        target: target_id,
        private: some(is_private),
      ),
    ))
    let statement_id = state.ast.add_statement(astTF.Statement(
      kind: astTF.sType,
      `type`: astTF.StatementType(id: type_id),
    ))
    state.statement_chain(statement_id)


proc statement_passthrough (state :var State; node :PNode) =
  if node.kind != nkPragma or node.safeLen < 1: return
  let child = node[0]
  if child.kind != nkExprColonExpr or child.safeLen < 2: return
  let pragma_name = child[0].name()
  if pragma_name != "emit": return
  var value_node = child[1]
  if value_node.kind == nkArgList and value_node.safeLen > 0:
    value_node = value_node[0]
  let text = case value_node.kind
    of nkStrLit..nkTripleStrLit: value_node.strVal
    else: return
  let text_loc = state.name_add(text)
  let statement = astTF.Statement(
    kind: astTF.sPassthrough,
    passthrough: astTF.StatementPassthrough(location: text_loc),
  )
  let statement_id = state.ast.add_statement(statement)
  state.statement_chain(statement_id)


proc statement_block (state :var State; node :PNode) :void=
  let label_node    = node[0]
  let body_node     = node[1]
  discard state.scope_push()
  let block_body_id = case body_node.kind
    of nkEmpty      : none(astTF.Id)
    else            : some(state.statement_body(body_node))
  state.scope_pop()
  var block_expr    = astTF.Expression(kind: astTF.eBlock)
  block_expr.`block`.body = block_body_id
  let block_id      = state.ast.add_expression(block_expr)
  let label_name    = if label_node.kind != nkEmpty: label_node.name() else: "_"
  let keyword_loc   = state.name_add("block")
  let label_loc     = state.name_add(label_name)
  let keyword_id    = state.ast.add_expression(astTF.Expression(
    kind            : astTF.eKeyword,
    keyword         : astTF.ExpressionKeyword(
      keyword       : astTF.Identifier(location: keyword_loc),
      label         : some(astTF.Identifier(location: label_loc)),
      value         : some(block_id),),))
  let depth_id      = some(state.make_depth(node))
  let statement_id  = state.ast.add_statement(astTF.Statement(
    kind            : astTF.sExpression,
    expression      : astTF.StatementExpression(id: keyword_id, depth: depth_id),
  ))
  state.statement_chain(statement_id)


proc is_at_prefix (node :PNode; prefix :string) :bool=
  node.kind == nkCommand and node.safeLen >= 3 and
    node[0].kind == nkPrefix and node[0].safeLen > 1 and
    node[0][0].name() == "@" and node[0][1].name() == prefix

proc is_at_test (node :PNode) :bool=
  node.is_at_prefix("test") and node[node.safeLen - 1].kind == nkStmtList

proc statement_test (state :var State; node :PNode) :void=
  let name_node     = node[1]
  let body_node     = node[node.safeLen - 1]
  discard state.scope_push()
  let block_body_id = case body_node.kind
    of nkEmpty      : none(astTF.Id)
    else            : some(state.statement_body(body_node))
  state.scope_pop()
  var block_expr    = astTF.Expression(kind: astTF.eBlock)
  block_expr.`block`.body = block_body_id
  let block_id      = state.ast.add_expression(block_expr)
  let test_name     = if name_node.kind in {nkStrLit..nkTripleStrLit}: "\"" & name_node.strVal & "\""
                      else: name_node.name()
  let keyword_loc   = state.name_add("test")
  let label_loc     = state.name_add(test_name)
  let keyword_id    = state.ast.add_expression(astTF.Expression(
    kind            : astTF.eKeyword,
    keyword         : astTF.ExpressionKeyword(
      keyword       : astTF.Identifier(location: keyword_loc),
      label         : some(astTF.Identifier(location: label_loc)),
      value         : some(block_id),),))
  let depth_id      = some(state.make_depth(node))
  let statement_id  = state.ast.add_statement(astTF.Statement(
    kind            : astTF.sExpression,
    expression      : astTF.StatementExpression(id: keyword_id, depth: depth_id),
  ))
  state.statement_chain(statement_id)

proc statement_describe (state :var State; node :PNode) :void=
  let var_name_node   = node[1]
  let desc_node       = node[2]
  let body_node       = node[node.safeLen - 1]
  let var_name        = var_name_node.name()
  let desc_str        = if desc_node.kind in {nkStrLit..nkTripleStrLit}: desc_node.strVal
                        else: desc_node.name()

  # var Name = t.describe("description");
  let var_name_loc    = state.name_add(var_name)
  let t_loc           = state.name_add("t")
  let describe_loc    = state.name_add("describe")
  let t_id            = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: t_loc)),))
  let describe_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: describe_loc)),))
  let dot_loc         = state.name_add(".")
  let dot_id          = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eAffix,
    affix             : astTF.ExpressionAffix(
      left            : some(t_id),
      operator        : dot_loc,
      right           : some(describe_id),),))
  let desc_loc        = state.name_add(desc_str)
  let desc_lit_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eLiteral,
    literal           : astTF.ExpressionLiteral(
      kind            : astTF.LiteralKind.string,
      value           : desc_loc,),))
  let desc_bind_id    = state.ast.add_binding(astTF.Binding(value: some(desc_lit_id)))
  let call_id         = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eCall,
    call              : astTF.ExpressionCall(
      name            : dot_id,
      arguments       : some(desc_bind_id),),))
  let binding_id      = state.ast.add_binding(astTF.Binding(
    name              : some(astTF.Identifier(location: var_name_loc)),
    private           : some(false),
    mutable           : some(true),
    runtime           : some(true),
    value             : some(call_id),))
  let var_stmt_id     = state.ast.add_statement(astTF.Statement(
    kind              : astTF.sVariable,
    variable          : astTF.StatementVariable(id: binding_id),))
  state.statement_chain(var_stmt_id)

  # test Name { Name.begin(); defer Name.end(); ...body... }
  discard state.scope_push()
  let saved_previous  = state.previous_stmt
  state.previous_stmt = none(astTF.Id)
  var first_inner     = none(astTF.Id)

  # Name.begin()
  let begin_name_loc  = state.name_add(var_name)
  let begin_name_id   = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: begin_name_loc)),))
  let begin_loc       = state.name_add("begin")
  let begin_fn_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: begin_loc)),))
  let begin_dot_loc   = state.name_add(".")
  let begin_dot_id    = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eAffix,
    affix             : astTF.ExpressionAffix(
      left            : some(begin_name_id),
      operator        : begin_dot_loc,
      right           : some(begin_fn_id),),))
  let begin_call_id   = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eCall,
    call              : astTF.ExpressionCall(name: begin_dot_id),))
  let begin_depth_id  = some(state.make_depth(node))
  let begin_stmt_id   = state.ast.add_statement(astTF.Statement(
    kind              : astTF.sExpression,
    expression        : astTF.StatementExpression(id: begin_call_id, depth: begin_depth_id),))
  first_inner = some(begin_stmt_id)
  state.previous_stmt = some(begin_stmt_id)

  # defer Name.end()
  let end_name_loc    = state.name_add(var_name)
  let end_name_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: end_name_loc)),))
  let end_loc         = state.name_add("end")
  let end_fn_id       = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eIdentifier,
    identifier        : astTF.ExpressionIdentifier(name: astTF.Identifier(location: end_loc)),))
  let end_dot_loc     = state.name_add(".")
  let end_dot_id      = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eAffix,
    affix             : astTF.ExpressionAffix(
      left            : some(end_name_id),
      operator        : end_dot_loc,
      right           : some(end_fn_id),),))
  let end_call_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eCall,
    call              : astTF.ExpressionCall(name: end_dot_id),))
  let defer_loc       = state.name_add("defer")
  let defer_kw_id     = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eKeyword,
    keyword           : astTF.ExpressionKeyword(
      keyword         : astTF.Identifier(location: defer_loc),
      value           : some(end_call_id),),))
  let defer_depth_id  = some(state.make_depth(node))
  let defer_stmt_id   = state.ast.add_statement(astTF.Statement(
    kind              : astTF.sExpression,
    expression        : astTF.StatementExpression(id: defer_kw_id, depth: defer_depth_id),))
  var prev_begin      = state.ast.statement(begin_stmt_id)
  prev_begin.expression.next = some(defer_stmt_id)
  state.ast.data.statements.get[begin_stmt_id] = prev_begin
  state.previous_stmt = some(defer_stmt_id)

  # Append user body statements
  if body_node.kind == nkStmtList:
    for child in body_node:
      let child_stmt_id = state.statement_body(child)
      var prev_stmt = state.ast.statement(state.previous_stmt.get)
      case prev_stmt.kind
      of astTF.sExpression: prev_stmt.expression.next = some(child_stmt_id)
      else: discard
      state.ast.data.statements.get[state.previous_stmt.get] = prev_stmt
      state.previous_stmt = some(child_stmt_id)

  state.scope_pop()
  state.previous_stmt = saved_previous

  # Wrap in test keyword block
  var block_expr      = astTF.Expression(kind: astTF.eBlock)
  block_expr.`block`.body = first_inner
  let block_id        = state.ast.add_expression(block_expr)
  let test_kw_loc     = state.name_add("test")
  let test_label_loc  = state.name_add(var_name)
  let test_kw_id      = state.ast.add_expression(astTF.Expression(
    kind              : astTF.eKeyword,
    keyword           : astTF.ExpressionKeyword(
      keyword         : astTF.Identifier(location: test_kw_loc),
      label           : some(astTF.Identifier(location: test_label_loc)),
      value           : some(block_id),),))
  let test_depth_id   = some(state.make_depth(node))
  let test_stmt_id    = state.ast.add_statement(astTF.Statement(
    kind              : astTF.sExpression,
    expression        : astTF.StatementExpression(id: test_kw_id, depth: test_depth_id),))
  state.statement_chain(test_stmt_id)


proc statement_top_level (state :var State; node :PNode) =
  if node == nil: return
  if state.target == Language.Zig and not state.typed:
    if node.is_at_test():
      state.statement_test(node)
      return
    if node.is_at_prefix("describe") and node[node.safeLen - 1].kind == nkStmtList:
      state.statement_describe(node)
      return
  case node.kind
  of nkProcDef, nkFuncDef:
    state.statement_procedure(node)
  of nkVarSection, nkLetSection, nkConstSection:
    state.statement_variable(node)
  of nkCommentStmt:
    state.statement_comment(node)
  of nkImportStmt, nkFromStmt, nkImportExceptStmt, nkIncludeStmt:
    state.statement_import(node)
  of nkTypeDef:
    state.statement_type(node)
  of nkTypeSection:
    for child in node:
      if child.kind == nkTypeDef:
        state.statement_type(child)
  of nkPragma:
    state.statement_passthrough(node)
  of nkBlockStmt:
    state.statement_block(node)
  of nkStmtList:
    for child in node:
      state.statement_top_level(child)
  else:
    discard


#_______________________________________
# @section Entry Point
#_____________________________
proc convert *(
    root   : PNode;
    target : Language = Language.Nim;
    typed  : bool     = true;
    path   : string   = "input.nim";
  ) :astTF.Ast=
  var state = State(
    ast           : astTF.Ast(root: 0, data: astTF.AstData(modules: @[])),
    source        : "",
    previous_stmt : none(astTF.Id),
    target        : target,
    typed         : typed,
    next_scope    : 1,
    scope_stack   : @[0'u64],
  )
  state.module = astTF.Id(state.ast.data.modules.len)
  state.ast.data.modules.add(astTF.Module(path: path, source: ""))

  state.statement_top_level(root)

  if state.target == Language.C and state.typed:
    var first_import = none(astTF.Id)
    var last_import = none(astTF.Id)
    if state.needs.stdbool:
      let path_loc = state.name_add("stdbool.h")
      let import_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sImport,
        `import`: astTF.StatementImport(path: path_loc),
      ))
      if first_import.isNone: first_import = some(import_id)
      if last_import.isSome:
        var prev = state.ast.statement(last_import.get)
        prev.`import`.next = some(import_id)
        state.ast.data.statements.get[last_import.get] = prev
      last_import = some(import_id)
    if state.needs.stdint:
      let path_loc = state.name_add("stdint.h")
      let import_id = state.ast.add_statement(astTF.Statement(
        kind: astTF.sImport,
        `import`: astTF.StatementImport(path: path_loc),
      ))
      if first_import.isNone: first_import = some(import_id)
      if last_import.isSome:
        var prev = state.ast.statement(last_import.get)
        prev.`import`.next = some(import_id)
        state.ast.data.statements.get[last_import.get] = prev
      last_import = some(import_id)
    if first_import.isSome:
      let original_body = state.ast.data.modules[state.module].body
      if original_body.isSome:
        var last = state.ast.statement(last_import.get)
        last.`import`.next = original_body
        state.ast.data.statements.get[last_import.get] = last
      state.ast.data.modules[state.module].body = first_import

  state.ast.data.modules[state.module].source = state.source
  return state.ast

