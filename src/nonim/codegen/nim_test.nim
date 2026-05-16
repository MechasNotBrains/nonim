#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps tests
import minitest
# @deps nonim
import ./nim

const expected_dir = "./expected/nim/"
const partials_dir = expected_dir & "partials/"
template expected (path :static system.string) :system.string= staticRead(expected_dir & path)
template partial  (path :static system.string) :system.string= staticRead(partials_dir & path)


#_______________________________________
# @section Keywords
#_____________________________
describe "nonim.codegen.nim | Keyword Cases":
  it "must return true for known nim keywords", proc()=
    keyword("proc").eq(true)

  it "must return false for other words", proc()=
    keyword("hello").eq(false)


#_______________________________________
# @section Identifiers
#_____________________________
describe "nonim.codegen.nim | Identifier Cases":
  it "must generate an identifier without backticks when the name is not a nim keyword", proc()=
    const Expected   = partial("identifier_plain.nim")
    const Input_name = "thing"
    const Input_src  = Input_name & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    # Run
    ast.identifier(module, astTF.Identifier(location: name_loc), Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an identifier with backticks when the name is a nim keyword", proc()=
    const Expected   = partial("identifier_keyword.nim")
    const Input_name = "proc"
    const Input_src  = Input_name & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    # Run
    ast.identifier(module, astTF.Identifier(location: name_loc), Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Pragmas
#_____________________________
describe "nonim.codegen.nim | Pragma Cases":
  it "must generate a single pragma", proc()=
    const Expected   = partial("pragma_single.nim")
    const Input_name = "pop"
    const Input_src  = Input_name & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let key_expr     = ast.add_expression(astTF.Expression(
      kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: name_loc))))
    let pragma_id    = ast.add_pragma(astTF.Pragma(key: key_expr))
    # Run
    ast.pragma(module, pragma_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a combined pragma", proc()=
    const Expected    = partial("pragma_combined.nim")
    const Input_name1 = "pragma"
    const Input_name2 = "header"
    const Input_value = "hello.h"
    const Input_src   = Input_name1 & Input_name2 & Input_value & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: First key
    let key1_loc      = astTF.Location(start: 0, `end`: Input_name1.len)
    let key1          = ast.add_expression(astTF.Expression(
      kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: key1_loc))))
    # Setup: Second key
    let key2_loc      = astTF.Location(start: key1_loc.`end`, `end`: key1_loc.`end` + Input_name2.len)
    let key2          = ast.add_expression(astTF.Expression(
      kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(
      name: astTF.Identifier(location: key2_loc))))
    # Setup: Second Value
    let value_loc     = astTF.Location(start: key2_loc.`end`, `end`: key2_loc.`end` + Input_value.len)
    let value         = ast.add_expression(astTF.Expression(
      kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(
      kind: astTF.LiteralKind.string, value: value_loc)))
    # Setup: Pragma Chain
    let pragma2       = ast.add_pragma(astTF.Pragma(key: key2, value: some(value)))
    let pragma1       = ast.add_pragma(astTF.Pragma(key: key1, next: some(pragma2)))
    # Run
    ast.pragma(module, pragma1, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Literals
#_____________________________
describe "nonim.codegen.nim | Literal Cases":
  it "must generate a literal value", proc()=
    const Expected   = partial("literal_integer.nim")
    const Input_val  = "42"
    const Input_src  = Input_val & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let value_loc    = astTF.Location(start: 0, `end`: Input_val.len)
    let expr_id      = ast.add_expression(astTF.Expression(
      kind           : astTF.eLiteral,
      literal        : astTF.ExpressionLiteral(
        kind         : astTF.LiteralKind.integer,
        value        : value_loc)))
    # Run
    ast.literal(module, expr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must append u64 suffix to integer literals exceeding int32 range", proc()=
    const Expected   = partial("literal_large_integer.nim")
    const Input_val  = $(int32.high.int64 + 1)
    const Input_src  = Input_val & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let value_loc    = astTF.Location(start: 0, `end`: Input_val.len)
    let expr_id      = ast.add_expression(astTF.Expression(
      kind           : astTF.eLiteral,
      literal        : astTF.ExpressionLiteral(
        kind         : astTF.LiteralKind.integer,
        value        : value_loc)))
    # Run
    ast.literal(module, expr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Affix Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.affix Cases":
  it "must generate a binary infix expression", proc()=
    const Expected    = partial("expression_affix_binary.nim")
    const Input_left  = "a"
    const Input_op    = "or"
    const Input_right = "b"
    const Input_src   = Input_left & Input_op & Input_right & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let left_loc      = astTF.Location(start: 0, `end`: Input_left.len)
    let op_loc        = astTF.Location(start: left_loc.`end`, `end`: left_loc.`end` + Input_op.len)
    let right_loc     = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + Input_right.len)
    let left_id       = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: left_loc))))
    let right_id      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: right_loc))))
    let affix_id      = ast.add_expression(Expression(kind: astTF.eAffix, affix: ExpressionAffix(left: some(left_id), right: some(right_id), operator: op_loc)))
    # Run
    ast.expression(module, affix_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a unary prefix expression", proc()=
    const Expected    = partial("expression_affix_unary.nim")
    const Input_op    = "not"
    const Input_right = "x"
    const Input_src   = Input_op & Input_right & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let op_loc        = astTF.Location(start: 0, `end`: Input_op.len)
    let right_loc     = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + Input_right.len)
    let right_id      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: right_loc))))
    let affix_id      = ast.add_expression(Expression(kind: astTF.eAffix, affix: ExpressionAffix(right: some(right_id), operator: op_loc)))
    # Run
    ast.expression(module, affix_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Group Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.group Cases":
  it "must generate a parenthesized expression", proc()=
    const Expected    = partial("expression_group.nim")
    const Input_left  = "a"
    const Input_op    = "or"
    const Input_right = "b"
    const Input_src   = Input_left & Input_op & Input_right & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let left_loc      = astTF.Location(start: 0, `end`: Input_left.len)
    let op_loc        = astTF.Location(start: left_loc.`end`, `end`: left_loc.`end` + Input_op.len)
    let right_loc     = astTF.Location(start: op_loc.`end`, `end`: op_loc.`end` + Input_right.len)
    let left_id       = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: left_loc))))
    let right_id      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: right_loc))))
    let affix_id      = ast.add_expression(Expression(kind: astTF.eAffix, affix: ExpressionAffix(left: some(left_id), right: some(right_id), operator: op_loc)))
    let group_id      = ast.add_expression(Expression(kind: astTF.eGroup, group: ExpressionGroup(inner: affix_id)))
    # Run
    ast.expression(module, group_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Call Expressions
#_____________________________
describe "nonim.codegen.nim | Expression.call Cases":
  it "must generate a call expression with an argument", proc()=
    const Expected    = partial("expression_call.nim")
    const Input_name  = "sizeof"
    const Input_arg   = "cint"
    const Input_src   = Input_name & Input_arg & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    let arg_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_arg.len)
    let name_id       = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: name_loc))))
    let arg_expr      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: arg_loc))))
    let arg_id        = ast.add_binding(Binding(value: some(arg_expr), private: some(true)))
    let call_id       = ast.add_expression(Expression(kind: astTF.eCall, call: ExpressionCall(name: name_id, arguments: some(arg_id))))
    # Run
    ast.expression(module, call_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a call expression without arguments", proc()=
    const Expected    = partial("expression_call_no_args.nim")
    const Input_name  = "foo"
    const Input_src   = Input_name & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    let name_id       = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: name_loc))))
    let call_id       = ast.add_expression(Expression(kind: astTF.eCall, call: ExpressionCall(name: name_id)))
    # Run
    ast.expression(module, call_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Types
#_____________________________
describe "nonim.codegen.nim | Type Cases":
  it "must generate a procedure type with args and return", proc()=
    const Expected      = partial("type_procedure.nim")
    const Input_arg     = "a"
    const Input_type    = "cint"
    const Input_pragma  = "cdecl"
    const Input_src     = Input_arg & Input_type & Input_pragma & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let arg_loc         = astTF.Location(start: 0, `end`: Input_arg.len)
    let type_loc        = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + Input_type.len)
    let pragma_loc      = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_pragma.len)
    let type_id         = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr       = ast.add_expression_type(type_id)
    let args_id         = ast.add_binding(Binding(name: some(Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
    let pragma_key      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: pragma_loc))))
    let pragma_id       = ast.add_pragma(Pragma(key: pragma_key))
    let proc_id         = ast.add_procedure(Procedure(arguments: some(args_id), returnType: some(type_expr), pragmas: some(pragma_id), impure: some(true), private: some(true)))
    let proctype_id     = ast.add_type(Type(kind: astTF.tProcedure, procedure: TypeProcedure(id: proc_id)))
    # Run
    ast.`type`(module, proctype_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a procedure type without return", proc()=
    const Expected      = partial("type_procedure_no_return.nim")
    const Input_arg     = "a"
    const Input_type    = "cint"
    const Input_pragma  = "cdecl"
    const Input_src     = Input_arg & Input_type & Input_pragma & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let arg_loc         = astTF.Location(start: 0, `end`: Input_arg.len)
    let type_loc        = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + Input_type.len)
    let pragma_loc      = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_pragma.len)
    let type_id         = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr       = ast.add_expression_type(type_id)
    let args_id         = ast.add_binding(Binding(name: some(Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
    let pragma_key      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: pragma_loc))))
    let pragma_id       = ast.add_pragma(Pragma(key: pragma_key))
    let proc_id         = ast.add_procedure(Procedure(arguments: some(args_id), pragmas: some(pragma_id), impure: some(true), private: some(true)))
    let proctype_id     = ast.add_type(Type(kind: astTF.tProcedure, procedure: TypeProcedure(id: proc_id)))
    # Run
    ast.`type`(module, proctype_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a pointer type", proc()=
    const Expected    = partial("type_ptr.nim")
    const Input_name  = "cint"
    const Input_src   = Input_name & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    let target_id     = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: name_loc))))
    let ptr_id        = ast.add_type(Type(kind: astTF.tPtr, `ptr`: TypePtr(target: target_id)))
    # Run
    ast.`type`(module, ptr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a fixed-size array type", proc()=
    const Expected    = partial("type_array_fixed.nim")
    const Input_elem  = "cint"
    const Input_len   = "10"
    const Input_src   = Input_elem & Input_len & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let elem_loc      = astTF.Location(start: 0, `end`: Input_elem.len)
    let len_loc       = astTF.Location(start: elem_loc.`end`, `end`: elem_loc.`end` + Input_len.len)
    let elem_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: elem_loc))))
    let len_id        = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: len_loc)))
    let arr_id        = ast.add_type(Type(kind: astTF.tArray, array: TypeArray(element: elem_id, length: some(len_id))))
    # Run
    ast.`type`(module, arr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a named array type", proc()=
    const Expected     = partial("type_array_named.nim")
    const Input_name   = "UncheckedArray"
    const Input_elem   = "cint"
    const Input_src    = Input_name & Input_elem & "567890Z"
    # Setup
    var Out            = Output.create()
    let module         = astTF.Id(0)
    var ast            = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc       = astTF.Location(start: 0, `end`: Input_name.len)
    let elem_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_elem.len)
    let elem_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: elem_loc))))
    let arr_id         = ast.add_type(Type(kind: astTF.tArray, array: TypeArray(name: some(Identifier(location: name_loc)), element: elem_id)))
    # Run
    ast.`type`(module, arr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a pointer to pointer type", proc()=
    const Expected    = partial("type_ptr_to_ptr.nim")
    const Input_name  = "cint"
    const Input_src   = Input_name & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    let inner_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: name_loc))))
    let outer_id      = ast.add_type(Type(kind: astTF.tPtr, `ptr`: TypePtr(target: inner_id)))
    let ptr_id        = ast.add_type(Type(kind: astTF.tPtr, `ptr`: TypePtr(target: outer_id)))
    # Run
    ast.`type`(module, ptr_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Bindings
#_____________________________
describe "nonim.codegen.nim | Binding Cases":
  it "must generate a single named binding with a type", proc()=
    const Expected   = partial("binding_named_type.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_src  = Input_name & Input_type & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let binding_id   = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr)))
    # Run
    ast.binding(module, binding_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a single named binding with a type and a default value", proc()=
    const Expected    = partial("binding_named_type_value.nim")
    const Input_name  = "thing"
    const Input_type  = "int"
    const Input_value = "42"
    const Input_src   = Input_name & Input_type & Input_value & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Name
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    # Setup: Type
    let type_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr     = ast.add_expression_type(type_id)
    # Setup: Value
    let value_loc     = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_value.len)
    let value_id      = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    # Setup: Binding
    let binding_id    = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr), value: some(value_id)))
    # Run
    ast.binding(module, binding_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a single named binding with a pragma", proc()=
    const Expected     = partial("binding_named_pragma.nim")
    const Input_name   = "thing"
    const Input_pragma = "cdecl"
    const Input_type   = "int"
    const Input_src    = Input_name & Input_pragma & Input_type & "567890Z"
    # Setup
    var Out            = Output.create()
    let module         = astTF.Id(0)
    var ast            = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Name
    let name_loc       = astTF.Location(start: 0, `end`: Input_name.len)
    # Setup: Pragma
    let pragma_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_pragma.len)
    let pragma_key     = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: pragma_loc))))
    let pragma_id      = ast.add_pragma(Pragma(key: pragma_key))
    # Setup: Type
    let type_loc       = astTF.Location(start: pragma_loc.`end`, `end`: pragma_loc.`end` + Input_type.len)
    let type_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr      = ast.add_expression_type(type_id)
    # Setup: Binding
    let binding_id     = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr), pragmas: some(pragma_id)))
    # Run
    ast.binding(module, binding_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a multi named binding with a type and a default value", proc()=
    const Expected    = partial("binding_multi_type_value.nim")
    const Input_name1 = "a"
    const Input_name2 = "b"
    const Input_type  = "int"
    const Input_value = "42"
    const Input_src   = Input_name1 & Input_name2 & Input_type & Input_value & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Names
    let name1_loc     = astTF.Location(start: 0, `end`: Input_name1.len)
    let name2_loc     = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + Input_name2.len)
    # Setup: Type
    let type_loc      = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + Input_type.len)
    let type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr     = ast.add_expression_type(type_id)
    # Setup: Value
    let value_loc     = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_value.len)
    let value_id      = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    # Setup: Bindings (reverse order for chaining)
    let binding2_id   = ast.add_binding(Binding(name: some(Identifier(location: name2_loc)), dataType: some(type_expr), value: some(value_id)))
    let binding1_id   = ast.add_binding(Binding(name: some(Identifier(location: name1_loc)), next: some(binding2_id)))
    # Run
    ast.binding(module, binding1_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Variables
#_____________________________
describe "nonim.codegen.nim | Variable Statement Cases":
  it "must generate a let variable statement", proc()=
    const Expected   = expected("variable_let.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_val  = "42"
    const Input_src  = Input_name & Input_type & Input_val & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Name + Type + Value
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let value_loc    = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_val.len)
    let value_id     = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    # Setup: Binding (runtime + immutable = let)
    let binding_id   = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr), value: some(value_id), runtime: some(true)))
    # Setup: Statement
    let statement_id = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: binding_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a var variable statement", proc()=
    const Expected   = expected("variable_var.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_val  = "42"
    const Input_src  = Input_name & Input_type & Input_val & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Name + Type + Value
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let value_loc    = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_val.len)
    let value_id     = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    # Setup: Binding (runtime + mutable = var)
    let binding_id   = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr), value: some(value_id), runtime: some(true), mutable: some(true)))
    # Setup: Statement
    let statement_id = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: binding_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a const variable statement", proc()=
    const Expected   = expected("variable_const.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_val  = "42"
    const Input_src  = Input_name & Input_type & Input_val & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Name + Type + Value
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let value_loc    = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_val.len)
    let value_id     = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    # Setup: Binding (comptime + immutable = const)
    let binding_id   = ast.add_binding(Binding(name: some(Identifier(location: name_loc)), dataType: some(type_expr), value: some(value_id)))
    # Setup: Statement
    let statement_id = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: binding_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Procedures
#_____________________________
describe "nonim.codegen.nim | Procedure Cases":
  it "must generate a public impure procedure with one argument and a return type", proc()=
    const Expected   = partial("procedure_public_impure.nim")
    const Input_name = "thing"
    const Input_arg  = "a"
    const Input_type = "int"
    const Input_src  = Input_name & Input_arg & Input_type & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let arg_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_arg.len)
    let type_loc     = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let args_id      = ast.add_binding(Binding(name: some(Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
    let proc_id      = ast.add_procedure(Procedure(
      name           : some(Identifier(location: name_loc)),
      arguments      : some(args_id),
      returnType     : some(type_expr),
      impure         : some(true)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a private impure procedure", proc()=
    const Expected   = partial("procedure_private_impure.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_src  = Input_name & Input_type & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let proc_id      = ast.add_procedure(Procedure(
      name           : some(Identifier(location: name_loc)),
      returnType     : some(type_expr),
      impure         : some(true),
      private        : some(true)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a public pure procedure", proc()=
    const Expected   = partial("procedure_public_pure.nim")
    const Input_name = "thing"
    const Input_type = "int"
    const Input_src  = Input_name & Input_type & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id      = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr    = ast.add_expression_type(type_id)
    let proc_id      = ast.add_procedure(Procedure(
      name           : some(Identifier(location: name_loc)),
      returnType     : some(type_expr)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a public pure procedure without return type", proc()=
    const Expected   = partial("procedure_no_return.nim")
    const Input_name = "thing"
    const Input_src  = Input_name & "567890Z"
    # Setup
    var Out          = Output.create()
    let module       = astTF.Id(0)
    var ast          = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc     = astTF.Location(start: 0, `end`: Input_name.len)
    let proc_id      = ast.add_procedure(Procedure(
      name           : some(Identifier(location: name_loc))))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a public pure procedure with pragmas", proc()=
    const Expected     = partial("procedure_with_pragmas.nim")
    const Input_name   = "thing"
    const Input_type   = "int"
    const Input_pragma = "cdecl"
    const Input_src    = Input_name & Input_type & Input_pragma & "567890Z"
    # Setup
    var Out            = Output.create()
    let module         = astTF.Id(0)
    var ast            = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc       = astTF.Location(start: 0, `end`: Input_name.len)
    let type_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_type.len)
    let type_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr      = ast.add_expression_type(type_id)
    let pragma_loc     = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_pragma.len)
    let pragma_key     = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: pragma_loc))))
    let pragma_id      = ast.add_pragma(Pragma(key: pragma_key))
    let proc_id        = ast.add_procedure(Procedure(
      name             : some(Identifier(location: name_loc)),
      returnType       : some(type_expr),
      pragmas          : some(pragma_id)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must use callable keyword when present", proc()=
    const Expected       = partial("procedure_template.nim")
    const Input_name     = "thing"
    const Input_callable = "template"
    const Input_src      = Input_name & Input_callable & "567890Z"
    # Setup
    var Out              = Output.create()
    let module           = astTF.Id(0)
    var ast              = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc         = astTF.Location(start: 0, `end`: Input_name.len)
    let call_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_callable.len)
    let proc_id          = ast.add_procedure(Procedure(name: some(Identifier(location: name_loc)), callable: some(Identifier(location: call_loc))))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must use callable keyword for method with args and return", proc()=
    const Expected       = partial("procedure_method.nim")
    const Input_name     = "thing"
    const Input_callable = "method"
    const Input_arg      = "a"
    const Input_type     = "int"
    const Input_src      = Input_name & Input_callable & Input_arg & Input_type & "567890Z"
    # Setup
    var Out              = Output.create()
    let module           = astTF.Id(0)
    var ast              = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc         = astTF.Location(start: 0, `end`: Input_name.len)
    let call_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_callable.len)
    let arg_loc          = astTF.Location(start: call_loc.`end`, `end`: call_loc.`end` + Input_arg.len)
    let type_loc         = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + Input_type.len)
    let type_id          = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr        = ast.add_expression_type(type_id)
    let args_id          = ast.add_binding(Binding(name: some(Identifier(location: arg_loc)), dataType: some(type_expr), private: some(true)))
    let proc_id          = ast.add_procedure(Procedure(name: some(Identifier(location: name_loc)), callable: some(Identifier(location: call_loc)), arguments: some(args_id), returnType: some(type_expr), impure: some(true)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a generic procedure", proc()=
    const Expected      = partial("procedure_generic.nim")
    const Input_name    = "clamp"
    const Input_param   = "T"
    const Input_arg1    = "value"
    const Input_arg2    = "low"
    const Input_arg3    = "high"
    const Input_src     = Input_name & Input_param & Input_arg1 & Input_arg2 & Input_arg3 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let param_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_param.len)
    let arg1_loc        = astTF.Location(start: param_loc.`end`, `end`: param_loc.`end` + Input_arg1.len)
    let arg2_loc        = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + Input_arg2.len)
    let arg3_loc        = astTF.Location(start: arg2_loc.`end`, `end`: arg2_loc.`end` + Input_arg3.len)
    # Setup: Generic parameter T
    let generic_id      = ast.add_binding(Binding(name: some(Identifier(location: param_loc)), private: some(true)))
    # Setup: T as a type
    let param_type_id   = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: param_loc))))
    let param_type_expr = ast.add_expression_type(param_type_id)
    # Setup: Arguments
    let arg3_id         = ast.add_binding(Binding(name: some(Identifier(location: arg3_loc)), dataType: some(param_type_expr), private: some(true)))
    let arg2_id         = ast.add_binding(Binding(name: some(Identifier(location: arg2_loc)), dataType: some(param_type_expr), private: some(true), next: some(arg3_id)))
    let arg1_id         = ast.add_binding(Binding(name: some(Identifier(location: arg1_loc)), dataType: some(param_type_expr), private: some(true), next: some(arg2_id)))
    # Setup: Procedure
    let proc_id         = ast.add_procedure(Procedure(
      name              : some(Identifier(location: name_loc)),
      generics          : some(generic_id),
      arguments         : some(arg1_id),
      returnType        : some(param_type_expr),
      impure            : some(true)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a procedure with multiple generic parameters", proc()=
    const Expected      = partial("procedure_generic_multi.nim")
    const Input_name    = "map"
    const Input_k       = "K"
    const Input_v       = "V"
    const Input_arg1    = "key"
    const Input_arg2    = "value"
    const Input_src     = Input_name & Input_k & Input_v & Input_arg1 & Input_arg2 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let k_loc           = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_k.len)
    let v_loc           = astTF.Location(start: k_loc.`end`, `end`: k_loc.`end` + Input_v.len)
    let arg1_loc        = astTF.Location(start: v_loc.`end`, `end`: v_loc.`end` + Input_arg1.len)
    let arg2_loc        = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + Input_arg2.len)
    # Setup: Generic parameters K, V
    let generic_v       = ast.add_binding(Binding(name: some(Identifier(location: v_loc)), private: some(true)))
    let generic_k       = ast.add_binding(Binding(name: some(Identifier(location: k_loc)), private: some(true), next: some(generic_v)))
    # Setup: Types K and V
    let k_type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: k_loc))))
    let v_type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: v_loc))))
    let k_type_expr     = ast.add_expression_type(k_type_id)
    let v_type_expr     = ast.add_expression_type(v_type_id)
    # Setup: Arguments
    let arg2_id         = ast.add_binding(Binding(name: some(Identifier(location: arg2_loc)), dataType: some(v_type_expr), private: some(true)))
    let arg1_id         = ast.add_binding(Binding(name: some(Identifier(location: arg1_loc)), dataType: some(k_type_expr), private: some(true), next: some(arg2_id)))
    # Setup: Procedure
    let proc_id         = ast.add_procedure(Procedure(
      name              : some(Identifier(location: name_loc)),
      generics          : some(generic_k),
      arguments         : some(arg1_id),
      returnType        : some(v_type_expr),
      impure            : some(true)))
    # Run
    ast.procedure(module, proc_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Type Statements
#_____________________________
describe "nonim.codegen.nim | Type Statement Cases":
  it "must generate a type alias statement", proc()=
    const Expected      = expected("statement_type_alias.nim")
    const Input_name    = "thing"
    const Input_target  = "int"
    const Input_src     = Input_name & Input_target & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let target_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_target.len)
    let target_type_id  = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: target_loc))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an enum type statement", proc()=
    const Expected    = expected("statement_type_enum.nim")
    const Input_name  = "Thing"
    const Input_one   = "one"
    const Input_two   = "two"
    const Input_value = "42"
    const Input_src   = Input_name & Input_one & Input_two & Input_value & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc      = astTF.Location(start: 0, `end`: Input_name.len)
    # Setup: First Value
    let one_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_one.len)
    # Setup: Second Value
    let two_loc       = astTF.Location(start: one_loc.`end`, `end`: one_loc.`end` + Input_two.len)
    let value_loc     = astTF.Location(start: two_loc.`end`, `end`: two_loc.`end` + Input_value.len)
    let two_value     = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: value_loc)))
    let two_id        = ast.add_binding(Binding(name: some(Identifier(location: two_loc)), value: some(two_value), private: some(true)))
    # Setup: Binding + Type + Statement
    let values        = ast.add_binding(Binding(name: some(Identifier(location: one_loc)), next: some(two_id), private: some(true)))
    let type_id       = ast.add_type(Type(kind: astTF.tEnumeration, enumeration: TypeEnum(
      name            : some(Identifier(location: name_loc)),
      values          : some(values))))
    let statement_id  = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an object type statement", proc()=
    const Expected      = expected("statement_type_object.nim")
    const Input_name    = "Thing"
    const Input_field1  = "one"
    const Input_field2  = "two"
    const Input_type    = "int"
    const Input_src     = Input_name & Input_field1 & Input_field2 & Input_type & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let field1_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_field1.len)
    let field2_loc      = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + Input_field2.len)
    # Setup: Field Type
    let fieldT_loc      = astTF.Location(start: field2_loc.`end`, `end`: field2_loc.`end` + Input_type.len)
    let fieldT_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: fieldT_loc))))
    let fieldT_expr     = ast.add_expression_type(fieldT_id)
    # Setup: Bindings
    let field2_id       = ast.add_binding(Binding(name: some(Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
    let field1_id       = ast.add_binding(Binding(name: some(Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
    # Setup: Type + Statement
    let type_id         = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      fields            : some(field1_id))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


  it "must generate a generic object type statement", proc()=
    const Expected      = expected("statement_type_object_generic.nim")
    const Input_name    = "Vec2"
    const Input_param   = "T"
    const Input_field1  = "x"
    const Input_field2  = "y"
    const Input_src     = Input_name & Input_param & Input_field1 & Input_field2 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let param_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_param.len)
    let field1_loc      = astTF.Location(start: param_loc.`end`, `end`: param_loc.`end` + Input_field1.len)
    let field2_loc      = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + Input_field2.len)
    # Setup: Generic parameter T
    let generic_id      = ast.add_binding(Binding(name: some(Identifier(location: param_loc)), private: some(true)))
    # Setup: Field type is T (a primitive referencing the same name)
    let fieldT_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: param_loc))))
    let fieldT_expr     = ast.add_expression_type(fieldT_id)
    # Setup: Fields
    let field2_id       = ast.add_binding(Binding(name: some(Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
    let field1_id       = ast.add_binding(Binding(name: some(Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
    # Setup: Type + Statement
    let type_id         = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      fields            : some(field1_id),
      generics          : some(generic_id))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an object type with inheritance", proc()=
    const Expected      = expected("statement_type_object_inherit.nim")
    const Input_name    = "Circle"
    const Input_base    = "Shape"
    const Input_field   = "radius"
    const Input_type    = "cfloat"
    const Input_src     = Input_name & Input_base & Input_field & Input_type & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let base_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_base.len)
    let field_loc       = astTF.Location(start: base_loc.`end`, `end`: base_loc.`end` + Input_field.len)
    let fieldT_loc      = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + Input_type.len)
    # Setup: Base type
    let base_type_id    = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: base_loc))))
    let link_id         = ast.add_link(Link(`type`: base_type_id))
    let link_range      = astTF.Location(start: link_id.uint64, `end`: link_id.uint64)
    # Setup: Field
    let fieldT_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: fieldT_loc))))
    let fieldT_expr     = ast.add_expression_type(fieldT_id)
    let field_id        = ast.add_binding(Binding(name: some(Identifier(location: field_loc)), dataType: some(fieldT_expr)))
    # Setup: Type + Statement
    let type_id         = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      fields            : some(field_id),
      link              : some(link_range))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an object type with multiple generic parameters", proc()=
    const Expected      = expected("statement_type_object_generic_multi.nim")
    const Input_name    = "Table"
    const Input_k       = "K"
    const Input_v       = "V"
    const Input_field1  = "key"
    const Input_field2  = "value"
    const Input_src     = Input_name & Input_k & Input_v & Input_field1 & Input_field2 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let k_loc           = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_k.len)
    let v_loc           = astTF.Location(start: k_loc.`end`, `end`: k_loc.`end` + Input_v.len)
    let field1_loc      = astTF.Location(start: v_loc.`end`, `end`: v_loc.`end` + Input_field1.len)
    let field2_loc      = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + Input_field2.len)
    # Setup: Generic parameters K, V
    let generic_v       = ast.add_binding(Binding(name: some(Identifier(location: v_loc)), private: some(true)))
    let generic_k       = ast.add_binding(Binding(name: some(Identifier(location: k_loc)), private: some(true), next: some(generic_v)))
    # Setup: Types K and V for fields
    let k_type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: k_loc))))
    let v_type_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: v_loc))))
    let k_type_expr     = ast.add_expression_type(k_type_id)
    let v_type_expr     = ast.add_expression_type(v_type_id)
    # Setup: Fields
    let field2_id       = ast.add_binding(Binding(name: some(Identifier(location: field2_loc)), dataType: some(v_type_expr)))
    let field1_id       = ast.add_binding(Binding(name: some(Identifier(location: field1_loc)), dataType: some(k_type_expr), next: some(field2_id)))
    # Setup: Type + Statement
    let type_id         = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      fields            : some(field1_id),
      generics          : some(generic_k))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must render only the first base for multiple inheritance", proc()=
    const Expected       = expected("statement_type_object_inherit_multi.nim")
    const Input_name     = "DrawableCircle"
    const Input_base1    = "Circle"
    const Input_base2    = "Drawable"
    const Input_src      = Input_name & Input_base1 & Input_base2 & "567890Z"
    # Setup
    var Out              = Output.create()
    let module           = astTF.Id(0)
    var ast              = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc         = astTF.Location(start: 0, `end`: Input_name.len)
    let base1_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_base1.len)
    let base2_loc        = astTF.Location(start: base1_loc.`end`, `end`: base1_loc.`end` + Input_base2.len)
    # Setup: Base types
    let base1_type_id    = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: base1_loc))))
    let base2_type_id    = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: base2_loc))))
    let link1_id         = ast.add_link(Link(`type`: base1_type_id))
    let link2_id         = ast.add_link(Link(`type`: base2_type_id))
    let link_range       = astTF.Location(start: link1_id.uint64, `end`: link2_id.uint64)
    # Setup: Type + Statement (no fields)
    let type_id          = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name               : some(Identifier(location: name_loc)),
      link               : some(link_range))))
    let statement_id     = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a union type with keyword and pragma combined", proc()=
    const Expected      = expected("statement_type_union.nim")
    const Input_name    = "MyUnion"
    const Input_keyw    = "union"
    const Input_pragma  = "bycopy"
    const Input_field1  = "x"
    const Input_field2  = "y"
    const Input_type    = "int"
    const Input_src     = Input_name & Input_keyw & Input_pragma & Input_field1 & Input_field2 & Input_type & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let keyw_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_keyw.len)
    let pragma_loc      = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_pragma.len)
    let field1_loc      = astTF.Location(start: pragma_loc.`end`, `end`: pragma_loc.`end` + Input_field1.len)
    let field2_loc      = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + Input_field2.len)
    let fieldT_loc      = astTF.Location(start: field2_loc.`end`, `end`: field2_loc.`end` + Input_type.len)
    let fieldT_id       = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: fieldT_loc))))
    let fieldT_expr     = ast.add_expression_type(fieldT_id)
    let field2_id       = ast.add_binding(Binding(name: some(Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
    let field1_id       = ast.add_binding(Binding(name: some(Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
    let pragma_key      = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: pragma_loc))))
    let pragma_id       = ast.add_pragma(Pragma(key: pragma_key))
    let type_id         = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      keyword           : some(Identifier(location: keyw_loc)),
      fields            : some(field1_id),
      pragmas           : some(pragma_id))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


  it "must generate a type alias with distinct keyword on primitive", proc()=
    const Expected      = expected("statement_type_primitive_keyword.nim")
    const Input_keyw    = "distinct"
    const Input_name    = "Foo"
    const Input_target  = "int"
    const Input_src     = Input_keyw & Input_name & Input_target & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let keyw_loc        = astTF.Location(start: 0, `end`: Input_keyw.len)
    let name_loc        = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_name.len)
    let target_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_target.len)
    let target_type_id  = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(
      name              : Identifier(location: target_loc),
      keyword           : some(Identifier(location: keyw_loc)))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a primitive type with instantiation (generics)", proc()=
    const Expected      = expected("statement_type_primitive_instantiation.nim")
    const Input_name    = "Foo"
    const Input_ref     = "Ref"
    const Input_arg     = "Animation"
    const Input_src     = Input_name & Input_ref & Input_arg & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let ref_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_ref.len)
    let arg_loc         = astTF.Location(start: ref_loc.`end`, `end`: ref_loc.`end` + Input_arg.len)
    let arg_expr_id     = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: arg_loc))))
    let target_type_id  = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(
      name              : Identifier(location: ref_loc),
      instantiation     : some(arg_expr_id))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a primitive type with multi-arg instantiation", proc()=
    const Expected      = expected("statement_type_primitive_instantiation_multi.nim")
    const Input_name    = "Foo"
    const Input_ref     = "Map"
    const Input_arg1    = "string"
    const Input_arg2    = "int"
    const Input_src     = Input_name & Input_ref & Input_arg1 & Input_arg2 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let ref_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_ref.len)
    let arg1_loc        = astTF.Location(start: ref_loc.`end`, `end`: ref_loc.`end` + Input_arg1.len)
    let arg2_loc        = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + Input_arg2.len)
    let arg2_expr_id    = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: arg2_loc))))
    let arg1_expr_id    = ast.add_expression(Expression(kind: astTF.eIdentifier, identifier: ExpressionIdentifier(name: Identifier(location: arg1_loc), next: some(arg2_expr_id))))
    let target_type_id  = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(
      name              : Identifier(location: ref_loc),
      instantiation     : some(arg1_expr_id))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a ref object type (ptr with reference=true)", proc()=
    const Expected      = expected("statement_type_ptr_reference.nim")
    const Input_name    = "Foo"
    const Input_keyw    = "object"
    const Input_field   = "x"
    const Input_ftype   = "int"
    const Input_src     = Input_name & Input_keyw & Input_field & Input_ftype & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let keyw_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_keyw.len)
    let field_loc       = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_field.len)
    let ftype_loc       = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + Input_ftype.len)
    let field_type_id   = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: ftype_loc))))
    let field_type_expr = ast.add_expression_type(field_type_id)
    let field_id        = ast.add_binding(Binding(name: some(Identifier(location: field_loc)), dataType: some(field_type_expr)))
    let obj_type_id     = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: name_loc)),
      keyword           : some(Identifier(location: keyw_loc)),
      fields            : some(field_id))))
    let ptr_type_id     = ast.add_type(Type(kind: astTF.tPtr, `ptr`: TypePtr(
      target            : obj_type_id,
      reference         : some(true))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: ptr_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must render optional ref by name, not inline object body", proc()=
    const Expected      = expected("statement_type_ptr_reference_optional.nim")
    const Input_name    = "Foo"
    const Input_obj     = "Bar"
    const Input_field   = "x"
    const Input_ftype   = "int"
    const Input_src     = Input_name & Input_obj & Input_field & Input_ftype & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let obj_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_obj.len)
    let field_loc       = astTF.Location(start: obj_loc.`end`, `end`: obj_loc.`end` + Input_field.len)
    let ftype_loc       = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + Input_ftype.len)
    let field_type_id   = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: ftype_loc))))
    let field_type_expr = ast.add_expression_type(field_type_id)
    let field_id        = ast.add_binding(Binding(name: some(Identifier(location: field_loc)), dataType: some(field_type_expr)))
    let obj_type_id     = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name              : some(Identifier(location: obj_loc)),
      fields            : some(field_id))))
    let ptr_type_id     = ast.add_type(Type(kind: astTF.tPtr, `ptr`: TypePtr(
      target            : obj_type_id,
      reference         : some(true),
      optional          : some(true))))
    let target_expr_id  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: ptr_type_id)))
    let alias_type_id   = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name              : some(Identifier(location: name_loc)),
      target            : target_expr_id)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an unnamed tuple type inline", proc()=
    const Expected      = partial("type_tuple_unnamed.nim")
    const Input_t1      = "cint"
    const Input_t2      = "cstring"
    const Input_keyw    = "tuple"
    const Input_src     = Input_t1 & Input_t2 & Input_keyw
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let t1_loc          = astTF.Location(start: 0, `end`: Input_t1.len)
    let t2_loc          = astTF.Location(start: t1_loc.`end`, `end`: t1_loc.`end` + Input_t2.len)
    let keyw_loc        = astTF.Location(start: t2_loc.`end`, `end`: t2_loc.`end` + Input_keyw.len)
    let t1_id           = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: t1_loc))))
    let t2_id           = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: t2_loc))))
    let t1_expr         = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: t1_id)))
    let t2_expr         = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: t2_id)))
    let field1          = ast.add_binding(Binding(dataType: some(t1_expr)))
    let field2          = ast.add_binding(Binding(dataType: some(t2_expr)))
    ast.data.bindings.get[field1].next = some(field2)
    let tuple_type_id   = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(keyword: some(Identifier(location: keyw_loc)), fields: some(field1))))
    # Run
    ast.`type`(module, tuple_type_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a proc with unnamed tuple return type", proc()=
    const Expected      = expected("procedure_tuple_return.nim")
    const Input_name    = "tee"
    const Input_selfn   = "self"
    const Input_selft   = "Stream"
    const Input_t1      = "cint"
    const Input_t2      = "cstring"
    const Input_keyw    = "tuple"
    const Input_src     = Input_name & Input_selfn & Input_selft & Input_t1 & Input_t2 & Input_keyw
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let selfn_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_selfn.len)
    let selft_loc       = astTF.Location(start: selfn_loc.`end`, `end`: selfn_loc.`end` + Input_selft.len)
    let t1_loc          = astTF.Location(start: selft_loc.`end`, `end`: selft_loc.`end` + Input_t1.len)
    let t2_loc          = astTF.Location(start: t1_loc.`end`, `end`: t1_loc.`end` + Input_t2.len)
    let keyw_loc        = astTF.Location(start: t2_loc.`end`, `end`: t2_loc.`end` + Input_keyw.len)
    let self_type_id    = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: selft_loc))))
    let self_type_expr  = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: self_type_id)))
    let self_binding    = ast.add_binding(Binding(name: some(Identifier(location: selfn_loc)), dataType: some(self_type_expr), private: some(true)))
    let t1_id           = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: t1_loc))))
    let t2_id           = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: t2_loc))))
    let t1_expr         = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: t1_id)))
    let t2_expr         = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: t2_id)))
    let field1          = ast.add_binding(Binding(dataType: some(t1_expr)))
    let field2          = ast.add_binding(Binding(dataType: some(t2_expr)))
    ast.data.bindings.get[field1].next = some(field2)
    let tuple_type_id   = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(keyword: some(Identifier(location: keyw_loc)), fields: some(field1))))
    let ret_expr        = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: tuple_type_id)))
    let proc_id         = ast.add_procedure(Procedure(name: some(Identifier(location: name_loc)), arguments: some(self_binding), returnType: some(ret_expr), impure: some(true)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sProcedure, procedure: StatementProcedure(id: proc_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Block Statements (statement_list)
#_____________________________
describe "nonim.codegen.nim | statement_list Cases":
  it "must not group a single type statement followed by a different statement kind", proc()=
    const Expected       = expected("block_type_then_proc.nim")
    const Input_name1    = "Foo"
    const Input_target   = "int"
    const Input_proc     = "thing"
    const Input_arg      = "a"
    const Input_type     = "int"
    const Input_src      = Input_name1 & Input_target & Input_proc & Input_arg & Input_type & "567890Z"
    # Setup
    var Out              = Output.create()
    let module           = astTF.Id(0)
    var ast              = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Type alias Foo = int
    let name1_loc        = astTF.Location(start: 0, `end`: Input_name1.len)
    let target_loc       = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + Input_target.len)
    let target_type_id   = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: target_loc))))
    let target_expr_id   = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id    = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name               : some(Identifier(location: name1_loc)),
      target             : target_expr_id)))
    # Setup: Procedure thing(a :int) :int
    let proc_loc         = astTF.Location(start: target_loc.`end`, `end`: target_loc.`end` + Input_proc.len)
    let arg_loc          = astTF.Location(start: proc_loc.`end`, `end`: proc_loc.`end` + Input_arg.len)
    let argT_loc         = astTF.Location(start: arg_loc.`end`, `end`: arg_loc.`end` + Input_type.len)
    let argT_id          = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: argT_loc))))
    let argT_expr        = ast.add_expression_type(argT_id)
    let arg_id           = ast.add_binding(Binding(name: some(Identifier(location: arg_loc)), dataType: some(argT_expr), private: some(true)))
    let proc_id          = ast.add_procedure(Procedure(name: some(Identifier(location: proc_loc)), arguments: some(arg_id), returnType: some(argT_expr), impure: some(true)))
    # Setup: Chain type -> proc
    let statement2_id    = ast.add_statement(Statement(kind: astTF.sProcedure, procedure: StatementProcedure(id: proc_id)))
    let statement1_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id, next: some(statement2_id))))
    # Run
    ast.statement_list(module, statement1_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must merge chained type statements into a type block", proc()=
    const Expected       = expected("block_type.nim")
    const Input_name1    = "Foo"
    const Input_target   = "int"
    const Input_name2    = "Bar"
    const Input_field    = "x"
    const Input_type     = "int"
    const Input_src      = Input_name1 & Input_target & Input_name2 & Input_field & Input_type & "567890Z"
    # Setup
    var Out              = Output.create()
    let module           = astTF.Id(0)
    var ast              = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: First type (alias Foo = int)
    let name1_loc        = astTF.Location(start: 0, `end`: Input_name1.len)
    let target_loc       = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + Input_target.len)
    let target_type_id   = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: target_loc))))
    let target_expr_id   = ast.add_expression(Expression(kind: astTF.eType, `type`: ExpressionType(id: target_type_id)))
    let alias_type_id    = ast.add_type(Type(kind: astTF.tAlias, alias: TypeAlias(
      name               : some(Identifier(location: name1_loc)),
      target             : target_expr_id)))
    # Setup: Second type (object Bar with field x :int)
    let name2_loc        = astTF.Location(start: target_loc.`end`, `end`: target_loc.`end` + Input_name2.len)
    let field_loc        = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + Input_field.len)
    let fieldT_loc       = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + Input_type.len)
    let fieldT_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: fieldT_loc))))
    let fieldT_expr      = ast.add_expression_type(fieldT_id)
    let field_id         = ast.add_binding(Binding(name: some(Identifier(location: field_loc)), dataType: some(fieldT_expr)))
    let obj_type_id      = ast.add_type(Type(kind: astTF.tObject, `object`: TypeObject(
      name               : some(Identifier(location: name2_loc)),
      fields             : some(field_id))))
    # Setup: Chain second statement, then first with next pointing to second
    let statement2_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: obj_type_id)))
    let statement1_id    = ast.add_statement(Statement(kind: astTF.sType, `type`: StatementType(id: alias_type_id, next: some(statement2_id))))
    # Run
    ast.statement_list(module, statement1_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must not group variable statements with different keywords", proc()=
    const Expected     = expected("block_variable_different_keywords.nim")
    const Input_name1  = "a"
    const Input_name2  = "b"
    const Input_type   = "int"
    const Input_val1   = "1"
    const Input_val2   = "2"
    const Input_src    = Input_name1 & Input_name2 & Input_type & Input_val1 & Input_val2 & "567890Z"
    # Setup
    var Out            = Output.create()
    let module         = astTF.Id(0)
    var ast            = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name1_loc      = astTF.Location(start: 0, `end`: Input_name1.len)
    let name2_loc      = astTF.Location(start: name1_loc.`end`, `end`: name1_loc.`end` + Input_name2.len)
    let type_loc       = astTF.Location(start: name2_loc.`end`, `end`: name2_loc.`end` + Input_type.len)
    let val1_loc       = astTF.Location(start: type_loc.`end`, `end`: type_loc.`end` + Input_val1.len)
    let val2_loc       = astTF.Location(start: val1_loc.`end`, `end`: val1_loc.`end` + Input_val2.len)
    let type_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: type_loc))))
    let type_expr      = ast.add_expression_type(type_id)
    let val1_id        = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: val1_loc)))
    let val2_id        = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: val2_loc)))
    # Setup: let a :int= 1 (runtime, not mutable)
    let binding1_id    = ast.add_binding(Binding(name: some(Identifier(location: name1_loc)), dataType: some(type_expr), value: some(val1_id), runtime: some(true)))
    # Setup: var b :int= 2 (runtime, mutable)
    let binding2_id    = ast.add_binding(Binding(name: some(Identifier(location: name2_loc)), dataType: some(type_expr), value: some(val2_id), runtime: some(true), mutable: some(true)))
    # Setup: Chain let -> var
    let statement2_id  = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: binding2_id)))
    let statement1_id  = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: binding1_id, next: some(statement2_id))))
    # Run
    ast.statement_list(module, statement1_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must group same keywords and split across different keywords and procs", proc()=
    const Expected     = expected("block_mixed_chain.nim")
    const Input_a      = "a"
    const Input_b      = "b"
    const Input_c      = "c"
    const Input_d      = "d"
    const Input_e      = "e"
    const Input_f      = "f"
    const Input_p1     = "thing1"
    const Input_p2     = "thing2"
    const Input_type   = "int"
    const Input_v1     = "1"
    const Input_v2     = "2"
    const Input_v3     = "3"
    const Input_v4     = "4"
    const Input_v5     = "5"
    const Input_v6     = "6"
    const Input_src    = Input_a & Input_b & Input_c & Input_d & Input_e & Input_f &
                         Input_p1 & Input_p2 & Input_type &
                         Input_v1 & Input_v2 & Input_v3 & Input_v4 & Input_v5 & Input_v6 & "567890Z"
    # Setup
    var Out            = Output.create()
    let module         = astTF.Id(0)
    var ast            = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    # Setup: Locations
    var pos            = 0'u64
    template loc(input :static system.string) :astTF.Location=
      let start = pos
      pos += input.len.uint64
      astTF.Location(start: start, `end`: pos)
    let loc_a          = loc(Input_a)
    let loc_b          = loc(Input_b)
    let loc_c          = loc(Input_c)
    let loc_d          = loc(Input_d)
    let loc_e          = loc(Input_e)
    let loc_f          = loc(Input_f)
    let loc_p1         = loc(Input_p1)
    let loc_p2         = loc(Input_p2)
    let loc_type       = loc(Input_type)
    let loc_v1         = loc(Input_v1)
    let loc_v2         = loc(Input_v2)
    let loc_v3         = loc(Input_v3)
    let loc_v4         = loc(Input_v4)
    let loc_v5         = loc(Input_v5)
    let loc_v6         = loc(Input_v6)
    # Setup: Shared type
    let type_id        = ast.add_type(Type(kind: astTF.tPrimitive, primitive: TypePrimitive(name: Identifier(location: loc_type))))
    let type_expr      = ast.add_expression_type(type_id)
    # Setup: Expressions
    let expr1          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v1)))
    let expr2          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v2)))
    let expr3          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v3)))
    let expr4          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v4)))
    let expr5          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v5)))
    let expr6          = ast.add_expression(Expression(kind: astTF.eLiteral, literal: ExpressionLiteral(kind: LiteralKind.integer, value: loc_v6)))
    # Setup: Bindings (let a, let b, var c, var d, const e, const f)
    let bind_a         = ast.add_binding(Binding(name: some(Identifier(location: loc_a)), dataType: some(type_expr), value: some(expr1), runtime: some(true)))
    let bind_b         = ast.add_binding(Binding(name: some(Identifier(location: loc_b)), dataType: some(type_expr), value: some(expr2), runtime: some(true)))
    let bind_c         = ast.add_binding(Binding(name: some(Identifier(location: loc_c)), dataType: some(type_expr), value: some(expr3), runtime: some(true), mutable: some(true)))
    let bind_d         = ast.add_binding(Binding(name: some(Identifier(location: loc_d)), dataType: some(type_expr), value: some(expr4), runtime: some(true), mutable: some(true)))
    let bind_e         = ast.add_binding(Binding(name: some(Identifier(location: loc_e)), dataType: some(type_expr), value: some(expr5)))
    let bind_f         = ast.add_binding(Binding(name: some(Identifier(location: loc_f)), dataType: some(type_expr), value: some(expr6)))
    # Setup: Procedures
    let proc1          = ast.add_procedure(Procedure(name: some(Identifier(location: loc_p1)), impure: some(true)))
    let proc2          = ast.add_procedure(Procedure(name: some(Identifier(location: loc_p2)), impure: some(true)))
    # Setup: Statements (build chain backwards)
    let stmt_f         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_f)))
    let stmt_e         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_e, next: some(stmt_f))))
    let stmt_p2        = ast.add_statement(Statement(kind: astTF.sProcedure, procedure: StatementProcedure(id: proc2, next: some(stmt_e))))
    let stmt_p1        = ast.add_statement(Statement(kind: astTF.sProcedure, procedure: StatementProcedure(id: proc1, next: some(stmt_p2))))
    let stmt_d         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_d, next: some(stmt_p1))))
    let stmt_c         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_c, next: some(stmt_d))))
    let stmt_b         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_b, next: some(stmt_c))))
    let stmt_a         = ast.add_statement(Statement(kind: astTF.sVariable, variable: StatementVariable(id: bind_a, next: some(stmt_b))))
    # Run
    ast.statement_list(module, stmt_a, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Passthrough Statements
#_____________________________
describe "nonim.codegen.nim | Statement.passthrough Cases":
  it "must generate a passthrough statement", proc()=
    const Expected    = expected("statement_passthrough.nim")
    const Input_text  = "# unsupported: __attribute__((packed))"
    const Input_src   = Input_text & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let text_loc      = astTF.Location(start: 0, `end`: Input_text.len)
    let statement_id  = ast.add_statement(Statement(kind: astTF.sPassthrough, passthrough: StatementPassthrough(location: text_loc)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Import Statements
#_____________________________
describe "nonim.codegen.nim | Statement.import Cases":
  it "must generate a simple import statement", proc()=
    const Expected      = expected("statement_import.nim")
    const Input_keyword = "import"
    const Input_path    = "foo"
    const Input_src     = Input_keyword & Input_path & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let keyw_loc        = astTF.Location(start: 0, `end`: Input_keyword.len)
    let path_loc        = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_path.len)
    let statement_id    = ast.add_statement(Statement(kind: astTF.sImport, `import`: StatementImport(keyword: some(Identifier(location: keyw_loc)), path: path_loc)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a from-import statement with symbols", proc()=
    const Expected      = expected("statement_import_from.nim")
    const Input_keyword = "from"
    const Input_path    = "foo"
    const Input_sym1    = "bar"
    const Input_sym2    = "baz"
    const Input_src     = Input_keyword & Input_path & Input_sym1 & Input_sym2 & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let keyw_loc        = astTF.Location(start: 0, `end`: Input_keyword.len)
    let path_loc        = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_path.len)
    let sym1_loc        = astTF.Location(start: path_loc.`end`, `end`: path_loc.`end` + Input_sym1.len)
    let sym2_loc        = astTF.Location(start: sym1_loc.`end`, `end`: sym1_loc.`end` + Input_sym2.len)
    let alias2          = ast.add_alias(Alias(name: Identifier(location: sym2_loc)))
    let alias1          = ast.add_alias(Alias(name: Identifier(location: sym1_loc), next: some(alias2)))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sImport, `import`: StatementImport(keyword: some(Identifier(location: keyw_loc)), path: path_loc, symbols: some(alias1))))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate an include statement", proc()=
    const Expected      = expected("statement_include.nim")
    const Input_keyword = "include"
    const Input_path    = "stdio"
    const Input_src     = Input_keyword & Input_path & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let keyw_loc        = astTF.Location(start: 0, `end`: Input_keyword.len)
    let path_loc        = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + Input_path.len)
    let statement_id    = ast.add_statement(Statement(kind: astTF.sImport, `import`: StatementImport(keyword: some(Identifier(location: keyw_loc)), path: path_loc)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Alias Statements
#_____________________________
describe "nonim.codegen.nim | Statement.alias Cases":
  it "must generate an alias statement as const", proc()=
    const Expected      = partial("statement_alias.nim")
    const Input_name    = "A"
    const Input_target  = "B"
    const Input_src     = Input_name & Input_target & "567890Z"
    # Setup
    var Out             = Output.create()
    let module          = astTF.Id(0)
    var ast             = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let name_loc        = astTF.Location(start: 0, `end`: Input_name.len)
    let target_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + Input_target.len)
    let alias_id        = ast.add_alias(Alias(name: Identifier(location: name_loc), target: some(Identifier(location: target_loc))))
    let statement_id    = ast.add_statement(Statement(kind: astTF.sAlias, alias: StatementAlias(id: alias_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)


#_______________________________________
# @section Comment Statements
#_____________________________
describe "nonim.codegen.nim | Statement.comment Cases":
  it "must generate a regular comment from C line comment", proc()=
    const Expected    = expected("statement_comment.nim")
    const Input_kind  = "//"
    const Input_text  = "this is a comment"
    const Input_src   = Input_kind & Input_text & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let kind_loc      = astTF.Location(start: 0, `end`: Input_kind.len)
    let text_loc      = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + Input_text.len)
    let comment_id    = ast.add_comment(Comment(kind: Identifier(location: kind_loc), text: text_loc))
    let statement_id  = ast.add_statement(Statement(kind: astTF.sComment, comment: StatementComment(id: comment_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a doc comment from C doc comment", proc()=
    const Expected    = expected("statement_comment_doc.nim")
    const Input_kind  = "///"
    const Input_text  = "this is a doc comment"
    const Input_src   = Input_kind & Input_text & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let kind_loc      = astTF.Location(start: 0, `end`: Input_kind.len)
    let text_loc      = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + Input_text.len)
    let comment_id    = ast.add_comment(Comment(kind: Identifier(location: kind_loc), text: text_loc))
    let statement_id  = ast.add_statement(Statement(kind: astTF.sComment, comment: StatementComment(id: comment_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

  it "must generate a multi-line doc comment with prefix on every line", proc()=
    const Expected    = expected("statement_comment_multiline.nim")
    const Input_kind  = "/**"
    const Input_text  = "first line\nsecond line\nthird line"
    const Input_src   = Input_kind & Input_text & "567890Z"
    # Setup
    var Out           = Output.create()
    let module        = astTF.Id(0)
    var ast           = astTF.Ast(root: module)
    ast.add_module(astTF.Module(source: Input_src))
    let kind_loc      = astTF.Location(start: 0, `end`: Input_kind.len)
    let text_loc      = astTF.Location(start: kind_loc.`end`, `end`: kind_loc.`end` + Input_text.len)
    let comment_id    = ast.add_comment(Comment(kind: Identifier(location: kind_loc), text: text_loc))
    let statement_id  = ast.add_statement(Statement(kind: astTF.sComment, comment: StatementComment(id: comment_id)))
    # Run
    ast.statement(module, statement_id, Target.definition, Out)
    # Check
    Out.modules[module].definitions.eq_str(Expected)

