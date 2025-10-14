#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, options, lineinfos, msgs, pathutils ]
from   "$nim"/compiler/renderer import renderTree, renderNoComments, renderNoPragmas
# @deps generator
import ./random
import ./generate/procedure as gen_proc
import ./generate/statement/variable as gen_variable


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
  if root.node.kind == nkConstSection: return renderConst(root) # Remove const blocks
  renderTree(root.node, {renderNoComments, renderNoPragmas})


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
  doAssert kind in ["variable", "proc"]
  let root = generate.root(path)
  for _ in 0..<random.integer(128):
    case kind
    of "variable" : root.node.add gen_variable.random(root.info)
    of "proc"     : root.node.add gen_proc.random(root.info)
    else:discard # unreachable
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
  for _ in 0..<random.integer(128):
    case random.integer(1):
    of 0: root.node.add gen_variable.random(root.info)
    of 1: root.node.add gen_proc.random(root.info)
    else:discard

  # Convert the AST to a string
  return generate.render(root, allowBlocks)

