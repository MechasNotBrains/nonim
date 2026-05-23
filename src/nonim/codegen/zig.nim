#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/options import some, none, isSome, isNone, get, Option
from std/strutils import split, endsWith
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
func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func statement_branch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void
func type_name (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string

func expression_identifier (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let name = ast.source(module, expression.identifier.name.location)
  Out.string(module, name, output.Target.definition)

func expression_literal (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  if expression.literal.kind == astTF.LiteralKind.nil:
    Out.string(module, "null", output.Target.definition)
    return
  let value = ast.source(module, expression.literal.value)
  case expression.literal.kind
  of astTF.LiteralKind.string:
    Out.string(module, "\"", output.Target.definition)
    Out.string(module, value, output.Target.definition)
    Out.string(module, "\"", output.Target.definition)
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
  of "shl": "<<"
  of "shr": ">>"
  of "xor": "^"
  else: operator

func expression_affix (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let is_prefix = expression.affix.left.isNone
  let raw_operator = ast.source(module, expression.affix.operator)
  # Prefix `not` is Zig's `!`; an infix `not` (eg. `a not b`) is left untouched.
  let op = if is_prefix and raw_operator == "not": "!"
           else: translate_operator(raw_operator)
  let is_postfix = expression.affix.right.isNone
  let spaced = op != "." and not is_postfix
  if expression.affix.left.isSome:
    ast.expression(module, expression.affix.left.get, Out)
    if spaced: Out.string(module, " ", output.Target.definition)
  Out.string(module, op, output.Target.definition)
  if spaced and not is_prefix: Out.string(module, " ", output.Target.definition)
  if expression.affix.right.isSome:
    ast.expression(module, expression.affix.right.get, Out)

func expression_call (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let name_expr = ast.data.expressions.get[expression.call.name]
  let is_tuple = name_expr.kind == astTF.eIdentifier and
    ast.source(module, name_expr.identifier.name.location) == "."
  let has_named_args = expression.call.arguments.isSome and
    ast.data.bindings.get[expression.call.arguments.get].name.isSome
  let is_constructor = has_named_args and not is_tuple
  let open  = if is_tuple: ".{" elif is_constructor: "{" else: "("
  let close = if is_tuple or is_constructor: "}" else: ")"
  if not is_tuple:
    ast.expression(module, expression.call.name, Out)
  Out.string(module, open, output.Target.definition)
  if expression.call.arguments.isSome:
    var current = some(expression.call.arguments.get)
    var first = true
    while current.isSome:
      let binding = ast.data.bindings.get[current.get]
      if not first:
        Out.string(module, ", ", output.Target.definition)
      first = false
      if binding.name.isSome:
        Out.string(module, ".", output.Target.definition)
        Out.string(module, ast.source(module, binding.name.get.location), output.Target.definition)
        Out.string(module, "= ", output.Target.definition)
      if binding.value.isSome:
        ast.expression(module, binding.value.get, Out)
      current = binding.next
  Out.string(module, close, output.Target.definition)

func expression_indexed (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  ast.expression(module, expr.indexed.`object`, Out)
  Out.string(module, "[", output.Target.definition)
  ast.expression(module, expr.indexed.index, Out)
  Out.string(module, "]", output.Target.definition)

func expression_keyword (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  let keyword = ast.source(module, expr.keyword.keyword.location)
  if keyword == "discard":
    Out.string(module, "_ = ", output.Target.definition)
    if expr.keyword.value.isSome:
      ast.expression(module, expr.keyword.value.get, Out)
  else:
    Out.string(module, keyword, output.Target.definition)
    if expr.keyword.value.isSome:
      Out.string(module, " ", output.Target.definition)
      ast.expression(module, expr.keyword.value.get, Out)

func expression_block (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "{\n", output.Target.definition)
  if expr.`block`.body.isSome:
    ast.statement_list(module, expr.`block`.body.get, Out)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_keyword_block (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  if expr.keyword.label.isSome:
    let label = ast.source(module, expr.keyword.label.get.location)
    if label != "_":
      Out.string(module, label & ": ", output.Target.definition)
  if expr.keyword.value.isSome:
    ast.expression_block(module, expr.keyword.value.get, depth, Out)

func expression_object (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, ".{", output.Target.definition)
  var current = some(expr.`object`.fields)
  var first = true
  while current.isSome:
    let field = ast.data.bindings.get[current.get]
    if not first: Out.string(module, ", ", output.Target.definition)
    if field.name.isSome:
      Out.string(module, ".", output.Target.definition)
      Out.string(module, ast.source(module, field.name.get.location), output.Target.definition)
      Out.string(module, "= ", output.Target.definition)
    if field.value.isSome:
      ast.expression(module, field.value.get, Out)
    first = false
    current = field.next
  Out.string(module, "}", output.Target.definition)

func expression_array (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, ".{", output.Target.definition)
  var current = some(expr.array.elements)
  var first = true
  while current.isSome:
    let element = ast.data.array_elements.get[current.get]
    if not first: Out.string(module, ", ", output.Target.definition)
    ast.expression(module, element.element, Out)
    first = false
    current = element.next
  Out.string(module, "}", output.Target.definition)

func expression_type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  let type_data = ast.data.types.get[expr.`type`.id]
  if type_data.kind != astTF.tObject:
    Out.string(module, ast.type_name(module, expr.`type`.id), output.Target.definition)
    return
  let obj = type_data.`object`
  let keyword = if obj.keyword.isSome: ast.source(module, obj.keyword.get.location) else: "struct"
  Out.string(module, keyword & " {\n", output.Target.definition)
  var current = obj.fields
  while current.isSome:
    let member = ast.data.bindings.get[current.get]
    Out.string(module, Tab, output.Target.definition)
    let is_field = member.dataType.isSome and member.value.isNone
    if is_field:
      if member.name.isSome:
        Out.string(module, ast.source(module, member.name.get.location), output.Target.definition)
      Out.string(module, ": " & ast.type_name(module, member.dataType.get) & ",\n", output.Target.definition)
    else:
      if member.private.isSome and not member.private.get:
        Out.string(module, "pub ", output.Target.definition)
      Out.string(module, (if member.mutable.get(false): "var " else: "const "), output.Target.definition)
      if member.name.isSome:
        Out.string(module, ast.source(module, member.name.get.location), output.Target.definition)
      if member.dataType.isSome:
        Out.string(module, ": " & ast.type_name(module, member.dataType.get), output.Target.definition)
      if member.value.isSome:
        Out.string(module, " = ", output.Target.definition)
        ast.expression(module, member.value.get, Out)
      Out.string(module, ";\n", output.Target.definition)
    current = member.next
  Out.string(module, "}", output.Target.definition)

func expression_group (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  Out.string(module, "(", output.Target.definition)
  ast.expression(module, expression.group.inner, Out)
  Out.string(module, ")", output.Target.definition)

func expression *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eIdentifier: ast.expression_identifier(module, id, Out)
  of astTF.eLiteral:    ast.expression_literal(module, id, Out)
  of astTF.eAffix:      ast.expression_affix(module, id, Out)
  of astTF.eCall:       ast.expression_call(module, id, Out)
  of astTF.eIndexed:    ast.expression_indexed(module, id, Out)
  of astTF.eKeyword:    ast.expression_keyword(module, id, Out)
  of astTF.eObject:     ast.expression_object(module, id, Out)
  of astTF.eArray:      ast.expression_array(module, id, Out)
  of astTF.eGroup:      ast.expression_group(module, id, Out)
  of astTF.eType:       ast.expression_type(module, id, Out)
  else: assert false, "codegen.zig: unsupported expression kind: " & $expression.kind

func expression_loop (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "while (", output.Target.definition)
  if expr.loop.condition.isSome:
    ast.expression(module, expr.loop.condition.get, Out)
  Out.string(module, ") {\n", output.Target.definition)
  if expr.loop.body.isSome:
    ast.statement_list(module, expr.loop.body.get, Out)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_switch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "switch (", output.Target.definition)
  ast.expression(module, expr.conditional.condition, Out)
  Out.string(module, ") {\n", output.Target.definition)
  if expr.conditional.branches.isSome:
    var current = some(expr.conditional.branches.get)
    while current.isSome:
      let branch = ast.data.statements.get[current.get].branch
      let branch_depth = ast.node_depth(branch.depth)
      for indentation in 0 ..< branch_depth: Out.string(module, Tab, output.Target.definition)
      if branch.condition.isSome:
        var value_current = some(branch.condition.get)
        var first_value = true
        while value_current.isSome:
          if not first_value: Out.string(module, ", ", output.Target.definition)
          ast.expression(module, value_current.get, Out)
          first_value = false
          value_current = ast.expression_next(value_current.get)
        Out.string(module, " => {\n", output.Target.definition)
      else:
        Out.string(module, "else => {\n", output.Target.definition)
      if branch.body.isSome:
        ast.statement_list(module, branch.body.get, Out)
      for indentation in 0 ..< branch_depth: Out.string(module, Tab, output.Target.definition)
      Out.string(module, "},\n", output.Target.definition)
      current = branch.next
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_conditional (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  if expr.conditional.keyword.isSome:
    let keyword = ast.source(module, expr.conditional.keyword.get)
    if keyword == "switch":
      ast.expression_switch(module, id, depth, Out)
      return
  Out.string(module, "if (", output.Target.definition)
  ast.expression(module, expr.conditional.condition, Out)
  Out.string(module, ") {\n", output.Target.definition)
  if expr.conditional.body.isSome:
    ast.statement_list(module, expr.conditional.body.get, Out)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}", output.Target.definition)
  if expr.conditional.branches.isSome:
    ast.statement_branch(module, expr.conditional.branches.get, Out)
  else:
    Out.string(module, "\n", output.Target.definition)


#_______________________________________
# @section Type Mapping
#_____________________________

func type_name_identifier (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  result = ast.source(module, expression.identifier.name.location)

func type_render (ast :astTF.Ast; module :astTF.Id; type_id :astTF.Id) :string=
  ## Recursively renders a Type, so nested element/target types resolve:
  ## `[N]T`, `[N][M]T`, `*const T`, `*T`, qualified names, etc.
  let type_data = ast.data.types.get[type_id]
  case type_data.kind
  of astTF.tPrimitive:
    ast.source(module, type_data.primitive.name.location)
  of astTF.tArray:
    let length = if type_data.array.length.isSome:
                   "[" & ast.source(module, ast.data.expressions.get[type_data.array.length.get].literal.value) & "]"
                 else: "[]"
    length & ast.type_render(module, type_data.array.element)
  of astTF.tPtr:
    let target = ast.data.types.get[type_data.`ptr`.target]
    # Pointee mutability lives on the target: immutable -> `*const T`, mutable -> `*T`.
    let mutable = target.kind == astTF.tPrimitive and target.primitive.mutable.get(false)
    (if mutable: "*" else: "*const ") & ast.type_render(module, type_data.`ptr`.target)
  else: "void"

func type_name_type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  result = ast.type_render(module, expression.`type`.id)

func type_name_affix (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  if expression.affix.left.isSome: result.add ast.type_name(module, expression.affix.left.get)
  result.add ast.source(module, expression.affix.operator)
  if expression.affix.right.isSome: result.add ast.type_name(module, expression.affix.right.get)

func type_name_call (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  result.add ast.type_name(module, expression.call.name)
  result.add "("
  if expression.call.arguments.isSome:
    var current = some(expression.call.arguments.get)
    var first = true
    while current.isSome:
      let binding = ast.data.bindings.get[current.get]
      if not first:
        result.add ", "
      first = false
      if binding.value.isSome:
        result.add ast.type_name(module, binding.value.get)
      current = binding.next
  result.add ")"

func type_name_literal (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  ast.source(module, expression.literal.value)

func type_name (ast :astTF.Ast; module :astTF.Id; id :astTF.Id) :string=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eIdentifier : ast.type_name_identifier(module, id)
  of astTF.eType       : ast.type_name_type(module, id)
  of astTF.eAffix      : ast.type_name_affix(module, id)
  of astTF.eCall       : ast.type_name_call(module, id)
  of astTF.eLiteral    : ast.type_name_literal(module, id)
  else                 : "void"


#_______________________________________
# @section Statements
#_____________________________
func statement_variable (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let binding   = ast.data.bindings.get[statement.variable.id]

  let is_mutable = binding.mutable.get(false)
  let is_private = binding.private.get(true)
  let depth      = ast.node_depth(statement.variable.depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)

  if not is_private and depth == 0:
    Out.string(module, "pub ", output.Target.definition)

  case is_mutable
  of on  : Out.string(module, "var ",   output.Target.definition)
  of off : Out.string(module, "const ", output.Target.definition)

  if binding.name.isSome:
    let name = ast.source(module, binding.name.get.location)
    Out.string(module, name, output.Target.definition)

  if binding.dataType.isSome:
    Out.string(module, ": ", output.Target.definition)
    Out.string(module, ast.type_name(module, binding.dataType.get), output.Target.definition)

  if binding.value.isSome:
    Out.string(module, " = ", output.Target.definition)
    ast.expression(module, binding.value.get, Out)

  Out.string(module, ";\n", output.Target.definition)


func statement_procedure (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let procedure = ast.data.procedures.get[statement.procedure.id]

  let is_private = procedure.private.get(true)

  if not is_private:
    Out.string(module, "pub ", output.Target.definition)

  if procedure.pragmas.isSome:
    var current = some(procedure.pragmas.get)
    while current.isSome:
      let pragma = ast.data.pragmas.get[current.get]
      let key_expr = ast.data.expressions.get[pragma.key]
      if key_expr.kind == astTF.eIdentifier:
        let key_text = ast.source(module, key_expr.identifier.name.location)
        if key_text == "inline":
          Out.string(module, "inline ", output.Target.definition)
        elif key_text == "extern":
          Out.string(module, "extern ", output.Target.definition)
      current = pragma.next

  Out.string(module, "fn ", output.Target.definition)

  if procedure.name.isSome:
    let name = ast.source(module, procedure.name.get.location)
    Out.string(module, name, output.Target.definition)

  Out.string(module, " (", output.Target.definition)

  if procedure.arguments.isSome:
    var current = some(procedure.arguments.get)
    var first = true
    var param_types :seq[string]
    var scan = some(procedure.arguments.get)
    var pending_untyped = 0
    while scan.isSome:
      let binding = ast.data.bindings.get[scan.get]
      if binding.dataType.isSome:
        let resolved_type = ast.type_name(module, binding.dataType.get)
        for untyped_index in 0 ..< pending_untyped:
          param_types.add(resolved_type)
        param_types.add(resolved_type)
        pending_untyped = 0
      else:
        pending_untyped += 1
      scan = binding.next
    for untyped_index in 0 ..< pending_untyped:
      param_types.add("i64")

    var param_index = 0
    while current.isSome:
      let binding = ast.data.bindings.get[current.get]
      if not first:
        Out.string(module, ", ", output.Target.definition)
      first = false

      if binding.name.isSome:
        let name = ast.source(module, binding.name.get.location)
        Out.string(module, name, output.Target.definition)

      Out.string(module, ": ", output.Target.definition)
      Out.string(module, param_types[param_index], output.Target.definition)

      current = binding.next
      param_index += 1

  Out.string(module, ") ", output.Target.definition)

  let return_str = if procedure.returnType.isSome: ast.type_name(module, procedure.returnType.get)
                   else: "void"
  Out.string(module, return_str, output.Target.definition)

  if procedure.body.isSome:
    Out.string(module, " {\n", output.Target.definition)
    ast.statement_list(module, procedure.body.get, Out)
    Out.string(module, "}\n", output.Target.definition)
  else:
    Out.string(module, ";\n", output.Target.definition)



func statement_type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let type_data = ast.data.types.get[statement.`type`.id]
  if type_data.kind == astTF.tObject:
    let obj = type_data.`object`
    if obj.private.isSome and not obj.private.get:
      Out.string(module, "pub ", output.Target.definition)
    Out.string(module, "const ", output.Target.definition)
    if obj.name.isSome:
      Out.string(module, ast.source(module, obj.name.get.location), output.Target.definition)
    Out.string(module, " = struct {\n", output.Target.definition)
    if obj.fields.isSome:
      var current = some(obj.fields.get)
      while current.isSome:
        let field = ast.data.bindings.get[current.get]
        Out.string(module, Tab, output.Target.definition)
        if field.value.isSome and field.dataType.isNone:
          # An aliased field is a struct-level declaration, not a data field.
          if field.private.isSome and not field.private.get:
            Out.string(module, "pub ", output.Target.definition)
          Out.string(module, "const ", output.Target.definition)
          if field.name.isSome:
            Out.string(module, ast.source(module, field.name.get.location), output.Target.definition)
          Out.string(module, " = ", output.Target.definition)
          ast.expression(module, field.value.get, Out)
          Out.string(module, ";\n", output.Target.definition)
        else:
          if field.name.isSome:
            Out.string(module, ast.source(module, field.name.get.location), output.Target.definition)
          Out.string(module, ": ", output.Target.definition)
          if field.dataType.isSome:
            Out.string(module, ast.type_name(module, field.dataType.get), output.Target.definition)
          Out.string(module, ",\n", output.Target.definition)
        current = field.next
    Out.string(module, "};\n", output.Target.definition)
  elif type_data.kind == astTF.tProcedure:
    let procedure = ast.data.procedures.get[type_data.procedure.id]
    let is_private = procedure.private.get(true)
    if not is_private:
      Out.string(module, "pub ", output.Target.definition)
    Out.string(module, "const ", output.Target.definition)
    if procedure.name.isSome:
      Out.string(module, ast.source(module, procedure.name.get.location), output.Target.definition)
    Out.string(module, " = *const fn (", output.Target.definition)
    if procedure.arguments.isSome:
      var current = some(procedure.arguments.get)
      var first = true
      var param_types :seq[string]
      var scan = some(procedure.arguments.get)
      var pending_untyped = 0
      while scan.isSome:
        let binding = ast.data.bindings.get[scan.get]
        if binding.dataType.isSome:
          let resolved_type = ast.type_name(module, binding.dataType.get)
          for untyped_index in 0 ..< pending_untyped:
            param_types.add(resolved_type)
          param_types.add(resolved_type)
          pending_untyped = 0
        else:
          pending_untyped += 1
        scan = binding.next
      for untyped_index in 0 ..< pending_untyped:
        param_types.add("i64")
      var param_index = 0
      while current.isSome:
        let binding = ast.data.bindings.get[current.get]
        if not first:
          Out.string(module, ", ", output.Target.definition)
        first = false
        if binding.name.isSome:
          Out.string(module, ast.source(module, binding.name.get.location), output.Target.definition)
        Out.string(module, ": ", output.Target.definition)
        Out.string(module, param_types[param_index], output.Target.definition)
        current = binding.next
        param_index += 1
    Out.string(module, ") ", output.Target.definition)
    let return_str = if procedure.returnType.isSome: ast.type_name(module, procedure.returnType.get)
                     else: "void"
    Out.string(module, return_str, output.Target.definition)
    Out.string(module, ";\n", output.Target.definition)
  elif type_data.kind == astTF.tAlias:
    let alias = type_data.alias
    if alias.private.isSome and not alias.private.get:
      Out.string(module, "pub ", output.Target.definition)
    Out.string(module, "const ", output.Target.definition)
    if alias.name.isSome:
      Out.string(module, ast.source(module, alias.name.get.location), output.Target.definition)
    Out.string(module, " = ", output.Target.definition)
    ast.expression(module, alias.target, Out)
    Out.string(module, ";\n", output.Target.definition)


func statement_expression (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let expr = ast.data.expressions.get[statement.expression.id]
  let depth = ast.node_depth(statement.expression.depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  case expr.kind
  of astTF.eLoop:        ast.expression_loop(module, statement.expression.id, depth, Out)
  of astTF.eConditional: ast.expression_conditional(module, statement.expression.id, depth, Out)
  of astTF.eKeyword:
    let keyword_text = ast.source(module, expr.keyword.keyword.location)
    if keyword_text == "block":
      ast.expression_keyword_block(module, statement.expression.id, depth, Out)
    else:
      ast.expression_keyword(module, statement.expression.id, Out)
      Out.string(module, ";\n", output.Target.definition)
  else:
    ast.expression(module, statement.expression.id, Out)
    Out.string(module, ";\n", output.Target.definition)


func statement_import_from (ast :astTF.Ast; module :astTF.Id; path :string; symbols :astTF.Id; Out :var Output) :void=
  var current = some(symbols)
  while current.isSome:
    let symbol = ast.alias(current.get)
    let symbol_name = ast.source(module, symbol.name.location)
    let symbol_parts = symbol_name.split(".")
    let const_name = if symbol.target.isSome: ast.source(module, symbol.target.get.location)
                     else: symbol_parts[symbol_parts.len - 1]
    Out.string(module, "pub const " & const_name & " = @import(\"" & path & "\")." & symbol_name & ";\n", output.Target.definition)
    current = symbol.next

func statement_import (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).`import`
  let path = ast.source(module, S.path)
  if S.symbols.isSome:
    ast.statement_import_from(module, path, S.symbols.get, Out)
    return
  let parts = path.split("/")
  var name = parts[parts.len - 1]
  if name.endsWith(".zig"): name = name[0 ..< name.len - ".zig".len]
  Out.string(module, "const " & name & " = @import(\"" & path & "\");\n", output.Target.definition)

func statement_passthrough (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).passthrough
  Out.string(module, ast.source(module, S.location, false) & "\n", output.Target.definition)

func statement_comment (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let S = ast.statement(id).comment
  let C = ast.comment(S.id)
  let kind_text = ast.source(module, C.kind.location, C.kind.synthetic.get(false))
  let is_doc = kind_text == "##" or kind_text == "///" or kind_text == "/**"
  let text = ast.source(module, C.text, false)
  var first = true
  for line in text.split("\n"):
    if not first: Out.string(module, "\n", output.Target.definition)
    let prefix = if is_doc and line.len > 0 and line[0] == '!': "//"
                 elif is_doc: "/// "
                 else: "// "
    Out.string(module, prefix & line, output.Target.definition)
    first = false
  Out.string(module, "\n", output.Target.definition)

func statement (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  case statement.kind
  of astTF.sVariable:    ast.statement_variable(module, id, Out)
  of astTF.sProcedure:   ast.statement_procedure(module, id, Out)
  of astTF.sType:        ast.statement_type(module, id, Out)
  of astTF.sBranch:      ast.statement_branch(module, id, Out)
  of astTF.sExpression:  ast.statement_expression(module, id, Out)
  of astTF.sImport:      ast.statement_import(module, id, Out)
  of astTF.sPassthrough: ast.statement_passthrough(module, id, Out)
  of astTF.sComment:     ast.statement_comment(module, id, Out)
  else:                  assert false, "codegen.zig: unsupported statement kind: " & $statement.kind


func statement_branch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  var current = some(id)
  while current.isSome:
    let branch = ast.data.statements.get[current.get].branch
    let depth = ast.node_depth(branch.depth)
    if branch.condition.isSome:
      Out.string(module, " else if (", output.Target.definition)
      ast.expression(module, branch.condition.get, Out)
      Out.string(module, ") {\n", output.Target.definition)
    else:
      Out.string(module, " else {\n", output.Target.definition)
    if branch.body.isSome:
      ast.statement_list(module, branch.body.get, Out)
    for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
    Out.string(module, "}", output.Target.definition)
    current = branch.next
  Out.string(module, "\n", output.Target.definition)


func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  var current = some(id)
  while current.isSome:
    let current_id = current.get
    ast.statement(module, current_id, Out)
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
      of astTF.sBranch:      none(astTF.Id)
      else:                  none(astTF.Id)


#_______________________________________
# @section Entry Point
#_____________________________
func zig *(
    ast    : astTF.Ast;
    target : output.Target = output.Target.definition;
  ) :Output=
  result = Output()
  for index in 0 ..< ast.data.modules.len:
    result.modules.add output.Module(path: ast.data.modules[index].path)
  for index in 0 ..< ast.data.modules.len:
    let module_body = ast.data.modules[index].body
    if module_body.isSome:
      ast.statement_list(astTF.Id(index), module_body.get, result)
