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

type State = object
  ast            :astTF.Ast
  module         :astTF.Id
  source         :string
  previous_stmt  :Option[astTF.Id]
  target         :Language
  typed          :bool


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


proc translate_type (state :State; nim_type :string) :string=
  if not state.typed: return nim_type
  case state.target
  of Language.C:
    case nim_type
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
  of Language.Zig:
    case nim_type
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
    else:          nim_type
  of Language.Nim:
    nim_type

proc type_from_sym (state :var State; node :PNode) :Option[astTF.Id]=
  if node.kind == nkSym and node.sym.typ != nil:
    let type_name = state.translate_type(typeToString(node.sym.typ))
    let type_loc = state.name_add(type_name)
    return some(state.ast.add_expression(astTF.Expression(
      kind: astTF.eIdentifier,
      identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: type_loc)),
    )))
  return none(astTF.Id)

proc exported (node :PNode) :bool=
  if node.kind == nkPostfix: return true
  if node.kind == nkSym: return sfExported in node.sym.flags
  return false


#_______________________________________
# @section Expressions
#_____________________________
proc expression (state :var State; node :PNode) :astTF.Id
proc expression_array_type (state :var State; node :PNode) :astTF.Id

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

proc type_identifier (state :var State; node :PNode) :astTF.Id=
  let name = state.translate_type(node.name())
  let name_loc = state.name_add(name)
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eIdentifier,
    identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: name_loc)),
  ))

proc type_expression (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of nkBracketExpr:
    if node[0].kind == nkSym and node[0].sym.name.s == "array":
      state.expression_array_type(node)
    else:
      state.type_identifier(node)
  else:
    state.type_identifier(node)

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
  let length_node = node[1]
  let element_node = node[2]
  let element_name = state.translate_type(element_node.name())
  let element_loc = state.name_add(element_name)
  let element_type_id = state.ast.add_type(astTF.Type(
    kind: astTF.tPrimitive,
    primitive: astTF.TypePrimitive(name: astTF.Identifier(location: element_loc)),
  ))
  var length_id = none(astTF.Id)
  if length_node.kind in SomeLit:
    length_id = some(state.expression_literal(length_node))
  let array_type_id = state.ast.add_type(astTF.Type(
    kind: astTF.tArray,
    array: astTF.TypeArray(element: element_type_id, length: length_id),
  ))
  state.ast.add_expression(astTF.Expression(
    kind: astTF.eType,
    `type`: astTF.ExpressionType(id: array_type_id),
  ))

proc expression (state :var State; node :PNode) :astTF.Id=
  case node.kind
  of SomeLit:                      state.expression_literal(node)
  of SomeIdent, nkSym, nkPostfix:  state.expression_identifier(node)
  of nkInfix:                      state.expression_infix(node)
  of nkPrefix:                     state.expression_prefix(node)
  of nkCall, nkCommand:            state.expression_call(node)
  of nkBracketExpr:
    if node[0].kind == nkSym and node[0].sym.name.s == "array":
      state.expression_array_type(node)
    else:
      state.expression_indexed(node)
  of nkHiddenStdConv, nkHiddenSubConv:
    if node.safeLen > 1: state.expression(node[1])
    else: state.expression_identifier("")
  of nkStmtListExpr:
    for child in node:
      if child.kind != nkEmpty:
        return state.expression(child)
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
      data_type = some(state.type_expression(type_node))

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

proc statement_conditional (state :var State; node :PNode; depth :uint64) :astTF.Id=
  var main_condition :astTF.Id
  var main_body = none(astTF.Id)
  var first_branch = none(astTF.Id)
  var previous_branch = none(astTF.Id)
  var is_first = true
  for branch_node in node:
    if branch_node.kind == nkElifBranch:
      let condition = state.expression(branch_node[0])
      let body_id = some(state.statement_body(branch_node[1], depth + 1))
      if is_first:
        main_condition = condition
        main_body = body_id
        is_first = false
      else:
        let branch_depth = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
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
      let body_id = some(state.statement_body(branch_node[0], depth + 1))
      let branch_depth = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
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
  let depth_id = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
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
      of astTF.sKeyword:    previous.keyword.next = some(statement_id)
      of astTF.sVariable:   previous.variable.next = some(statement_id)
      of astTF.sExpression: previous.expression.next = some(statement_id)
      else: discard
      state.ast.data.statements.get[previous_id] = previous
    state.previous_stmt = some(statement_id)

  proc body_variable (state :var State; child :PNode) =
    if child.kind != nkVarSection: return
    for definition in child:
      if definition.kind != nkIdentDefs: continue
      let name_node = definition[0]
      let type_node = definition[^2]
      let value_node = definition[^1]
      let name_str = name_node.name()
      if name_str.len == 0: continue
      let name_loc = state.name_add(name_str)
      var data_type = none(astTF.Id)
      if type_node.kind != nkEmpty:
        data_type = some(state.type_expression(type_node))
      else:
        data_type = state.type_from_sym(name_node)
      var value = none(astTF.Id)
      if value_node.kind != nkEmpty:
        value = some(state.expression(value_node))
      let depth_id = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
      let binding_id = state.ast.add_binding(astTF.Binding(
        name: some(astTF.Identifier(location: name_loc)),
        mutable: some(true),
        runtime: some(true),
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
    let loop_body_id = some(state.statement_body(body_node, depth + 1))
    let depth_id = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
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

  proc body_assignment (state :var State; child :PNode) :astTF.Id=
    let left_node = child[0]
    let right_node = child[1]
    let left_id = state.expression(left_node)
    let right_id = state.expression(right_node)
    let assign_loc = state.name_add("=")
    let depth_id = some(state.ast.add_depth(astTF.Depth(indent: some(depth))))
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

  proc body_statement (state :var State; child :PNode) =
    let statement_id = case child.kind
      of nkReturnStmt, nkBreakStmt, nkContinueStmt, nkDiscardStmt:
        state.statement_keyword(child, depth)
      of nkIfStmt:
        state.statement_conditional(child, depth)
      of nkWhileStmt:
        state.body_while(child)
      of nkAsgn:
        state.body_assignment(child)
      of nkVarSection:
        state.body_variable(child)
        return
      else:
        return
    state.body_chain(statement_id)

  if node.kind == nkStmtList:
    for child in node:
      state.body_statement(child)
  elif node.kind == nkIfStmt:
    let statement_id = state.statement_conditional(node, depth)
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
        param_type = some(state.type_expression(type_node))

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
      return_type = some(state.type_expression(return_node))

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
          field_type = some(state.type_expression(type_node))
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
proc convert *(root :PNode; target :Language= Language.Nim; typed :bool= true; path :string= "input.nim") :astTF.Ast=
  var state = State(
    ast: astTF.Ast(root: 0, data: astTF.AstData(modules: @[])),
    source: "",
    previous_stmt: none(astTF.Id),
    target: target,
    typed: typed,
  )
  state.module = astTF.Id(state.ast.data.modules.len)
  state.ast.data.modules.add(astTF.Module(path: path, source: ""))

  state.statement_top_level(root)

  state.ast.data.modules[state.module].source = state.source
  return state.ast

