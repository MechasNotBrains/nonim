#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random
import ../identifier
import ../expression
import ./comment as Comment


#_______________________________________
# @section Variable Generation
#_____________________________
func runtime (
    info    : TLineInfo;
    public  : bool     = false;
    mutable : bool     = true;
    cmment  : bool     = random.bool();
    T       : string   = random.typename();
    count   : Positive = 1;
  ) :PNode=
  # Create let/var declaration node
  let kind = if mutable: nkVarSection else: nkLetSection
  result = newNodeI(kind, info)
  for id in 1..count:
    let identDefs = newNodeI(nkIdentDefs, info)
    identDefs.add(identifier.random(info, public))  # Child 0: Name (with export)
    identDefs.add(identifier.typ(info, T))          # Child 1: Type
    identDefs.add(expression.random(info, T))       # Child 2: Value
    # {.cast(noSideEffect).}: # Adding comments to nodes is safe
    #   if cmment: identDefs.comment = Comment.random()
    result.add(identDefs)
#___________________
func comptime (
    info    : TLineInfo;
    public  : bool     = false;
    cmment  : bool     = random.bool();
    T       : string   = random.typename();
    count   : Positive = 1;
  ) :PNode=
  # Create const declaration node
  result = newNodeI(nkConstSection, info)
  for id in 1..count:
    let constDef = newNodeI(nkConstDef, info)
    constDef.add(identifier.random(info, public))  # Child 0: Name (with export)
    constDef.add(identifier.typ(info, T))          # Child 1: Type
    constDef.add(expression.random(info, T))       # Child 2: Value
    # {.cast(noSideEffect).}: # Adding comments to nodes is safe
    #   if cmment: constDef.comment = Comment.random()
    result.add constDef


#_______________________________________
# @section Variable Generation: Entry Point
#_____________________________
func random *(
    info    : TLineInfo;
    public  : bool   = random.bool();
    mutable : bool   = random.bool();
    runtime : bool   = random.bool();
    comment : bool   = random.bool();
    T       : string = random.typename();
  ) :PNode=
  if runtime : variable.runtime(info, public, mutable, comment, T)
  else       : variable.comptime(info, public, comment, T)

