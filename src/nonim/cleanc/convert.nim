#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________
## Converts the typed Nim PNode AST into astTF data.
## This is the bridge between Nim's compiler internals and slate's codegen.
#_________________________________________________________|
# @deps std
import std/options
# @deps nimc
import "$nim"/compiler/[ast, renderer]
# @deps nonim
import slate/ast as astTF
import slate
# @deps nonim.cleanc
import ../nimc/Typed


type State = object
  ast            :astTF.Ast
  module         :astTF.Id
  source         :string
  previous_stmt  :Option[astTF.Id]


proc add_name(state :var State; name :string) :astTF.Location=
  let start = uint64(state.source.len)
  state.source.add(name)
  let finish = uint64(state.source.len)
  state.ast.data.modules[state.module].source = state.source
  return astTF.Location(start: start, `end`: finish)


proc literal_expression(state :var State; node :PNode) :astTF.Id=
  let value_str = $node.intVal
  let value_loc = state.add_name(value_str)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eLiteral,
    literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: value_loc),
  ))

proc identifier_expression(state :var State; name :string) :astTF.Id=
  let name_loc = state.add_name(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc chain_statement(state :var State; statement_id :astTF.Id) =
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
    else: discard
    state.ast.data.statements.get[previous_id] = previous
  state.previous_stmt = some(statement_id)


proc procedure(state :var State; node :PNode) =
  if node.kind notin {nkProcDef, nkFuncDef}: return
  # node[0] = name, node[1] = pattern, node[2] = generics,
  # node[3] = params, node[4] = pragmas, node[5] = reserved, node[6] = body
  let name_node = node[0]
  let params_node = node[3]
  let body_node = node[6]

  let name_str = case name_node.kind
    of nkPostfix: name_node[1].sym.name.s
    of nkSym:     name_node.sym.name.s
    else:         ""
  if name_str.len == 0: return

  let is_exported = name_node.kind == nkPostfix
  let is_func = node.kind == nkFuncDef

  let name_loc = state.add_name(name_str)
  let name_ident = astTF.Identifier(location: name_loc)

  # Arguments: params_node[0] = return type, params_node[1..] = param groups
  var first_argument = none(astTF.Id)
  var previous_binding = none(astTF.Id)
  if params_node.kind == nkFormalParams and params_node.safeLen > 1:
    for param_index in 1 ..< params_node.safeLen:
      let param_group = params_node[param_index]
      if param_group.kind != nkIdentDefs: continue
      # Each param group: name1, name2, ..., type, default
      let type_index = param_group.safeLen - 2
      let type_node = param_group[type_index]
      var param_type = none(astTF.Id)
      if type_node.kind == nkSym:
        param_type = some(state.identifier_expression(type_node.sym.name.s))
      elif type_node.kind != nkEmpty:
        param_type = some(state.identifier_expression(renderer.renderTree(type_node)))

      for name_index in 0 ..< type_index:
        let param_name_node = param_group[name_index]
        let param_name = case param_name_node.kind
          of nkSym: param_name_node.sym.name.s
          else:     ""
        if param_name.len == 0: continue

        let is_last_in_group = name_index == type_index - 1
        let param_name_loc = state.add_name(param_name)
        let param_ident = astTF.Identifier(location: param_name_loc)
        let param_binding = astTF.Binding(
          name: some(param_ident),
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

  # Return type
  var return_type = none(astTF.Id)
  if params_node.kind == nkFormalParams and params_node.safeLen > 0:
    let return_node = params_node[0]
    if return_node.kind == nkSym:
      return_type = some(state.identifier_expression(return_node.sym.name.s))
    elif return_node.kind != nkEmpty:
      return_type = some(state.identifier_expression(renderer.renderTree(return_node)))

  let proc_data = astTF.Procedure(
    name: some(name_ident),
    private: some(not is_exported),
    impure: some(not is_func),
    arguments: first_argument,
    returnType: return_type,
  )
  let procedure_id = state.ast.add_procedure(proc_data)
  let statement = astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: procedure_id),
  )
  let statement_id = state.ast.add_statement(statement)
  state.chain_statement(statement_id)


proc variable(state :var State; node :PNode) =
  if node.kind notin {nkVarSection, nkLetSection, nkConstSection}: return
  let is_mutable = node.kind == nkVarSection
  let is_runtime = node.kind == nkLetSection

  for definition in node:
    if definition.kind != nkIdentDefs: continue
    let name_node = definition[0]
    let type_node = definition[1]
    let value_node = definition[2]

    let name_str = case name_node.kind
      of nkSym:     name_node.sym.name.s
      of nkPostfix: name_node[1].sym.name.s
      else:         ""
    if name_str.len == 0: continue

    let is_exported = name_node.kind == nkPostfix

    let name_loc = state.add_name(name_str)
    let identifier = astTF.Identifier(location: name_loc)

    var data_type = none(astTF.Id)
    if type_node.kind == nkSym:
      data_type = some(state.identifier_expression(type_node.sym.name.s))
    elif type_node.kind != nkEmpty:
      data_type = some(state.identifier_expression(renderer.renderTree(type_node)))

    var value = none(astTF.Id)
    if value_node.kind != nkEmpty:
      if value_node.kind in {nkIntLit .. nkUInt64Lit}:
        value = some(state.literal_expression(value_node))
      else:
        let value_str = renderer.renderTree(value_node)
        let value_loc = state.add_name(value_str)
        value = some(state.ast.add_expression(astTF.Expression(
          kind: astTF.eLiteral,
          literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.generic, value: value_loc),
        )))

    let binding = astTF.Binding(
      name: some(identifier),
      private: some(not is_exported),
      mutable: some(is_mutable),
      runtime: some(is_runtime),
      dataType: data_type,
      value: value,
    )
    let binding_id = state.ast.add_binding(binding)
    let statement = astTF.Statement(
      kind: astTF.sVariable,
      variable: astTF.StatementVariable(id: binding_id),
    )
    let statement_id = state.ast.add_statement(statement)
    state.chain_statement(statement_id)


proc top_level(state :var State; node :PNode) =
  if node == nil: return
  case node.kind
  of nkProcDef, nkFuncDef:
    state.procedure(node)
  of nkVarSection, nkLetSection, nkConstSection:
    state.variable(node)
  of nkStmtList:
    for child in node:
      state.top_level(child)
  else:
    discard


proc convert *(compiled :CompileResult) :astTF.Ast=
  var state = State(
    ast: astTF.Ast(root: 0, data: astTF.AstData(modules: @[])),
    source: "",
    previous_stmt: none(astTF.Id),
  )
  state.module = astTF.Id(state.ast.data.modules.len)
  state.ast.data.modules.add(astTF.Module(path: "input.nim", source: ""))

  for statement in compiled.statements:
    state.top_level(statement)

  state.ast.data.modules[state.module].source = state.source
  return state.ast

