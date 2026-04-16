#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import std/sets
# @deps compiler
import "$nim"/compiler/[ ast, idents, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../shared
import ../identifier
import ../expression
import ./Return
import ./assignment
import ./call
import ./variable
import ./comment as Comment


const MaxDepth * = 4

func random *(info :TLineInfo; public :bool= false; cmment :bool= R.bool(); depth :int= 0) :PNode

# Generate a random body statement at the given nesting depth
func bodyStatement *(info :TLineInfo; depth :int) :PNode=
  let kind = R.integer(4)
  result = case kind
  of 0 : variable.random(info, public=false)
  of 1 : call.random(info)
  of 2 : Comment.random(info)
  of 3 : assignment.random(info)
  else:
    if depth < MaxDepth : procedure.random(info, public=false, depth= depth + 1)
    else                : variable.random(info, public=false)


# Generate a random procedure node
func random *(info :TLineInfo; public :bool= false; cmment :bool= R.bool(); depth :int= 0) :PNode=
  # 1. Name (Postfix node for export)
  let nameNode = identifier.random(info, public) # Create postfix node for name

  # 2. Formal Params
  let randomRetType  = R.sample(basicTypes) # Randomly select a return type from basic types only
  {.cast(noSideEffect).}: # Access to gIdentCache is safe
    let retTypeIdent = gIdentCache.getIdent(randomRetType)
  let retTypeNode    = newIdentNode(retTypeIdent, info) # Use the random type
  let paramsNode     = newNodeI(nkFormalParams, info)
  paramsNode.add(retTypeNode) # Add return type node as first child

  var lastParamDef: PNode = nil
  var lastParamTypeIdent: PIdent = nil
  var usedParamNames = initHashSet[string]() # Track used names in this scope

  # Parameter Helper Proc
  proc addParam(initialNameLength: int; typeStr: string) =
    # Ensure unique name
    var nameStr = ""
    while true:
      nameStr = identifier.name(length=initialNameLength)
      if nameStr notin usedParamNames:
        usedParamNames.incl(nameStr)
        break

    {.cast(noSideEffect).}: # Access to gIdentCache is safe
      let paramIdent  = gIdentCache.getIdent(nameStr)
    let paramNameNode = newIdentNode(paramIdent, info)
    {.cast(noSideEffect).}: # Access to gIdentCache is safe
      let typeIdent   = gIdentCache.getIdent(typeStr)

    # Check if we can group with the previous definition
    if lastParamDef != nil and typeIdent == lastParamTypeIdent:
      # Group: Insert the new name node before the type node in the last definition
      let typeNodeIndex = lastParamDef.len - 2 # Index of type node (before default value)
      lastParamDef.sons.insert(paramNameNode, typeNodeIndex)
    else:
      # Start new group: Create new nkIdentDefs node
      let typeNode = newIdentNode(typeIdent, info)
      let newParamDef = newNodeI(nkIdentDefs, info)
      if R.bool():
        let pragmaName = newNodeI(nkPragmaExpr, info)
        pragmaName.add(paramNameNode)
        pragmaName.add(expression.pragmaNode(info, decl= true))
        newParamDef.add(pragmaName)
      else:
        newParamDef.add(paramNameNode)
      newParamDef.add(typeNode)
      newParamDef.add(newNodeI(nkEmpty, info)) # No default value
      paramsNode.add(newParamDef) # Add new definition to the list
      # Update tracking for next potential grouping
      lastParamDef = newParamDef
      lastParamTypeIdent = typeIdent

  # --- Add Parameters ---
  let numParams = R.integer(0..16) # Generate 0 to 16 parameters
  for i in 0..<numParams:
    let randomType = R.sample(basicTypes)
    let randomLength = R.integer(1..32) # Use length up to 32
    addParam(randomLength, randomType)
  # --- End Parameters ---

  # 3. Body
  var bodyNode = newNodeI(nkStmtList, info)
  if randomRetType != "void":
    bodyNode.add(assignment.defaultResult(info, randomRetType))
  for _ in 0..<R.integer(0..16):
    bodyNode.add(bodyStatement(info, depth))
  if bodyNode.len == 0:
    bodyNode = newNodeI(nkEmpty, info)

  # 4. Combine into final proc node
  result = newNodeI(nkProcDef, info)
  result.add(nameNode)                 # Child 0: Name (with export)
  result.add(newNodeI(nkEmpty, info))  # Child 1: Generic params (empty)
  result.add(newNodeI(nkEmpty, info))  # Child 2: Signature (empty)
  result.add(paramsNode)               # Child 3: Formal params
  result.add(expression.pragmaNode(info, decl= true)) # Child 4: Pragma
  result.add(newNodeI(nkEmpty, info))  # Child 5: Reserved (empty)
  result.add(bodyNode)                 # Child 6: Body
  if cmment: result.addComment()

