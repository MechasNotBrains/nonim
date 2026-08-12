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
func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void
func statement_branch (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void

func statement_indent (ast :astTF.Ast; stored :Option[astTF.Id]; block_depth :int) :int=
  ## @descr Indentation level of a statement. Falls back to the level of the block that holds it
  ## when the statement stores none of its own.
  if stored.isNone: return block_depth
  result = ast.node_depth(stored)

func expression_identifier (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let name = ast.source(module, expression.identifier.name.location)
  Out.string(module, name, output.Target.definition)

func expression_literal (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  if expression.literal.kind == astTF.LiteralKind.nil:
    Out.string(module, "NULL", output.Target.definition)
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
  of "and": "&&"
  of "or":  "||"
  of "not": "!"
  of "shl": "<<"
  of "shr": ">>"
  of "xor": "^"
  else: operator

func expression_affix (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  let is_prefix = expression.affix.left.isNone
  if expression.affix.left.isSome:
    ast.expression(module, expression.affix.left.get, Out)
    Out.string(module, " ", output.Target.definition)
  Out.string(module, translate_operator(ast.source(module, expression.affix.operator)), output.Target.definition)
  if not is_prefix: Out.string(module, " ", output.Target.definition)
  if expression.affix.right.isSome:
    ast.expression(module, expression.affix.right.get, Out)

func expression_call (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
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

func expression_loop (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
  let expr = ast.data.expressions.get[id]
  Out.string(module, "while ", output.Target.definition)
  if expr.loop.condition.isSome:
    ast.expression_condition(module, expr.loop.condition.get, Out)
  Out.string(module, " {\n", output.Target.definition)
  if expr.loop.body.isSome:
    ast.statement_list(module, expr.loop.body.get, Out, depth + 1)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  Out.string(module, "}\n", output.Target.definition)

func expression_condition (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  ## @descr Condition of a control flow construct, wrapped in the parentheses that C requires.
  ## A condition that already carries a group spells them itself.
  if ast.data.expressions.get[id].kind == astTF.eGroup:
    ast.expression(module, id, Out)
    return
  Out.string(module, "(", output.Target.definition)
  ast.expression(module, id, Out)
  Out.string(module, ")", output.Target.definition)

func expression_conditional (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; depth :int; Out :var Output) :void=
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

func expression *(ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eIdentifier: ast.expression_identifier(module, id, Out)
  of astTF.eLiteral:    ast.expression_literal(module, id, Out)
  of astTF.eAffix:      ast.expression_affix(module, id, Out)
  of astTF.eCall:       ast.expression_call(module, id, Out)
  of astTF.eIndexed:    ast.expression_indexed(module, id, Out)
  of astTF.eKeyword:    ast.expression_keyword(module, id, Out)
  of astTF.eGroup:      ast.expression_group(module, id, Out)
  else: assert false, "codegen.C: unsupported expression kind: " & $expression.kind


#_______________________________________
# @section Type Mapping
#_____________________________
func type_name (ast :astTF.Ast; module :astTF.Id; expression_id :Option[astTF.Id]) :string=
  if expression_id.isNone: return "void"
  let expression = ast.data.expressions.get[expression_id.get]
  case expression.kind
  of astTF.eIdentifier:
    ast.source(module, expression.identifier.name.location)
  of astTF.eType:
    let type_data = ast.data.types.get[expression.`type`.id]
    case type_data.kind
    of astTF.tPrimitive:
      ast.source(module, type_data.primitive.name.location)
    of astTF.tArray:
      let elem_type = ast.data.types.get[type_data.array.element]
      ast.source(module, elem_type.primitive.name.location)
    of astTF.tPtr:
      let target_type = ast.data.types.get[type_data.`ptr`.target]
      ast.source(module, target_type.primitive.name.location) & "*"
    else: "void"
  else: "void"

func type_suffix (ast :astTF.Ast; module :astTF.Id; expression_id :Option[astTF.Id]) :string=
  if expression_id.isNone: return ""
  let expression = ast.data.expressions.get[expression_id.get]
  if expression.kind != astTF.eType: return ""
  let type_data = ast.data.types.get[expression.`type`.id]
  if type_data.kind != astTF.tArray: return ""
  if type_data.array.length.isNone: return "[]"
  let length_expr = ast.data.expressions.get[type_data.array.length.get]
  return "[" & ast.source(module, length_expr.literal.value) & "]"

#_______________________________________
# @section Statements
#_____________________________
func statement_variable (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  let statement = ast.data.statements.get[id]
  let binding = ast.data.bindings.get[statement.variable.id]

  let type_str = ast.type_name(module, binding.dataType)

  let is_mutable = binding.mutable.get(false)
  let is_private = binding.private.get(true)

  let depth = ast.statement_indent(statement.variable.depth, block_depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)

  if is_private and depth == 0:
    Out.string(module, "static ", output.Target.definition)

  Out.string(module, type_str, output.Target.definition)

  if not is_mutable:
    Out.string(module, " const", output.Target.definition)

  if binding.name.isSome:
    Out.string(module, " ", output.Target.definition)
    let name = ast.source(module, binding.name.get.location)
    Out.string(module, name, output.Target.definition)

  if binding.value.isSome:
    Out.string(module, " = ", output.Target.definition)
    ast.expression(module, binding.value.get, Out)

  Out.string(module, ";\n", output.Target.definition)


func statement_procedure (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let procedure = ast.data.procedures.get[statement.procedure.id]

  let is_private = procedure.private.get(true)

  if is_private:
    Out.string(module, "static ", output.Target.definition)

  let return_str = if procedure.returnType.isSome: ast.type_name(module, procedure.returnType)
                   else: "void"
  Out.string(module, return_str, output.Target.definition)

  if procedure.name.isSome:
    Out.string(module, " ", output.Target.definition)
    let name = ast.source(module, procedure.name.get.location)
    Out.string(module, name, output.Target.definition)

  Out.string(module, " (", output.Target.definition)

  if procedure.arguments.isSome:
    var current = some(procedure.arguments.get)
    var first = true
    var last_type = "int"
    # Pre-scan to find the type for grouped params (only last in group has dataType)
    var param_types: seq[string]
    var scan = some(procedure.arguments.get)
    var pending_untyped = 0
    while scan.isSome:
      let binding = ast.data.bindings.get[scan.get]
      if binding.dataType.isSome:
        let resolved_type = ast.type_name(module, binding.dataType)
        for untyped_index in 0 ..< pending_untyped:
          param_types.add(resolved_type)
        param_types.add(resolved_type)
        pending_untyped = 0
      else:
        pending_untyped += 1
      scan = binding.next
    for untyped_index in 0 ..< pending_untyped:
      param_types.add("int")

    var param_index = 0
    while current.isSome:
      let binding = ast.data.bindings.get[current.get]
      if not first:
        Out.string(module, ", ", output.Target.definition)
      first = false

      Out.string(module, param_types[param_index], output.Target.definition)
      Out.string(module, " const ", output.Target.definition)

      if binding.name.isSome:
        let name = ast.source(module, binding.name.get.location)
        Out.string(module, name, output.Target.definition)

      if binding.dataType.isSome:
        let suffix = ast.type_suffix(module, binding.dataType)
        if suffix.len > 0:
          Out.string(module, suffix, output.Target.definition)

      current = binding.next
      param_index += 1

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


func statement_type (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let type_data = ast.data.types.get[statement.`type`.id]
  if type_data.kind == astTF.tObject:
    let obj = type_data.`object`
    Out.string(module, "typedef struct {\n", output.Target.definition)
    if obj.fields.isSome:
      var current = some(obj.fields.get)
      while current.isSome:
        let field = ast.data.bindings.get[current.get]
        Out.string(module, Tab, output.Target.definition)
        if field.dataType.isSome:
          Out.string(module, ast.type_name(module, field.dataType), output.Target.definition)
          Out.string(module, " ", output.Target.definition)
        if field.name.isSome:
          Out.string(module, ast.source(module, field.name.get.location), output.Target.definition)
        Out.string(module, ";\n", output.Target.definition)
        current = field.next
    Out.string(module, "} ", output.Target.definition)
    if obj.name.isSome:
      Out.string(module, ast.source(module, obj.name.get.location), output.Target.definition)
    Out.string(module, ";\n", output.Target.definition)


func statement_expression (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  let statement = ast.data.statements.get[id]
  let expr = ast.data.expressions.get[statement.expression.id]
  let depth = ast.statement_indent(statement.expression.depth, block_depth)
  for indentation in 0 ..< depth: Out.string(module, Tab, output.Target.definition)
  case expr.kind
  of astTF.eLoop:        ast.expression_loop(module, statement.expression.id, depth, Out)
  of astTF.eConditional: ast.expression_conditional(module, statement.expression.id, depth, Out)
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

func statement (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  let statement = ast.data.statements.get[id]
  case statement.kind
  of astTF.sVariable:    ast.statement_variable(module, id, Out, block_depth)
  of astTF.sProcedure:   ast.statement_procedure(module, id, Out)
  of astTF.sType:        ast.statement_type(module, id, Out)
  of astTF.sBranch:      ast.statement_branch(module, id, Out)
  of astTF.sExpression:  ast.statement_expression(module, id, Out, block_depth)
  of astTF.sImport:      ast.statement_import(module, id, Out)
  of astTF.sPassthrough: ast.statement_passthrough(module, id, Out)
  of astTF.sComment:     ast.statement_comment(module, id, Out)
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


func statement_list (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output; block_depth :int = 0) :void=
  var current = some(id)
  while current.isSome:
    let current_id = current.get
    ast.statement(module, current_id, Out, block_depth)
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
      ast.statement_list(astTF.Id(index), module_body.get, result)

