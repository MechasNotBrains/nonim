#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, options, lineinfos, msgs, pathutils ]
from   "$nim"/compiler/renderer import renderTree, renderNoComments, renderNoPragmas
# @deps std
from std/strutils import replace
# @deps generator
import ./random
import ./generate/node


#_______________________________________
# @section AST Render tools
#_____________________________
# TODO: Move to its own render file
type RootData * = tuple[node :PNode, info :TLineInfo]
func renderConst *(root :RootData) :string=
  result = ""
  debugEcho "........................."
  for entry in root.node[0].sons:
    debugEcho entry.repr
#___________________
proc render *(
    root        : RootData;
    allowBlocks : bool = true;
  ) :string=
  # if root.node.kind == nkConstSection: return renderConst(root) # Remove const blocks
  result = renderTree(root.node, {renderNoComments, renderNoPragmas})


#_______________________________________
# @section RootData Generation
#_____________________________
proc root *(path :string) :RootData=
  let config  = newConfigRef()
  let absPath = AbsoluteFile(path)
  let info    = newLineInfo(config, absPath, 0, 0)
  let node    = newNodeI(nkStmtList, info)
  return (node:node, info:info)


#_______________________________________
# @section Code Generation: Generic
#_____________________________
proc codegen *(
    kind        : string = "variable";
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string=
  ## @descr Generates random Nim code of the given {@arg kind}
  ## @arg allowBlocks (default: false) Will allow generating let/var/const/etc blocks when true.
  doAssert kind in Nodes_all
  let root = generate.root(path)
  for _ in 0..<random.integer(128): root.node.add(node.random(root.info, kind))
  return generate.render(root, allowBlocks)


#_______________________________________
# @section Code Generation: Specific Nim Syntax
#_____________________________
proc variable *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string= "variable".codegen(path, allowBlocks)
  ## @descr Generates Nim code with random Variable statements
  ## @arg allowBlocks (default: false) Will allow generating let/var/const/etc blocks when true.
#___________________
proc procs *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string= "proc".codegen(path, allowBlocks)
  ## @descr Generates Nim code with random Variable statements
  ## @arg allowBlocks (default: false) Will allow generating let/var/const/etc blocks when true.


#_______________________________________
# @section Code Generation: All Nim Syntax
#_____________________________
proc nim *(
    path        : string = "generated.nim";
    allowBlocks : bool   = false;
  ) :string=
  ## @descr Generates random Nim code
  ## @arg allowBlocks (default: false) Will allow generating let/var/const/etc blocks when true.
  let root = generate.root(path)
  # Generate a random amount of TopLevel statements
  for _ in 0..<random.integer(128): root.node.add(node.random(root.info))
  # Convert the AST to a string
  return generate.render(root, allowBlocks)

