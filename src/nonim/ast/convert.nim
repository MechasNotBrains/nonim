#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Converts Nim PNode AST (typed or untyped) into astTF data.
## Takes a single root PNode and walks it recursively.
#____________________________________________________________|
# @deps nimc
import "$nim"/compiler/[ast]
# @deps std
import std/options
# @deps nonim
import ../nimc/ergonomics
import ./types as astTF
import ./data as ast_data
import ./access


type State = object
  ast            :astTF.Ast
  module         :astTF.Id
  source         :string
  previous_stmt  :Option[astTF.Id]


proc name_add (state :var State; name :string) :astTF.Location=
  let start = uint64(state.source.len)
  state.source.add(name)
  let finish = uint64(state.source.len)
  state.ast.data.modules[state.module].source = state.source
  return astTF.Location(start: start, `end`: finish)


proc name (node :PNode) :string=
  case node.kind
  of nkSym:      node.sym.name.s
  of nkIdent:    node.ident.s
  of nkPostfix:  node[1].name()
  of nkAccQuoted: node.strValue
  else:          ""


proc exported (node :PNode) :bool=
  if node.kind == nkPostfix: return true
  if node.kind == nkSym: return sfExported in node.sym.flags
  return false


#_______________________________________
# @section Expressions
#_____________________________
proc expression (state :var State; node :PNode) :astTF.Id

proc expression_literal (state :var State; node :PNode) :astTF.Id=
  let literal_kind = case node.kind
    of Char:  astTF.LiteralKind.char
    of Int:   astTF.LiteralKind.integer
    of UInt:  astTF.LiteralKind.integer
    of Float: astTF.LiteralKind.float
    of Str:   astTF.LiteralKind.string
    of Nil:   astTF.LiteralKind.nil
    else:     astTF.LiteralKind.generic
  let value_str = node.strValue
  let value_loc = state.name_add(value_str)
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

proc expression_identifier (state :var State; name :string) :astTF.Id=
  let name_loc = state.name_add(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc expression_infix (state :var State; node :PNode) :astTF.Id=
  let operator_node = node[0]
  let left_node = node[1]
  let right_node = node[2]
  let operator_loc = state.name_add(operator_node.name())
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

proc expression_call (state :var State; node :PNode) :astTF.Id=
  let function_node = node[0]
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

proc expression_prefix (state :var State; node :PNode) :astTF.Id=
  let operator_node = node[0]
  let right_node = node[1]
  let operator_loc = state.name_add(operator_node.name())
  let right_id = state.expression(right_node)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eAffix,
    affix: astTF.ExpressionAffix(
      right: some(right_id),
      operator: operator_loc,
    ),
  ))

proc expression (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of SomeLit:                      state.expression_literal(node)
  of SomeIdent, nkSym, nkPostfix:  state.expression_identifier(node)
  of nkInfix:                      state.expression_infix(node)
  of nkPrefix:                     state.expression_prefix(node)
  of nkCall, nkCommand:            state.expression_call(node)
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
    of astTF.sKeyword:     previous.keyword.next = some(statement_id)
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
  let kind_loc = state.name_add("#")
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


proc statement_import (state :var State; node :PNode) =
  for child in node:
    let module_name = case child.kind
      of nkIdent:  child.ident.s
      of nkSym:    child.sym.name.s
      of nkInfix:  child[1].name() & "/" & child[2].name()
      of nkPrefix: child[0].name() & child[1].name()
      of nkStrLit..nkTripleStrLit: child.strVal
      else:        ""
    if module_name.len == 0: continue
    let name_loc = state.name_add(module_name)
    let statement = astTF.Statement(
      kind: astTF.sImport,
      `import`: astTF.StatementImport(
        path: name_loc,
      ),
    )
    let statement_id = state.ast.add_statement(statement)
    state.statement_chain(statement_id)


proc statement_variable (state :var State; node :PNode) =
  if node.kind notin {nkVarSection, nkLetSection, nkConstSection}: return
  let is_mutable = node.kind == nkVarSection
  let is_runtime = node.kind == nkLetSection

  for definition in node:
    if definition.kind == nkCommentStmt:
      state.statement_comment(definition)
      continue
    if definition.kind != nkIdentDefs: continue
    let name_node = definition[0]
    let type_node = definition[^2]
    let value_node = definition[^1]

    let name_str = name_node.name()
    if name_str.len == 0: continue

    let is_exported = name_node.exported()

    let name_loc = state.name_add(name_str)
    let identifier = astTF.Identifier(location: name_loc)

    var data_type = none(astTF.Id)
    if type_node.kind != nkEmpty:
      data_type = some(state.expression(type_node))

    var value = none(astTF.Id)
    if value_node.kind != nkEmpty:
      value = some(state.expression(value_node))

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
    state.statement_chain(statement_id)


proc statement_keyword (state :var State; node :PNode; depth :uint64= 0) :astTF.Id=
  let keyword_str = case node.kind
    of nkReturnStmt: "return"
    of nkBreakStmt:  "break"
    of nkContinueStmt: "continue"
    of nkDiscardStmt: "discard"
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
  let depth_id = if depth > 0: some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
                 else: none(astTF.Id)
  state.ast.add_statement(astTF.Statement(
    kind: astTF.sKeyword,
    keyword: astTF.StatementKeyword(
      keyword: astTF.Identifier(location: keyword_loc),
      value: value,
      depth: depth_id,
    ),
  ))


proc statement_body (state :var State; node :PNode; depth :uint64= 1) :astTF.Id

proc statement_branch (state :var State; node :PNode; depth :uint64) :astTF.Id=
  var first_branch = none(astTF.Id)
  var previous_branch = none(astTF.Id)
  for branch_node in node:
    var condition = none(astTF.Id)
    var body_node :PNode
    if branch_node.kind == nkElifBranch:
      condition = some(state.expression(branch_node[0]))
      body_node = branch_node[1]
    elif branch_node.kind == nkElse:
      body_node = branch_node[0]
    else:
      continue
    let body_id = some(state.statement_body(body_node, depth + 1))
    let depth_id = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
    let branch_id = state.ast.add_statement(astTF.Statement(
      kind: astTF.sBranch,
      branch: astTF.StatementBranch(
        condition: condition,
        body: body_id,
        depth: depth_id,
      ),
    ))
    if first_branch.isNone:
      first_branch = some(branch_id)
    if previous_branch.isSome:
      var prev = state.ast.statement(previous_branch.get)
      prev.branch.next = some(branch_id)
      state.ast.data.statements.get[previous_branch.get] = prev
    previous_branch = some(branch_id)
  return first_branch.get

proc statement_body (state :var State; node :PNode; depth :uint64= 1) :astTF.Id=
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
      of astTF.sKeyword: previous.keyword.next = some(statement_id)
      of astTF.sBranch:  previous.branch.next = some(statement_id)
      else: discard
      state.ast.data.statements.get[previous_id] = previous
    state.previous_stmt = some(statement_id)

  proc body_statement (state :var State; child :PNode) =
    let statement_id = case child.kind
      of nkReturnStmt, nkBreakStmt, nkContinueStmt, nkDiscardStmt:
        state.statement_keyword(child, depth)
      of nkIfStmt:
        state.statement_branch(child, depth)
      else:
        return
    state.body_chain(statement_id)

  if node.kind == nkStmtList:
    for child in node:
      state.body_statement(child)
  elif node.kind == nkIfStmt:
    let statement_id = state.statement_branch(node, depth)
    state.body_chain(statement_id)
  else:
    state.body_statement(node)

  state.previous_stmt = saved_previous
  return first_id.get


proc statement_procedure (state :var State; node :PNode) =
  if node.kind notin {nkProcDef, nkFuncDef}: return
  let name_node = node[0]
  let params_node = node[3]

  let name_str = name_node.name()
  if name_str.len == 0: return

  let is_exported = name_node.exported()
  let is_func = node.kind == nkFuncDef

  let name_loc = state.name_add(name_str)
  let name_ident = astTF.Identifier(location: name_loc)

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
        param_type = some(state.expression(type_node))

      for name_index in 0 ..< type_index:
        let param_name_node = param_group[name_index]
        let param_name = param_name_node.name()
        if param_name.len == 0: continue

        let is_last_in_group = name_index == type_index - 1
        let param_name_loc = state.name_add(param_name)
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

  var return_type = none(astTF.Id)
  if params_node.kind == nkFormalParams and params_node.safeLen > 0:
    let return_node = params_node[0]
    if return_node.kind != nkEmpty:
      return_type = some(state.expression(return_node))

  var body_id = none(astTF.Id)
  let body_node = node[6]
  if body_node.kind != nkEmpty:
    body_id = some(state.statement_body(body_node))

  let proc_data = astTF.Procedure(
    name: some(name_ident),
    private: some(not is_exported),
    impure: some(not is_func),
    arguments: first_argument,
    returnType: return_type,
    body: body_id,
  )
  let procedure_id = state.ast.add_procedure(proc_data)
  let statement = astTF.Statement(
    kind: astTF.sProcedure,
    procedure: astTF.StatementProcedure(id: procedure_id),
  )
  let statement_id = state.ast.add_statement(statement)
  state.statement_chain(statement_id)


proc statement_type (state :var State; node :PNode) =
  if node.kind != nkTypeDef: return
  let name_node = node[0]
  let body_node = node[2]
  let name_str = name_node.name()
  if name_str.len == 0: return
  let is_exported = name_node.exported()
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
          field_type = some(state.expression(type_node))
        for name_index in 0 ..< type_index:
          let field_name_node = field_def[name_index]
          let field_name_str = field_name_node.name()
          if field_name_str.len == 0: continue
          let field_name_loc = state.name_add(field_name_str)
          let is_last_in_group = name_index == type_index - 1
          let field_binding = astTF.Binding(
            name: some(astTF.Identifier(location: field_name_loc)),
            dataType: if is_last_in_group: field_type else: none(astTF.Id),
          )
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
        private: some(not is_exported),
      ),
    ))
    let statement_id = state.ast.add_statement(astTF.Statement(
      kind: astTF.sType,
      `type`: astTF.StatementType(id: type_id),
    ))
    state.statement_chain(statement_id)


proc statement_top_level (state :var State; node :PNode) =
  if node == nil: return
  case node.kind
  of nkProcDef, nkFuncDef:
    state.statement_procedure(node)
  of nkVarSection, nkLetSection, nkConstSection:
    state.statement_variable(node)
  of nkCommentStmt:
    state.statement_comment(node)
  of nkImportStmt, nkFromStmt, nkImportExceptStmt:
    state.statement_import(node)
  of nkTypeDef:
    state.statement_type(node)
  of nkTypeSection:
    for child in node:
      if child.kind == nkTypeDef:
        state.statement_type(child)
  of nkStmtList:
    for child in node:
      state.statement_top_level(child)
  else:
    discard


#_______________________________________
# @section Entry Point
#_____________________________
proc convert *(root :PNode; path :string= "input.nim") :astTF.Ast=
  var state = State(
    ast: astTF.Ast(root: 0, data: astTF.AstData(modules: @[])),
    source: "",
    previous_stmt: none(astTF.Id),
  )
  state.module = astTF.Id(state.ast.data.modules.len)
  state.ast.data.modules.add(astTF.Module(path: path, source: ""))

  state.statement_top_level(root)

  state.ast.data.modules[state.module].source = state.source
  return state.ast

