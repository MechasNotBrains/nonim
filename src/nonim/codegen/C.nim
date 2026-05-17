#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/options import some, none, isSome, isNone, get, Option
import ../ast as astTF
import ./output


#_______________________________________
# @section Helpers
#_____________________________
func source (ast :astTF.Ast; module :astTF.Id; location :astTF.Location) :string=
  ast.data.modules[module].source[location.start ..< location.`end`]


#_______________________________________
# @section Expressions
#_____________________________
func expression (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let expression = ast.data.expressions.get[id]
  case expression.kind
  of astTF.eIdentifier:
    let name = ast.source(module, expression.identifier.name.location)
    Out.string(module, name, output.Target.definition)
  of astTF.eLiteral:
    let value = ast.source(module, expression.literal.value)
    Out.string(module, value, output.Target.definition)
  else:
    discard


#_______________________________________
# @section Type Mapping
#_____________________________
func type_name (ast :astTF.Ast; module :astTF.Id; expression_id :astTF.Id) :string=
  let expression = ast.data.expressions.get[expression_id]
  case expression.kind
  of astTF.eIdentifier:
    let nim_type = ast.source(module, expression.identifier.name.location)
    case nim_type
    of "int":     "int"
    of "int8":    "int8_t"
    of "int16":   "int16_t"
    of "int32":   "int32_t"
    of "int64":   "int64_t"
    of "uint":    "unsigned int"
    of "uint8":   "uint8_t"
    of "uint16":  "uint16_t"
    of "uint32":  "uint32_t"
    of "uint64":  "uint64_t"
    of "float":   "double"
    of "float32": "float"
    of "float64": "double"
    of "bool":    "bool"
    of "char":    "char"
    of "string":  "char*"
    of "void":    "void"
    else:         nim_type
  else: "int"


#_______________________________________
# @section Statements
#_____________________________
func statement_variable (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  let binding = ast.data.bindings.get[statement.variable.id]

  let type_str = if binding.dataType.isSome: ast.type_name(module, binding.dataType.get)
                 else: "int"

  let is_mutable = binding.mutable.get(false)
  let is_private = binding.private.get(true)

  if is_private:
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

  let return_str = if procedure.returnType.isSome: ast.type_name(module, procedure.returnType.get)
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
        let resolved_type = ast.type_name(module, binding.dataType.get)
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

      current = binding.next
      param_index += 1

  Out.string(module, ");\n", output.Target.definition)


func statement (ast :astTF.Ast; module :astTF.Id; id :astTF.Id; Out :var Output) :void=
  let statement = ast.data.statements.get[id]
  case statement.kind
  of astTF.sVariable:  ast.statement_variable(module, id, Out)
  of astTF.sProcedure: ast.statement_procedure(module, id, Out)
  else: discard


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

