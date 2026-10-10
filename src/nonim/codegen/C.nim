#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/options import some, none, isSome, isNone, get, Option
from std/strutils import split
import ../ast as astTF
import ./output
import ./base


#_______________________________________
# @section Helpers
#_____________________________
func source (ast :astTF.Ast; module :astTF.Id; location :astTF.Location) :string=
  ast.data.modules[module].source[location.start ..< location.`end`]


const Tab = "  "

#_______________________________________
# @section Expressions
#_____________________________
func expression *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func expression_keyword (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func expression_condition (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0; top_level :bool = false) :void
func statement_branch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func expression_fields (ast :astTF.Ast; module :astTF.Id; first :Option[astTF.Id]; Out :var Output) :void
func type_name (ast :astTF.Ast; module :astTF.Id; expression_id :Option[astTF.Id]; is_const :bool; name :string) :string

func statement_indent (ast :astTF.Ast; stored :Option[astTF.Id]; block_depth :int) :int=
  ## @descr Indentation level of a statement. Falls back to the level of the block that holds it
  ## when the statement stores none of its own.
  if stored.isNone: return block_depth
  result = ast.node_depth(stored)

func expression_identifier (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let name = ast.source(module, expression.identifier.name.location)
  Out.string(module, name, output.Target.definition)

func expression_literal_string_multiline (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr  = ast.data.expressions.get[id].literal
  let lines = ast.source(module, expr.value, false).split("\n")
  for index, line in lines:
    if index > 0: Out.string(module, "\n" & Tab, output.Target.definition)
    let ending = if index < lines.high: "\\n" else: ""
    Out.string(module, "\"" & line & ending & "\"", output.Target.definition)

func expression_literal_string_singleline (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id].literal
  Out.string(module, "\"" & ast.source(module, expr.value) & "\"", output.Target.definition)

func expression_literal_string (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr      = ast.data.expressions.get[id].literal
  let multiline = expr.variant.isSome and ast.source(module, expr.variant.get) in ["\"\"\"", "\\\\", "/**"]
  if multiline: ast.expression_literal_string_multiline(module, id, Out)
  else:         ast.expression_literal_string_singleline(module, id, Out)

func expression_literal (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  if expression.literal.kind == astTF.LiteralKind.nil:
    Out.string(module, "NULL", output.Target.definition)
    return
  let value = ast.source(module, expression.literal.value)
  case expression.literal.kind
  of astTF.LiteralKind.string:
    ast.expression_literal_string(module, id, Out)
  of astTF.LiteralKind.char:
    Out.string(module, "'", output.Target.definition)
    Out.string(module, value, output.Target.definition)
    Out.string(module, "'", output.Target.definition)
  else:
    Out.string(module, value, output.Target.definition)

func translate_operator (operator :string) :string=
  case operator
  of "div": "/"
  of "mod": "%"
  of "and": "&&"
  of "or":  "||"
  of "not": "!"
  of "shl": "<<"
  of "shr": ">>"
  of "xor": "^"
  else: operator

func expression_affix_cast (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  Out.string(module, "(" & ast.type_name(module, expression.affix.right, false, "") & ")(", output.Target.definition)
  ast.expression(module, expression.affix.left.get, Out)
  Out.string(module, ")", output.Target.definition)

func expression_affix (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let operator = ast.source(module, expression.affix.operator)
  if expression.affix.left.isSome and operator in ["as", "@"]:
    ast.expression_affix_cast(module, id, Out)
    return
  let is_prefix = expression.affix.left.isNone
  if expression.affix.left.isSome:
    ast.expression(module, expression.affix.left.get, Out)
    Out.string(module, " ", output.Target.definition)
  Out.string(module, translate_operator(ast.source(module, expression.affix.operator)), output.Target.definition)
  if not is_prefix: Out.string(module, " ", output.Target.definition)
  if expression.affix.right.isSome:
    ast.expression(module, expression.affix.right.get, Out)

func expression_call_tuple (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :bool=
  let name = ast.data.expressions.get[ast.data.expressions.get[id].call.name]
  name.kind == astTF.eIdentifier and ast.source(module, name.identifier.name.location) == "."

func expression_call_constructor (ast :astTF.Ast; id :astTF.Id) :bool=
  let call = ast.data.expressions.get[id].call
  call.arguments.isSome and ast.data.bindings.get[call.arguments.get].name.isSome

func expression_call_builtin (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let name = ast.data.expressions.get[ast.data.expressions.get[id].call.name]
  if name.kind != astTF.eIdentifier: return ""
  let text = ast.source(module, name.identifier.name.location)
  if text.len == 0 or text[0] != '@': return ""
  return text

func expression_call_raw (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :bool=
  let call = ast.data.expressions.get[id].call
  let name = ast.data.expressions.get[call.name]
  if name.kind != astTF.eIdentifier: return false
  if ast.source(module, name.identifier.name.location) != "raw": return false
  if call.arguments.isNone: return false
  let argument = ast.data.bindings.get[call.arguments.get]
  argument.next.isNone and argument.value.isSome and ast.data.expressions.get[argument.value.get].kind == astTF.eLiteral

func expression_call_defined (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :bool=
  let call = ast.data.expressions.get[id].call
  let name = ast.data.expressions.get[call.name]
  if name.kind != astTF.eIdentifier: return false
  if ast.source(module, name.identifier.name.location) != "defined": return false
  if call.arguments.isNone: return false
  let argument = ast.data.bindings.get[call.arguments.get]
  if argument.next.isSome or argument.value.isNone: return false
  let value = ast.data.expressions.get[argument.value.get]
  value.kind == astTF.eLiteral and value.literal.kind == astTF.LiteralKind.string

func expression_call_cast (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let target = ast.data.bindings.get[ast.data.expressions.get[id].call.arguments.get]
  let value  = ast.data.bindings.get[target.next.get]
  Out.string(module, "(" & ast.type_name(module, target.value, false, "") & ")(", output.Target.definition)
  ast.expression(module, value.value.get, Out)
  Out.string(module, ")", output.Target.definition)

func expression_call (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  if ast.expression_call_builtin(module, id) == "@cast":
    ast.expression_call_cast(module, id, Out)
    return
  if ast.expression_call_raw(module, id):
    ast.expression(module, ast.data.bindings.get[expression.call.arguments.get].value.get, Out)
    return
  if ast.expression_call_defined(module, id):
    let value = ast.data.expressions.get[ast.data.bindings.get[expression.call.arguments.get].value.get]
    Out.string(module, "defined(" & ast.source(module, value.literal.value, false) & ")", output.Target.definition)
    return
  if ast.expression_call_tuple(module, id):
    ast.expression_fields(module, expression.call.arguments, Out)
    return
  if ast.expression_call_constructor(id):
    Out.string(module, "(", output.Target.definition)
    ast.expression(module, expression.call.name, Out)
    Out.string(module, ")", output.Target.definition)
    ast.expression_fields(module, expression.call.arguments, Out)
    return
  ast.expression(module, expression.call.name, Out)
  Out.string(module, "(", output.Target.definition)
  if expression.call.arguments.isSome:
    var current = some(expression.call.arguments.get)
    var first = true
    while current.isSome:
      let binding = ast.data.bindings.get[current.get]
      if not first:
        Out.string(module, ", ", output.Target.definition)
      first = false
      if binding.value.isSome:
        ast.expression(module, binding.value.get, Out)
      current = binding.next
  Out.string(module, ")", output.Target.definition)

func expression_loop_header_for (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr   = ast.data.expressions.get[id]
  let range  = ast.data.expressions.get[expr.loop.condition.get]
  assert range.kind == astTF.eAffix, "codegen.C: for loops only support ranges"
  let sentry = ast.data.statements.get[expr.loop.sentry.get].expression.id
  let comparison = if ast.source(module, range.affix.operator) == "..<": " < " else: " <= "
  Out.string(module, "for (size_t ", output.Target.definition)
  ast.expression(module, sentry, Out)
  Out.string(module, " = ", output.Target.definition)
  ast.expression(module, range.affix.left.get, Out)
  Out.string(module, "; ", output.Target.definition)
  ast.expression(module, sentry, Out)
  Out.string(module, comparison, output.Target.definition)
  ast.expression(module, range.affix.right.get, Out)
  Out.string(module, "; ++", output.Target.definition)
  ast.expression(module, sentry, Out)
  Out.string(module, ")", output.Target.definition)

func expression_loop_header_while (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "while ", output.Target.definition)
  if expr.loop.condition.isSome:
    ast.expression_condition(module, expr.loop.condition.get, Out)

func expression_loop (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  if expr.loop.keyword.isNone: ast.expression_loop_header_for(module, id, Out)
  else:                        ast.expression_loop_header_while(module, id, Out)
  Out.string(module, " {\n", output.Target.definition)
  if expr.loop.body.isSome:
    ast.statement_list(module, expr.loop.body.get, Out, depth + 1)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_condition (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  ## @descr Condition of a control flow construct, wrapped in the parentheses that C requires.
  ## A condition that already carries a group writes them itself.
  if ast.data.expressions.get[id].kind == astTF.eGroup:
    ast.expression(module, id, Out)
    return
  Out.string(module, "(", output.Target.definition)
  ast.expression(module, id, Out)
  Out.string(module, ")", output.Target.definition)

func switch_labels (ast :astTF.Ast; module :astTF.Id; condition :Option[astTF.Id]; depth :int; Out :var Output) :void=
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  if condition.isNone:
    Out.string(module, "default:", output.Target.definition)
    return
  var current = condition
  while current.isSome:
    Out.string(module, "case ", output.Target.definition)
    ast.expression(module, current.get, Out)
    Out.string(module, ":", output.Target.definition)
    current = ast.expression_next(current.get)
    if current.isNone: return
    Out.string(module, " /* fall-through */\n", output.Target.definition)
    for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)

func expression_conditional_switch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "switch ", output.Target.definition)
  ast.expression_condition(module, expr.conditional.condition, Out)
  Out.string(module, " {\n", output.Target.definition)
  var current = expr.conditional.branches
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    ast.switch_labels(module, branch.condition, depth + 1, Out)
    Out.string(module, " {\n", output.Target.definition)
    if branch.body.isSome:
      ast.statement_list(module, branch.body.get, Out, depth + 2)
    for indentation in 0 ..< depth + 1: Out.string(module, Tab, output.Target.definition)
    Out.string(module, "} break;\n", output.Target.definition)
    current = branch.next
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_conditional_comptime_body (ast :astTF.Ast; module :astTF.Id; body :Option[astTF.Id]; depth :int; Out :var Output; top_level :bool) :void=
  if body.isNone: return
  if top_level:
    ast.statement_list(module, body.get, Out, depth + 1, top_level)
    return
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "{\n", output.Target.definition)
  ast.statement_list(module, body.get, Out, depth + 1)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_conditional_comptime (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output; top_level :bool) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "#if ", output.Target.definition)
  ast.expression(module, expr.conditional.condition, Out)
  Out.string(module, "\n", output.Target.definition)
  ast.expression_conditional_comptime_body(module, expr.conditional.body, depth, Out, top_level)
  var current = expr.conditional.branches
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
    if branch.condition.isSome:
      Out.string(module, "#elif ", output.Target.definition)
      ast.expression(module, branch.condition.get, Out)
      Out.string(module, "\n", output.Target.definition)
    else:
      Out.string(module, "#else\n", output.Target.definition)
    ast.expression_conditional_comptime_body(module, branch.body, depth, Out, top_level)
    current = branch.next
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "#endif\n", output.Target.definition)

func expression_conditional_runtime (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "if ", output.Target.definition)
  ast.expression_condition(module, expr.conditional.condition, Out)
  Out.string(module, " {\n", output.Target.definition)
  if expr.conditional.body.isSome:
    ast.statement_list(module, expr.conditional.body.get, Out, depth + 1)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}", output.Target.definition)
  if expr.conditional.branches.isSome:
    ast.statement_branch(module, expr.conditional.branches.get, Out)
  else:
    Out.string(module, "\n", output.Target.definition)

func expression_conditional (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output; top_level :bool = false) :void=
  let expr = ast.data.expressions.get[id]
  if expr.conditional.keyword.isSome:
    ast.expression_conditional_switch(module, id, depth, Out)
  elif expr.conditional.runtime == some(false):
    ast.expression_conditional_comptime(module, id, depth, Out, top_level)
  else:
    ast.expression_conditional_runtime(module, id, depth, Out)

func expression_indexed (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  ast.expression(module, expr.indexed.`object`, Out)
  Out.string(module, "[", output.Target.definition)
  ast.expression(module, expr.indexed.index, Out)
  Out.string(module, "]", output.Target.definition)

func expression_group (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  Out.string(module, "(", output.Target.definition)
  var current = some(expression.group.inner)
  while current.isSome:
    ast.expression(module, current.get, Out)
    current = ast.expression_next(current.get)
    if current.isSome: Out.string(module, ", ", output.Target.definition)
  Out.string(module, ")", output.Target.definition)

func expression_fields (ast :astTF.Ast; module :astTF.Id; first :Option[astTF.Id]; Out :var Output) :void=
  Out.string(module, "{", output.Target.definition)
  var current = first
  while current.isSome:
    let field = ast.data.bindings.get[current.get]
    if field.name.isSome:
      Out.string(module, "." & ast.source(module, field.name.get.location) & " = ", output.Target.definition)
    if field.value.isSome: ast.expression(module, field.value.get, Out)
    current = field.next
    if current.isSome: Out.string(module, ", ", output.Target.definition)
  Out.string(module, "}", output.Target.definition)

func expression_array (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  Out.string(module, "{", output.Target.definition)
  var current = ast.data.expressions.get[id].array.elements
  var index   = 0
  while current.isSome:
    let element = ast.array_element(current.get)
    Out.string(module, "[" & $index & "] = ", output.Target.definition)
    ast.expression(module, element.element, Out)
    current = element.next
    index  += 1
    if current.isSome: Out.string(module, ", ", output.Target.definition)
  Out.string(module, "}", output.Target.definition)

func expression_object (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  ast.expression_fields(module, some(ast.data.expressions.get[id].`object`.fields), Out)

func expression_keyword_block (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id].keyword
  Out.string(module, "{", output.Target.definition)
  if expr.label.isSome:
    let label = ast.source(module, expr.label.get.location)
    if label != "_": Out.string(module, " /* " & label & " */", output.Target.definition)
  Out.string(module, "\n", output.Target.definition)
  if expr.value.isSome:
    let inner = ast.data.expressions.get[expr.value.get]
    if inner.kind == astTF.eBlock and inner.`block`.body.isSome:
      ast.statement_list(module, inner.`block`.body.get, Out, depth + 1)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func branch_value (ast :astTF.Ast; id :astTF.Id) :astTF.Id=
  ast.data.statements.get[id].expression.id

func expression_conditional_match (ast :astTF.Ast; module :astTF.Id; subject :astTF.Id; first :astTF.Id; Out :var Output) :void=
  var current = some(first)
  while current.isSome:
    ast.expression(module, subject, Out)
    Out.string(module, " == ", output.Target.definition)
    ast.expression(module, current.get, Out)
    current = ast.expression_next(current.get)
    if current.isSome: Out.string(module, " || ", output.Target.definition)

func expression_conditional_value_case (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id].conditional
  var current = expr.branches
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    if branch.condition.isNone:
      ast.expression(module, ast.branch_value(branch.body.get), Out)
      return
    ast.expression_conditional_match(module, expr.condition, branch.condition.get, Out)
    Out.string(module, " ? ", output.Target.definition)
    ast.expression(module, ast.branch_value(branch.body.get), Out)
    Out.string(module, " : ", output.Target.definition)
    current = branch.next

func expression_conditional_value (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id].conditional
  if expr.keyword.isSome:
    ast.expression_conditional_value_case(module, id, Out)
    return
  ast.expression(module, expr.condition, Out)
  Out.string(module, " ? ", output.Target.definition)
  ast.expression(module, ast.branch_value(expr.body.get), Out)
  var current = expr.branches
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    Out.string(module, " : ", output.Target.definition)
    if branch.condition.isSome:
      ast.expression(module, branch.condition.get, Out)
      Out.string(module, " ? ", output.Target.definition)
    ast.expression(module, ast.branch_value(branch.body.get), Out)
    current = branch.next

func expression *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eIdentifier:  ast.expression_identifier(module, id, Out)
  of astTF.eLiteral:     ast.expression_literal(module, id, Out)
  of astTF.eAffix:       ast.expression_affix(module, id, Out)
  of astTF.eCall:        ast.expression_call(module, id, Out)
  of astTF.eIndexed:     ast.expression_indexed(module, id, Out)
  of astTF.eKeyword:     ast.expression_keyword(module, id, Out)
  of astTF.eGroup:       ast.expression_group(module, id, Out)
  of astTF.eArray:       ast.expression_array(module, id, Out)
  of astTF.eObject:      ast.expression_object(module, id, Out)
  of astTF.eConditional: ast.expression_conditional_value(module, id, Out)
  else: assert false, "codegen.C: unsupported expression kind: " & $expression.kind


#_______________________________________
# @section Types
#_____________________________
func Type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string
func procedure_arguments (ast :astTF.Ast; module :astTF.Id; first :Option[astTF.Id]) :string

func type_spacing (name :string) :string=
  if name.len == 0: return ""
  if name[0] == '*': return name
  return " " & name

func type_const (is_const :bool) :string=
  if is_const: " const" else: ""

func type_length (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eLiteral:    result = ast.source(module, expression.literal.value)
  of astTF.eIdentifier: result = ast.source(module, expression.identifier.name.location)
  else: assert false, "codegen.C: unsupported array length kind: " & $expression.kind
  if result == "_": result = ""

func type_name (ast :astTF.Ast; module :astTF.Id; expression_id :Option[astTF.Id]; is_const :bool; name :string) :string=
  if expression_id.isNone: return "void" & type_spacing(name)
  let expression = ast.data.expressions.get[expression_id.get]
  case expression.kind
  of astTF.eIdentifier:
    result = ast.source(module, expression.identifier.name.location) & type_const(is_const) & type_spacing(name)
  of astTF.eType:
    result = ast.Type(module, expression.`type`.id, is_const, name)
  else: assert false, "codegen.C: unsupported type expression kind: " & $expression.kind

func type_primitive (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let typ = ast.data.types.get[id].primitive
  ast.source(module, typ.name.location) & type_const(is_const) & type_spacing(name)

func type_alias (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let typ = ast.data.types.get[id].alias
  ast.type_name(module, some(typ.target), is_const, name)

func type_pointer (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let typ = ast.data.types.get[id].`ptr`
  if ast.data.types.get[typ.target].kind == astTF.tProcedure:
    return ast.Type(module, typ.target, false, "*" & name)
  ast.Type(module, typ.target, not typ.mutable.get(false), "*" & type_const(is_const) & type_spacing(name))

func type_array (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let typ     = ast.data.types.get[id].array
  let wrapped = if name.len > 0 and name[0] == '*': "(" & name & ")" else: name
  let length  = if typ.length.isNone: "" else: ast.type_length(module, typ.length.get)
  let element_const = is_const or not typ.mutable.get(false)
  ast.Type(module, typ.element, element_const, wrapped & "[" & length & "]")

func type_procedure (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let procedure = ast.data.procedures.get[ast.data.types.get[id].procedure.id]
  let signature = "(" & name & ") (" & ast.procedure_arguments(module, procedure.arguments) & ")"
  ast.type_name(module, procedure.returnType, false, signature)

func Type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; is_const :bool; name :string) :string=
  let typ = ast.data.types.get[id]
  case typ.kind
  of astTF.tPrimitive: result = ast.type_primitive(module, id, is_const, name)
  of astTF.tAlias:     result = ast.type_alias(module, id, is_const, name)
  of astTF.tPtr:       result = ast.type_pointer(module, id, is_const, name)
  of astTF.tArray:     result = ast.type_array(module, id, is_const, name)
  of astTF.tProcedure: result = ast.type_procedure(module, id, is_const, name)
  else: assert false, "codegen.C: unsupported type kind: " & $typ.kind

func type_is_varargs (ast :astTF.Ast; module :astTF.Id; expression_id :Option[astTF.Id]) :bool=
  if expression_id.isNone: return false
  let expression = ast.data.expressions.get[expression_id.get]
  if expression.kind == astTF.eIdentifier:
    return ast.source(module, expression.identifier.name.location) == "varargs"
  if expression.kind != astTF.eType: return false
  let typ = ast.data.types.get[expression.`type`.id]
  if typ.kind != astTF.tPrimitive: return false
  return ast.source(module, typ.primitive.name.location) == "varargs"

func binding_types (ast :astTF.Ast; first :Option[astTF.Id]) :seq[Option[astTF.Id]]=
  var pending = 0
  var scan    = first
  while scan.isSome:
    let binding = ast.data.bindings.get[scan.get]
    scan = binding.next
    if binding.dataType.isNone:
      pending += 1
      continue
    for untyped_index in 0 .. pending: result.add(binding.dataType)
    pending = 0
  for untyped_index in 0 ..< pending: result.add(none(astTF.Id))

func procedure_arguments (ast :astTF.Ast; module :astTF.Id; first :Option[astTF.Id]) :string=
  let types   = ast.binding_types(first)
  var current = first
  var index   = 0
  while current.isSome:
    let binding = ast.data.bindings.get[current.get]
    if index > 0: result.add(", ")
    current = binding.next
    index += 1
    if ast.type_is_varargs(module, types[index - 1]):
      result.add("...")
      continue
    let name = if binding.name.isSome: ast.source(module, binding.name.get.location) else: ""
    result.add(ast.type_name(module, types[index - 1], true, name))

#_______________________________________
# @section Statements
#_____________________________
func expression_undefined (ast :astTF.Ast; module :astTF.Id; id :Option[astTF.Id]) :bool=
  if id.isNone: return false
  let expression = ast.data.expressions.get[id.get]
  expression.kind == astTF.eIdentifier and ast.source(module, expression.identifier.name.location) == "_"

func statement_variable (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  let statement = ast.data.statements.get[id]
  let binding = ast.data.bindings.get[statement.variable.id]

  let is_mutable = binding.mutable.get(false)
  let is_private = binding.private.get(true)

  let depth = ast.statement_indent(statement.variable.depth, block_depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)

  if is_private and depth == 0:
    Out.string(module, "static ", output.Target.definition)

  let name = if binding.name.isSome: ast.source(module, binding.name.get.location) else: ""
  Out.string(module, ast.type_name(module, binding.dataType, not is_mutable, name), output.Target.definition)

  if binding.value.isSome and not ast.expression_undefined(module, binding.value):
    Out.string(module, " = ", output.Target.definition)
    let value = ast.data.expressions.get[binding.value.get]
    let is_anonymous = value.kind == astTF.eObject or (value.kind == astTF.eCall and ast.expression_call_tuple(module, binding.value.get))
    if is_anonymous and binding.dataType.isSome:
      Out.string(module, "(" & ast.type_name(module, binding.dataType, false, "") & ")", output.Target.definition)
    ast.expression(module, binding.value.get, Out)

  Out.string(module, ";\n", output.Target.definition)


func procedure_pragmas (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let procedure = ast.data.procedures.get[id]
  var current = procedure.pragmas
  while current.isSome:
    let pragma = ast.pragm(current.get)
    let key    = ast.source(module, ast.data.expressions.get[pragma.key].identifier.name.location)
    case key
    of "inline", "extern":
      Out.string(module, key & " ", output.Target.definition)
    else: discard
    current = pragma.next

func statement_procedure (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let procedure = ast.data.procedures.get[statement.procedure.id]

  let is_private = procedure.private.get(true)

  if is_private:
    Out.string(module, "static ", output.Target.definition)
  ast.procedure_pragmas(module, statement.procedure.id, Out)

  let name = if procedure.name.isSome: ast.source(module, procedure.name.get.location) else: ""
  Out.string(module, ast.type_name(module, procedure.returnType, false, name), output.Target.definition)

  Out.string(module, " (", output.Target.definition)
  Out.string(module, ast.procedure_arguments(module, procedure.arguments), output.Target.definition)

  if procedure.body.isSome:
    Out.string(module, ") {\n", output.Target.definition)
    ast.statement_list(module, procedure.body.get, Out)
    Out.string(module, "}\n", output.Target.definition)
  else:
    Out.string(module, ");\n", output.Target.definition)


func expression_keyword (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  let keyword = ast.source(module, expr.keyword.keyword.location)
  if keyword == "discard":
    Out.string(module, "(void)(", output.Target.definition)
    if expr.keyword.value.isSome:
      ast.expression(module, expr.keyword.value.get, Out)
    Out.string(module, ")", output.Target.definition)
  else:
    Out.string(module, keyword, output.Target.definition)
    if expr.keyword.value.isSome:
      Out.string(module, " ", output.Target.definition)
      ast.expression(module, expr.keyword.value.get, Out)


func statement_type_object (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; name :string; Out :var Output) :void=
  let obj = ast.data.types.get[id].`object`
  if ast.pragma_has(module, obj.pragmas, ["stub"]) and obj.link.isSome:
    let parent = ast.link(astTF.Id(obj.link.get.start)).`type`
    Out.string(module, "typedef struct " & ast.Type(module, parent, false, "") & " " & name & ";\n", output.Target.definition)
    return
  Out.string(module, "typedef struct " & name & " {\n", output.Target.definition)
  let first   = ast.data.types.get[id].`object`.fields
  let types   = ast.binding_types(first)
  var current = first
  var index   = 0
  while current.isSome:
    let field = ast.data.bindings.get[current.get]
    let field_name = if field.name.isSome: ast.source(module, field.name.get.location) else: ""
    Out.string(module, Tab & ast.type_name(module, types[index], false, field_name) & ";\n", output.Target.definition)
    current = field.next
    index  += 1
  Out.string(module, "} " & name & ";\n", output.Target.definition)

func statement_type_enum (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; name :string; Out :var Output) :void=
  Out.string(module, "typedef enum " & name & " {\n", output.Target.definition)
  var current = ast.data.types.get[id].enumeration.values
  while current.isSome:
    let value = ast.data.bindings.get[current.get]
    Out.string(module, Tab, output.Target.definition)
    if value.name.isSome:
      Out.string(module, ast.source(module, value.name.get.location), output.Target.definition)
    if value.value.isSome:
      Out.string(module, " = ", output.Target.definition)
      ast.expression(module, value.value.get, Out)
    Out.string(module, ",\n", output.Target.definition)
    current = value.next
  Out.string(module, "} " & name & ";\n", output.Target.definition)

func statement_type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let type_id = ast.data.statements.get[id].`type`.id
  let name    = base.type_name(ast, module, type_id)
  case ast.data.types.get[type_id].kind
  of astTF.tObject:      ast.statement_type_object(module, type_id, name, Out)
  of astTF.tEnumeration: ast.statement_type_enum(module, type_id, name, Out)
  else: Out.string(module, "typedef " & ast.Type(module, type_id, false, name) & ";\n", output.Target.definition)


func statement_discard_bare (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :bool=
  let expr = ast.data.expressions.get[id]
  if expr.kind != astTF.eKeyword: return false
  if ast.source(module, expr.keyword.keyword.location) != "discard": return false
  if expr.keyword.value.isNone: return true
  let value = ast.data.expressions.get[expr.keyword.value.get]
  if value.kind == astTF.eBlock: return true
  return value.kind == astTF.eIdentifier and ast.source(module, value.identifier.name.location) == "_"

func statement_discard_tuple (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :Option[astTF.Id]=
  let expr = ast.data.expressions.get[id]
  if expr.kind != astTF.eKeyword: return none(astTF.Id)
  if ast.source(module, expr.keyword.keyword.location) != "discard": return none(astTF.Id)
  if expr.keyword.value.isNone: return none(astTF.Id)
  let value = ast.data.expressions.get[expr.keyword.value.get]
  if value.kind == astTF.eObject: return some(value.`object`.fields)
  if value.kind == astTF.eCall and ast.expression_call_tuple(module, expr.keyword.value.get): return value.call.arguments
  return none(astTF.Id)

func statement_expression (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0; top_level :bool = false) :void=
  let statement = ast.data.statements.get[id]
  let expr = ast.data.expressions.get[statement.expression.id]
  let depth = ast.statement_indent(statement.expression.depth, block_depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  if expr.kind == astTF.eKeyword and ast.source(module, expr.keyword.keyword.location) == "block":
    ast.expression_keyword_block(module, statement.expression.id, depth, Out)
    return
  if ast.statement_discard_bare(module, statement.expression.id):
    Out.string(module, "{}\n", output.Target.definition)
    return
  var element_id = ast.statement_discard_tuple(module, statement.expression.id)
  if element_id.isSome:
    while element_id.isSome:
      let element = ast.data.bindings.get[element_id.get]
      Out.string(module, "(void)(", output.Target.definition)
      ast.expression(module, element.value.get, Out)
      Out.string(module, ");\n", output.Target.definition)
      element_id = element.next
      if element_id.isSome:
        for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
    return
  case expr.kind
  of astTF.eLoop:        ast.expression_loop(module, statement.expression.id, depth, Out)
  of astTF.eConditional: ast.expression_conditional(module, statement.expression.id, depth, Out, top_level)
  else:
    ast.expression(module, statement.expression.id, Out)
    Out.string(module, ";\n", output.Target.definition)


func statement_import (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).`import`
  let path = ast.source(module, S.path)
  let is_global = S.global.get(true)
  if is_global:
    Out.string(module, "#include <" & path & ">\n", output.Target.definition)
  else:
    Out.string(module, "#include \"" & path & "\"\n", output.Target.definition)

func statement_passthrough (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).passthrough
  Out.string(module, ast.source(module, S.location, false) & "\n", output.Target.definition)

func statement_comment (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).comment
  let C = ast.comment(S.id)
  let kind_text = ast.source(module, C.kind.location, C.kind.synthetic.get(false))
  let prefix = if kind_text == "##" or kind_text == "///" or kind_text == "/**": "/// "
               else: "// "
  let text = ast.source(module, C.text, false)
  var first = true
  for line in text.split("\n"):
    if not first: Out.string(module, "\n", output.Target.definition)
    Out.string(module, prefix & line, output.Target.definition)
    first = false
  Out.string(module, "\n", output.Target.definition)

func statement_pragma (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  let statement = ast.data.statements.get[id]
  let pragma    = ast.pragm(statement.pragma.id)
  if ast.source(module, ast.data.expressions.get[pragma.key].identifier.name.location) != "define": return
  let depth = ast.statement_indent(statement.pragma.depth, block_depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "#define ", output.Target.definition)
  if pragma.value.isNone:
    Out.string(module, "\n", output.Target.definition)
    return
  let value = ast.data.expressions.get[pragma.value.get]
  if value.kind == astTF.eAffix and value.affix.left.isSome and ast.source(module, value.affix.operator) == "->":
    ast.expression(module, value.affix.left.get, Out)
    Out.string(module, " ", output.Target.definition)
    ast.expression(module, value.affix.right.get, Out)
  else:
    ast.expression(module, pragma.value.get, Out)
  Out.string(module, "\n", output.Target.definition)

func statement (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0; top_level :bool = false) :void=
  let statement = ast.data.statements.get[id]
  case statement.kind
  of astTF.sVariable:    ast.statement_variable(module, id, Out, block_depth)
  of astTF.sProcedure:   ast.statement_procedure(module, id, Out)
  of astTF.sType:        ast.statement_type(module, id, Out)
  of astTF.sBranch:      ast.statement_branch(module, id, Out)
  of astTF.sExpression:  ast.statement_expression(module, id, Out, block_depth, top_level)
  of astTF.sImport:      ast.statement_import(module, id, Out)
  of astTF.sPassthrough: ast.statement_passthrough(module, id, Out)
  of astTF.sComment:     ast.statement_comment(module, id, Out)
  of astTF.sPragma:      ast.statement_pragma(module, id, Out, block_depth)
  else:                  assert false, "codegen.C: unsupported statement kind: " & $statement.kind


func statement_branch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  var current = some(id)
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    let depth = ast.node_depth(branch.depth)
    if branch.condition.isSome:
      Out.string(module, " else if ", output.Target.definition)
      ast.expression_condition(module, branch.condition.get, Out)
      Out.string(module, " {\n", output.Target.definition)
    else:
      Out.string(module, " else {\n", output.Target.definition)
    if branch.body.isSome:
      ast.statement_list(module, branch.body.get, Out, depth + 1)
    for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
    Out.string(module, "}", output.Target.definition)
    current = branch.next
  Out.string(module, "\n", output.Target.definition)


func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0; top_level :bool = false) :void=
  var current = some(id)
  while current.isSome:
    let current_id = current.get
    ast.statement(module, current_id, Out, block_depth, top_level)
    let statement = ast.data.statements.get[current_id]
    current = case statement.kind
      of astTF.sVariable:    statement.variable.next
      of astTF.sProcedure:   statement.procedure.next
      of astTF.sComment:     statement.comment.next
      of astTF.sPassthrough: statement.passthrough.next
      of astTF.sImport:      statement.`import`.next
      of astTF.sType:        statement.`type`.next
      of astTF.sAlias:       statement.alias.next
      of astTF.sExpression:  statement.expression.next
      of astTF.sPragma:      statement.pragma.next
      of astTF.sBranch:      none(astTF.Id)
      else:                  none(astTF.Id)


#_______________________________________
# @section Entry Point
#_____________________________
func C *(
    ast    : astTF.Ast;
    target : output.Target = output.Target.definition;
  ) :Output=
  result = Output()
  for index in 0 ..< ast.data.modules.len:
    result.modules.add output.Module(path: ast.data.modules[index].path)
  for index in 0 ..< ast.data.modules.len:
    let module_body = ast.data.modules[index].body
    if module_body.isSome:
      ast.statement_list(astTF.Id(index), module_body.get, result, top_level = true)

