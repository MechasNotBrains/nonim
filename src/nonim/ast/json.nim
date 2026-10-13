#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/json import JsonNode, parseJson, to, pairs, hasKey, items, `[]`, `[]=`, getInt, getStr, getBool, `$`, pretty, add, newJObject, newJArray, newJString, newJBool, newJInt
from std/options import Option, some, get, isNone, isSome
from astTF import nil


proc fromJsonNode [T :enum](jsonNode :JsonNode; _:typedesc[T]) :T=
  T(jsonNode.getInt())

proc fromJsonNode (jsonNode :JsonNode; T :typedesc[astTF.ExpressionLiteral]) :T=
  result = default(T)
  result.kind = fromJsonNode(jsonNode["kind"], astTF.LiteralKind)
  result.value = jsonNode["value"].to(astTF.Location)
  if jsonNode.hasKey("next"): result.next = some(jsonNode["next"].to(astTF.Id))
  if jsonNode.hasKey("fmt"): result.fmt = some(jsonNode["fmt"].to(astTF.Id))

proc fromJsonNode (jsonNode :JsonNode; T :typedesc[astTF.Type]) :astTF.Type=
  for key, value in jsonNode.pairs:
    case key
    of "primitive":    return astTF.Type(kind: astTF.tPrimitive,   primitive:   value.to(astTF.TypePrimitive))
    of "array":        return astTF.Type(kind: astTF.tArray,       array:       value.to(astTF.TypeArray))
    of "ptr":          return astTF.Type(kind: astTF.tPtr,         `ptr`:       value.to(astTF.TypePtr))
    of "object":       return astTF.Type(kind: astTF.tObject,      `object`:    value.to(astTF.TypeObject))
    of "enumeration":  return astTF.Type(kind: astTF.tEnumeration, enumeration: value.to(astTF.TypeEnum))
    of "procedure":    return astTF.Type(kind: astTF.tProcedure,   procedure:   value.to(astTF.TypeProcedure))
    of "range":        return astTF.Type(kind: astTF.tRange,       `range`:     value.to(astTF.TypeRange))
    of "alias":        return astTF.Type(kind: astTF.tAlias,       alias:       value.to(astTF.TypeAlias))
    else: discard
  raise newException(ValueError, "unknown type variant: " & $jsonNode)

proc fromJsonNode (jsonNode :JsonNode; T :typedesc[astTF.Expression]) :astTF.Expression=
  for key, value in jsonNode.pairs:
    case key
    of "literal":     return astTF.Expression(kind: astTF.eLiteral,     literal:     fromJsonNode(value, astTF.ExpressionLiteral))
    of "identifier":  return astTF.Expression(kind: astTF.eIdentifier,  identifier:  value.to(astTF.ExpressionIdentifier))
    of "affix":       return astTF.Expression(kind: astTF.eAffix,       affix:       value.to(astTF.ExpressionAffix))
    of "call":        return astTF.Expression(kind: astTF.eCall,        call:        value.to(astTF.ExpressionCall))
    of "indexed":     return astTF.Expression(kind: astTF.eIndexed,     indexed:     value.to(astTF.ExpressionIndexed))
    of "block":       return astTF.Expression(kind: astTF.eBlock,       `block`:     value.to(astTF.ExpressionBlock))
    of "array":       return astTF.Expression(kind: astTF.eArray,       array:       value.to(astTF.ExpressionArray))
    of "object":      return astTF.Expression(kind: astTF.eObject,      `object`:    value.to(astTF.ExpressionObject))
    of "range":       return astTF.Expression(kind: astTF.eRange,       `range`:     value.to(astTF.ExpressionRange))
    of "conditional": return astTF.Expression(kind: astTF.eConditional, conditional: value.to(astTF.ExpressionConditional))
    of "loop":        return astTF.Expression(kind: astTF.eLoop,        loop:        value.to(astTF.ExpressionLoop))
    of "group":       return astTF.Expression(kind: astTF.eGroup,       group:       value.to(astTF.ExpressionGroup))
    of "type":        return astTF.Expression(kind: astTF.eType,        `type`:      value.to(astTF.ExpressionType))
    of "keyword":     return astTF.Expression(kind: astTF.eKeyword,     keyword:     value.to(astTF.ExpressionKeyword))
    of "procedure":   return astTF.Expression(kind: astTF.eProcedure,   procedure:   value.to(astTF.ExpressionProcedure))
    else: discard
  raise newException(ValueError, "unknown expression variant: " & $jsonNode)

proc fromJsonNode (jsonNode :JsonNode; T :typedesc[astTF.Statement]) :astTF.Statement=
  for key, value in jsonNode.pairs:
    case key
    of "expression":  return astTF.Statement(kind: astTF.sExpression,  expression:  value.to(astTF.StatementExpression))
    of "variable":    return astTF.Statement(kind: astTF.sVariable,    variable:    value.to(astTF.StatementVariable))
    of "procedure":   return astTF.Statement(kind: astTF.sProcedure,   procedure:   value.to(astTF.StatementProcedure))
    of "comment":     return astTF.Statement(kind: astTF.sComment,     comment:     value.to(astTF.StatementComment))
    of "import":      return astTF.Statement(kind: astTF.sImport,      `import`:    value.to(astTF.StatementImport))
    of "passthrough": return astTF.Statement(kind: astTF.sPassthrough, passthrough: value.to(astTF.StatementPassthrough))
    of "branch":      return astTF.Statement(kind: astTF.sBranch,      branch:      value.to(astTF.StatementBranch))
    of "pragma":      return astTF.Statement(kind: astTF.sPragma,      pragma:      value.to(astTF.StatementPragma))
    of "alias":       return astTF.Statement(kind: astTF.sAlias,       alias:       value.to(astTF.StatementAlias))
    of "type":        return astTF.Statement(kind: astTF.sType,        `type`:      value.to(astTF.StatementType))
    else: discard
  raise newException(ValueError, "unknown statement variant: " & $jsonNode)


proc fromJson *(json :string) :astTF.astTF=
  result = default(astTF.astTF)
  let root = parseJson(json)
  result.root = root["root"].to(astTF.Id)
  if root.hasKey("metadata"):
    result.metadata = some(root["metadata"].to(astTF.Metadata))
  let data = root["data"]
  for module in data["modules"].items:
    result.data.modules.add module.to(astTF.Module)
  if data.hasKey("bindings"):
    var list :astTF.DataList[astTF.Binding]= @[]
    for item in data["bindings"].items: list.add item.to(astTF.Binding)
    result.data.bindings = some(list)
  if data.hasKey("types"):
    var list :astTF.DataList[astTF.Type]= @[]
    for item in data["types"].items: list.add fromJsonNode(item, astTF.Type)
    result.data.types = some(list)
  if data.hasKey("expressions"):
    var list :astTF.DataList[astTF.Expression]= @[]
    for item in data["expressions"].items: list.add fromJsonNode(item, astTF.Expression)
    result.data.expressions = some(list)
  if data.hasKey("statements"):
    var list :astTF.DataList[astTF.Statement]= @[]
    for item in data["statements"].items: list.add fromJsonNode(item, astTF.Statement)
    result.data.statements = some(list)
  if data.hasKey("procedures"):
    var list :astTF.DataList[astTF.Procedure]= @[]
    for item in data["procedures"].items: list.add item.to(astTF.Procedure)
    result.data.procedures = some(list)
  if data.hasKey("comments"):
    var list :astTF.DataList[astTF.Comment]= @[]
    for item in data["comments"].items: list.add item.to(astTF.Comment)
    result.data.comments = some(list)
  if data.hasKey("aliases"):
    var list :astTF.DataList[astTF.Alias]= @[]
    for item in data["aliases"].items: list.add item.to(astTF.Alias)
    result.data.aliases = some(list)
  if data.hasKey("pragmas"):
    var list :astTF.DataList[astTF.Pragma]= @[]
    for item in data["pragmas"].items: list.add item.to(astTF.Pragma)
    result.data.pragmas = some(list)
  if data.hasKey("formats"):
    var list :astTF.DataList[astTF.Format]= @[]
    for item in data["formats"].items: list.add item.to(astTF.Format)
    result.data.formats = some(list)
  if data.hasKey("depths"):
    var list :astTF.DataList[astTF.Depth]= @[]
    for item in data["depths"].items: list.add item.to(astTF.Depth)
    result.data.depths = some(list)
  if data.hasKey("array_elements"):
    var list :astTF.DataList[astTF.ArrayElement]= @[]
    for item in data["array_elements"].items: list.add item.to(astTF.ArrayElement)
    result.data.array_elements = some(list)
  if data.hasKey("links"):
    var list :astTF.DataList[astTF.Link]= @[]
    for item in data["links"].items: list.add item.to(astTF.Link)
    result.data.links = some(list)
  if data.hasKey("synthetic"):
    result.data.synthetic = some(data["synthetic"].to(string))


proc toJsonNode (value :string) :JsonNode
proc toJsonNode (value :bool) :JsonNode
proc toJsonNode (value :SomeInteger) :JsonNode
proc toJsonNode [T :enum](value :T) :JsonNode
proc toJsonNode [T](value :seq[T]) :JsonNode
proc toJsonNode (value :astTF.Type) :JsonNode
proc toJsonNode (value :astTF.Expression) :JsonNode
proc toJsonNode (value :astTF.Statement) :JsonNode
proc toJsonNode [T :object](value :T) :JsonNode

proc toJsonNode (value :string) :JsonNode= newJString(value)
proc toJsonNode (value :bool) :JsonNode= newJBool(value)
proc toJsonNode (value :SomeInteger) :JsonNode= newJInt(BiggestInt(value))
proc toJsonNode [T :enum](value :T) :JsonNode= newJInt(BiggestInt(ord(value)))

proc toJsonNode [T](value :seq[T]) :JsonNode=
  result = newJArray()
  for item in value: result.add toJsonNode(item)

proc toJsonNode_variant (key :string; value :JsonNode) :JsonNode=
  result = newJObject()
  result[key] = value

proc toJsonNode (value :astTF.Type) :JsonNode=
  case value.kind
  of astTF.tPrimitive:   toJsonNode_variant("primitive",   toJsonNode(value.primitive))
  of astTF.tArray:       toJsonNode_variant("array",       toJsonNode(value.array))
  of astTF.tPtr:         toJsonNode_variant("ptr",         toJsonNode(value.`ptr`))
  of astTF.tObject:      toJsonNode_variant("object",      toJsonNode(value.`object`))
  of astTF.tEnumeration: toJsonNode_variant("enumeration", toJsonNode(value.enumeration))
  of astTF.tProcedure:   toJsonNode_variant("procedure",   toJsonNode(value.procedure))
  of astTF.tRange:       toJsonNode_variant("range",       toJsonNode(value.`range`))
  of astTF.tAlias:       toJsonNode_variant("alias",       toJsonNode(value.alias))

proc toJsonNode (value :astTF.Expression) :JsonNode=
  case value.kind
  of astTF.eLiteral:     toJsonNode_variant("literal",     toJsonNode(value.literal))
  of astTF.eIdentifier:  toJsonNode_variant("identifier",  toJsonNode(value.identifier))
  of astTF.eAffix:       toJsonNode_variant("affix",       toJsonNode(value.affix))
  of astTF.eCall:        toJsonNode_variant("call",        toJsonNode(value.call))
  of astTF.eIndexed:     toJsonNode_variant("indexed",     toJsonNode(value.indexed))
  of astTF.eBlock:       toJsonNode_variant("block",       toJsonNode(value.`block`))
  of astTF.eArray:       toJsonNode_variant("array",       toJsonNode(value.array))
  of astTF.eObject:      toJsonNode_variant("object",      toJsonNode(value.`object`))
  of astTF.eRange:       toJsonNode_variant("range",       toJsonNode(value.`range`))
  of astTF.eConditional: toJsonNode_variant("conditional", toJsonNode(value.conditional))
  of astTF.eLoop:        toJsonNode_variant("loop",        toJsonNode(value.loop))
  of astTF.eGroup:       toJsonNode_variant("group",       toJsonNode(value.group))
  of astTF.eType:        toJsonNode_variant("type",        toJsonNode(value.`type`))
  of astTF.eKeyword:     toJsonNode_variant("keyword",     toJsonNode(value.keyword))
  of astTF.eProcedure:   toJsonNode_variant("procedure",   toJsonNode(value.procedure))

proc toJsonNode (value :astTF.Statement) :JsonNode=
  case value.kind
  of astTF.sExpression:  toJsonNode_variant("expression",  toJsonNode(value.expression))
  of astTF.sVariable:    toJsonNode_variant("variable",    toJsonNode(value.variable))
  of astTF.sProcedure:   toJsonNode_variant("procedure",   toJsonNode(value.procedure))
  of astTF.sComment:     toJsonNode_variant("comment",     toJsonNode(value.comment))
  of astTF.sImport:      toJsonNode_variant("import",      toJsonNode(value.`import`))
  of astTF.sPassthrough: toJsonNode_variant("passthrough", toJsonNode(value.passthrough))
  of astTF.sBranch:      toJsonNode_variant("branch",      toJsonNode(value.branch))
  of astTF.sPragma:      toJsonNode_variant("pragma",      toJsonNode(value.pragma))
  of astTF.sAlias:       toJsonNode_variant("alias",       toJsonNode(value.alias))
  of astTF.sType:        toJsonNode_variant("type",        toJsonNode(value.`type`))

proc toJsonNode [T :object](value :T) :JsonNode=
  result = newJObject()
  for name, field in value.fieldPairs:
    when field is Option:
      if field.isSome: result[name] = toJsonNode(field.get)
    else:
      result[name] = toJsonNode(field)


proc toJson *(ast :astTF.astTF) :string= pretty(toJsonNode(ast))

