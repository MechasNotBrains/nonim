#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared test case AST builders for Type Statements.
#_______________________________________________________________|
import ./data


proc alias *() :TestData=
  const input_name   = "thing"
  const input_target = "int"
  const input_source = input_name & input_target & "567890Z"
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let target_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: target_loc))))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name   : some(astTF.Identifier(location: name_loc)),
    target : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc enumeration *() :TestData=
  const input_name   = "Thing"
  const input_one    = "one"
  const input_two    = "two"
  const input_value  = "42"
  const input_source = input_name & input_one & input_two & input_value & "567890Z"
  result = create(input_source)
  let name_loc  = astTF.Location(start: 0, `end`: input_name.len)
  let one_loc   = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_one.len)
  let two_loc   = astTF.Location(start: one_loc.`end`, `end`: one_loc.`end` + input_two.len)
  let value_loc = astTF.Location(start: two_loc.`end`, `end`: two_loc.`end` + input_value.len)
  let two_value = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: value_loc)))
  let two_id    = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: two_loc)), value: some(two_value), private: some(true)))
  let values    = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: one_loc)), next: some(two_id), private: some(true)))
  let type_id   = result.ast.add_type(astTF.Type(kind: astTF.tEnumeration, enumeration: astTF.TypeEnum(
    name   : some(astTF.Identifier(location: name_loc)),
    values : some(values),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_simple *() :TestData=
  const input_name   = "Thing"
  const input_field1 = "one"
  const input_field2 = "two"
  const input_type   = "int"
  const input_source = input_name & input_field1 & input_field2 & input_type & "567890Z"
  result = create(input_source)
  let name_loc    = astTF.Location(start: 0, `end`: input_name.len)
  let field1_loc  = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_field1.len)
  let field2_loc  = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + input_field2.len)
  let fieldT_loc  = astTF.Location(start: field2_loc.`end`, `end`: field2_loc.`end` + input_type.len)
  let fieldT_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: fieldT_loc))))
  let fieldT_expr = result.ast.add_expression_type(fieldT_id)
  let field2_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
  let field1_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
  let type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name   : some(astTF.Identifier(location: name_loc)),
    fields : some(field1_id),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_generic *() :TestData=
  const input_name   = "Vec2"
  const input_param  = "T"
  const input_field1 = "x"
  const input_field2 = "y"
  const input_source = input_name & input_param & input_field1 & input_field2 & "567890Z"
  result = create(input_source)
  let name_loc    = astTF.Location(start: 0, `end`: input_name.len)
  let param_loc   = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_param.len)
  let field1_loc  = astTF.Location(start: param_loc.`end`, `end`: param_loc.`end` + input_field1.len)
  let field2_loc  = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + input_field2.len)
  let generic_id  = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param_loc)), private: some(true)))
  let fieldT_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: param_loc))))
  let fieldT_expr = result.ast.add_expression_type(fieldT_id)
  let field2_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
  let field1_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
  let type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name     : some(astTF.Identifier(location: name_loc)),
    fields   : some(field1_id),
    generics : some(generic_id),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_inherit *() :TestData=
  const input_name    = "Circle"
  const input_base    = "Shape"
  const input_field   = "radius"
  const input_type    = "cfloat"
  const input_source  = input_name & input_base & input_field & input_type & "567890Z"
  result = create(input_source)
  let name_loc     = astTF.Location(start: 0, `end`: input_name.len)
  let base_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_base.len)
  let field_loc    = astTF.Location(start: base_loc.`end`, `end`: base_loc.`end` + input_field.len)
  let fieldT_loc   = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + input_type.len)
  let base_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: base_loc))))
  let link_id      = result.ast.add_link(astTF.Link(`type`: base_type_id))
  let link_range   = astTF.Location(start: link_id.uint64, `end`: link_id.uint64)
  let fieldT_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: fieldT_loc))))
  let fieldT_expr  = result.ast.add_expression_type(fieldT_id)
  let field_id     = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field_loc)), dataType: some(fieldT_expr)))
  let type_id      = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name   : some(astTF.Identifier(location: name_loc)),
    fields : some(field_id),
    link   : some(link_range),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_generic_multi *() :TestData=
  const input_name   = "Table"
  const input_k      = "K"
  const input_v      = "V"
  const input_field1 = "key"
  const input_field2 = "value"
  const input_source = input_name & input_k & input_v & input_field1 & input_field2 & "567890Z"
  result = create(input_source)
  let name_loc    = astTF.Location(start: 0, `end`: input_name.len)
  let k_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_k.len)
  let v_loc       = astTF.Location(start: k_loc.`end`, `end`: k_loc.`end` + input_v.len)
  let field1_loc  = astTF.Location(start: v_loc.`end`, `end`: v_loc.`end` + input_field1.len)
  let field2_loc  = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + input_field2.len)
  let generic_v   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: v_loc)), private: some(true)))
  let generic_k   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: k_loc)), private: some(true), next: some(generic_v)))
  let k_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: k_loc))))
  let v_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: v_loc))))
  let k_type_expr = result.ast.add_expression_type(k_type_id)
  let v_type_expr = result.ast.add_expression_type(v_type_id)
  let field2_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field2_loc)), dataType: some(v_type_expr)))
  let field1_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field1_loc)), dataType: some(k_type_expr), next: some(field2_id)))
  let type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name     : some(astTF.Identifier(location: name_loc)),
    fields   : some(field1_id),
    generics : some(generic_k),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_inherit_multi *() :TestData=
  const input_name   = "DrawableCircle"
  const input_base1  = "Circle"
  const input_base2  = "Drawable"
  const input_source = input_name & input_base1 & input_base2 & "567890Z"
  result = create(input_source)
  let name_loc      = astTF.Location(start: 0, `end`: input_name.len)
  let base1_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_base1.len)
  let base2_loc     = astTF.Location(start: base1_loc.`end`, `end`: base1_loc.`end` + input_base2.len)
  let base1_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: base1_loc))))
  let base2_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: base2_loc))))
  let link1_id      = result.ast.add_link(astTF.Link(`type`: base1_type_id))
  let link2_id      = result.ast.add_link(astTF.Link(`type`: base2_type_id))
  let link_range    = astTF.Location(start: link1_id.uint64, `end`: link2_id.uint64)
  let type_id       = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name : some(astTF.Identifier(location: name_loc)),
    link : some(link_range),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc union *() :TestData=
  const input_name   = "MyUnion"
  const input_keyw   = "union"
  const input_pragma = "bycopy"
  const input_field1 = "x"
  const input_field2 = "y"
  const input_type   = "int"
  const input_source = input_name & input_keyw & input_pragma & input_field1 & input_field2 & input_type & "567890Z"
  result = create(input_source)
  let name_loc    = astTF.Location(start: 0, `end`: input_name.len)
  let keyw_loc    = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_keyw.len)
  let pragma_loc  = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_pragma.len)
  let field1_loc  = astTF.Location(start: pragma_loc.`end`, `end`: pragma_loc.`end` + input_field1.len)
  let field2_loc  = astTF.Location(start: field1_loc.`end`, `end`: field1_loc.`end` + input_field2.len)
  let fieldT_loc  = astTF.Location(start: field2_loc.`end`, `end`: field2_loc.`end` + input_type.len)
  let fieldT_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: fieldT_loc))))
  let fieldT_expr = result.ast.add_expression_type(fieldT_id)
  let field2_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field2_loc)), dataType: some(fieldT_expr)))
  let field1_id   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field1_loc)), dataType: some(fieldT_expr), next: some(field2_id)))
  let pragma_key  = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: pragma_loc))))
  let pragma_id   = result.ast.add_pragma(astTF.Pragma(key: pragma_key))
  let type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name    : some(astTF.Identifier(location: name_loc)),
    keyword : some(astTF.Identifier(location: keyw_loc)),
    fields  : some(field1_id),
    pragmas : some(pragma_id),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc primitive_distinct *() :TestData=
  const input_keyw   = "distinct"
  const input_name   = "Foo"
  const input_target = "int"
  const input_source = input_keyw & input_name & input_target & "567890Z"
  result = create(input_source)
  let keyw_loc       = astTF.Location(start: 0, `end`: input_keyw.len)
  let name_loc       = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_name.len)
  let target_loc     = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_target.len)
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(
    name             : astTF.Identifier(location: target_loc),
    keyword          : some(astTF.Identifier(location: keyw_loc)),
  )))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name             : some(astTF.Identifier(location: name_loc)),
    target           : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc primitive_instantiation *() :TestData=
  const input_name   = "Foo"
  const input_ref    = "Ref"
  const input_arg    = "Animation"
  const input_source = input_name & input_ref & input_arg & "567890Z"
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let ref_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_ref.len)
  let arg_loc        = astTF.Location(start: ref_loc.`end`, `end`: ref_loc.`end` + input_arg.len)
  let arg_expr_id    = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: arg_loc))))
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(
    name             : astTF.Identifier(location: ref_loc),
    instantiation    : some(arg_expr_id),
  )))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name             : some(astTF.Identifier(location: name_loc)),
    target           : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc primitive_instantiation_multi *() :TestData=
  const input_name   = "Foo"
  const input_ref    = "Map"
  const input_arg1   = "string"
  const input_arg2   = "int"
  const input_source = input_name & input_ref & input_arg1 & input_arg2 & "567890Z"
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let ref_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_ref.len)
  let arg1_loc       = astTF.Location(start: ref_loc.`end`, `end`: ref_loc.`end` + input_arg1.len)
  let arg2_loc       = astTF.Location(start: arg1_loc.`end`, `end`: arg1_loc.`end` + input_arg2.len)
  let arg2_expr_id   = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: arg2_loc))))
  let arg1_expr_id   = result.ast.add_expression(astTF.Expression(kind: astTF.eIdentifier, identifier: astTF.ExpressionIdentifier(name: astTF.Identifier(location: arg1_loc), next: some(arg2_expr_id))))
  let target_type_id = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(
    name             : astTF.Identifier(location: ref_loc),
    instantiation    : some(arg1_expr_id),
  )))
  let target_expr_id = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: target_type_id)))
  let alias_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name             : some(astTF.Identifier(location: name_loc)),
    target           : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc ptr_reference *() :TestData=
  const input_name   = "Foo"
  const input_keyw   = "object"
  const input_field  = "x"
  const input_ftype  = "int"
  const input_source = input_name & input_keyw & input_field & input_ftype & "567890Z"
  result = create(input_source)
  let name_loc        = astTF.Location(start: 0, `end`: input_name.len)
  let keyw_loc        = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_keyw.len)
  let field_loc       = astTF.Location(start: keyw_loc.`end`, `end`: keyw_loc.`end` + input_field.len)
  let ftype_loc       = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + input_ftype.len)
  let field_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: ftype_loc))))
  let field_type_expr = result.ast.add_expression_type(field_type_id)
  let field_id        = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field_loc)), dataType: some(field_type_expr)))
  let obj_type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name              : some(astTF.Identifier(location: name_loc)),
    keyword           : some(astTF.Identifier(location: keyw_loc)),
    fields            : some(field_id),
  )))
  let ptr_type_id     = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(
    target            : obj_type_id,
    reference         : some(true),
  )))
  let target_expr_id  = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: ptr_type_id)))
  let alias_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name              : some(astTF.Identifier(location: name_loc)),
    target            : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc ptr_reference_optional *() :TestData=
  const input_name   = "Foo"
  const input_obj    = "Bar"
  const input_field  = "x"
  const input_ftype  = "int"
  const input_source = input_name & input_obj & input_field & input_ftype & "567890Z"
  result = create(input_source)
  let name_loc        = astTF.Location(start: 0, `end`: input_name.len)
  let obj_loc         = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_obj.len)
  let field_loc       = astTF.Location(start: obj_loc.`end`, `end`: obj_loc.`end` + input_field.len)
  let ftype_loc       = astTF.Location(start: field_loc.`end`, `end`: field_loc.`end` + input_ftype.len)
  let field_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: ftype_loc))))
  let field_type_expr = result.ast.add_expression_type(field_type_id)
  let field_id        = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field_loc)), dataType: some(field_type_expr)))
  let obj_type_id     = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name              : some(astTF.Identifier(location: obj_loc)),
    fields            : some(field_id),
  )))
  let ptr_type_id     = result.ast.add_type(astTF.Type(kind: astTF.tPtr, `ptr`: astTF.TypePtr(
    target            : obj_type_id,
    reference         : some(true),
    optional          : some(true),
  )))
  let target_expr_id  = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: ptr_type_id)))
  let alias_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tAlias, alias: astTF.TypeAlias(
    name              : some(astTF.Identifier(location: name_loc)),
    target            : target_expr_id,
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: alias_type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc tuple_unnamed *() :TestData=
  const input_t1     = "cint"
  const input_t2     = "cstring"
  const input_keyw   = "tuple"
  const input_source = input_t1 & input_t2 & input_keyw
  result = create(input_source)
  let t1_loc   = astTF.Location(start: 0, `end`: input_t1.len)
  let t2_loc   = astTF.Location(start: t1_loc.`end`, `end`: t1_loc.`end` + input_t2.len)
  let keyw_loc = astTF.Location(start: t2_loc.`end`, `end`: t2_loc.`end` + input_keyw.len)
  let t1_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: t1_loc))))
  let t2_id    = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: t2_loc))))
  let t1_expr  = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: t1_id)))
  let t2_expr  = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: t2_id)))
  let field1   = result.ast.add_binding(astTF.Binding(dataType: some(t1_expr)))
  let field2   = result.ast.add_binding(astTF.Binding(dataType: some(t2_expr)))
  result.ast.data.bindings.get[field1].next = some(field2)
  result.id = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(keyword: some(astTF.Identifier(location: keyw_loc)), fields: some(field1))))


proc object_field_defaults *() :TestData=
  const input_name     = "Config"
  const input_field1   = "title"
  const input_type1    = "cstring"
  const input_default1 = "hello"
  const input_field2   = "count"
  const input_type2    = "int"
  const input_default2 = "42"
  const input_field3   = "arena"
  const input_type3    = "Allocator"
  const input_source   = input_name & input_field1 & input_type1 & input_default1 & input_field2 & input_type2 & input_default2 & input_field3 & input_type3 & "567890Z"
  result = create(input_source)
  let name_loc      = astTF.Location(start: 0, `end`: input_name.len)
  var offset        = name_loc.`end`
  let field1_loc    = astTF.Location(start: offset, `end`: offset + input_field1.len); offset += input_field1.len
  let type1_loc     = astTF.Location(start: offset, `end`: offset + input_type1.len); offset += input_type1.len
  let default1_loc  = astTF.Location(start: offset, `end`: offset + input_default1.len); offset += input_default1.len
  let field2_loc    = astTF.Location(start: offset, `end`: offset + input_field2.len); offset += input_field2.len
  let type2_loc     = astTF.Location(start: offset, `end`: offset + input_type2.len); offset += input_type2.len
  let default2_loc  = astTF.Location(start: offset, `end`: offset + input_default2.len); offset += input_default2.len
  let field3_loc    = astTF.Location(start: offset, `end`: offset + input_field3.len); offset += input_field3.len
  let type3_loc     = astTF.Location(start: offset, `end`: offset + input_type3.len); offset += input_type3.len
  let type1_id      = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type1_loc))))
  let type1_expr    = result.ast.add_expression_type(type1_id)
  let type2_id      = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type2_loc))))
  let type2_expr    = result.ast.add_expression_type(type2_id)
  let type3_id      = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: type3_loc))))
  let type3_expr    = result.ast.add_expression_type(type3_id)
  let default1_expr = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.string, value: default1_loc)))
  let default2_expr = result.ast.add_expression(astTF.Expression(kind: astTF.eLiteral, literal: astTF.ExpressionLiteral(kind: astTF.LiteralKind.integer, value: default2_loc)))
  let field_depth   = some(result.ast.add_depth(astTF.Depth(indent: some(1'u64))))
  let field3_id     = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field3_loc)), dataType: some(type3_expr), depth: field_depth))
  let field2_id     = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field2_loc)), dataType: some(type2_expr), value: some(default2_expr), next: some(field3_id), depth: field_depth))
  let field1_id     = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: field1_loc)), dataType: some(type1_expr), value: some(default1_expr), next: some(field2_id), depth: field_depth))
  let type_id       = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(
    name            : some(astTF.Identifier(location: name_loc)),
    fields          : some(field1_id),
  )))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc object_empty *() :TestData=
  result = create("")
  let empty_binding = result.ast.add_binding(astTF.Binding(runtime: some(true)))
  result.id = result.ast.add_expression(astTF.Expression(
    kind     : astTF.eObject,
    `object` : astTF.ExpressionObject(fields: empty_binding),
  ))


proc procedure_generic *() :TestData=
  const input_name   = "Callback"
  const input_param  = "T"
  const input_arg    = "item"
  const input_source = input_name & input_param & input_arg & "567890Z"
  result = create(input_source)
  let name_loc        = astTF.Location(start: 0, `end`: input_name.len)
  let param_loc       = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_param.len)
  let arg_loc         = astTF.Location(start: param_loc.`end`, `end`: param_loc.`end` + input_arg.len)
  let generic_id      = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: param_loc)), private: some(true)))
  let param_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: param_loc))))
  let param_type_expr = result.ast.add_expression_type(param_type_id)
  let arg_id          = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: arg_loc)), dataType: some(param_type_expr), private: some(true)))
  let ret_expr        = result.ast.add_expression_type(param_type_id)
  let proc_id         = result.ast.add_procedure(astTF.Procedure(
    name              : some(astTF.Identifier(location: name_loc)),
    arguments         : some(arg_id),
    returnType        : some(ret_expr),
    generics          : some(generic_id),
    impure            : some(true),
  ))
  let type_id         = result.ast.add_type(astTF.Type(kind: astTF.tProcedure, procedure: astTF.TypeProcedure(id: proc_id)))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sType, `type`: astTF.StatementType(id: type_id)))
  result.ast.data.modules[result.module].body = some(result.id)


proc procedure_tuple_return *() :TestData=
  const input_name   = "tee"
  const input_selfn  = "self"
  const input_selft  = "Stream"
  const input_t1     = "cint"
  const input_t2     = "cstring"
  const input_keyw   = "tuple"
  const input_source = input_name & input_selfn & input_selft & input_t1 & input_t2 & input_keyw
  result = create(input_source)
  let name_loc       = astTF.Location(start: 0, `end`: input_name.len)
  let selfn_loc      = astTF.Location(start: name_loc.`end`, `end`: name_loc.`end` + input_selfn.len)
  let selft_loc      = astTF.Location(start: selfn_loc.`end`, `end`: selfn_loc.`end` + input_selft.len)
  let t1_loc         = astTF.Location(start: selft_loc.`end`, `end`: selft_loc.`end` + input_t1.len)
  let t2_loc         = astTF.Location(start: t1_loc.`end`, `end`: t1_loc.`end` + input_t2.len)
  let keyw_loc       = astTF.Location(start: t2_loc.`end`, `end`: t2_loc.`end` + input_keyw.len)
  let self_type_id   = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: selft_loc))))
  let self_type_expr = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: self_type_id)))
  let self_binding   = result.ast.add_binding(astTF.Binding(name: some(astTF.Identifier(location: selfn_loc)), dataType: some(self_type_expr), private: some(true)))
  let t1_id          = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: t1_loc))))
  let t2_id          = result.ast.add_type(astTF.Type(kind: astTF.tPrimitive, primitive: astTF.TypePrimitive(name: astTF.Identifier(location: t2_loc))))
  let t1_expr        = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: t1_id)))
  let t2_expr        = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: t2_id)))
  let field1         = result.ast.add_binding(astTF.Binding(dataType: some(t1_expr)))
  let field2         = result.ast.add_binding(astTF.Binding(dataType: some(t2_expr)))
  result.ast.data.bindings.get[field1].next = some(field2)
  let tuple_type_id  = result.ast.add_type(astTF.Type(kind: astTF.tObject, `object`: astTF.TypeObject(keyword: some(astTF.Identifier(location: keyw_loc)), fields: some(field1))))
  let ret_expr       = result.ast.add_expression(astTF.Expression(kind: astTF.eType, `type`: astTF.ExpressionType(id: tuple_type_id)))
  let proc_id        = result.ast.add_procedure(astTF.Procedure(name: some(astTF.Identifier(location: name_loc)), arguments: some(self_binding), returnType: some(ret_expr), impure: some(true)))
  result.id = result.ast.add_statement(astTF.Statement(kind: astTF.sProcedure, procedure: astTF.StatementProcedure(id: proc_id)))
  result.ast.data.modules[result.module].body = some(result.id)

