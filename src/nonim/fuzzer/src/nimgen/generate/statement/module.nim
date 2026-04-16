#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../identifier
import ../expression/affix
import ./comment as Comment


#_______________________________________
# @section Statement.Module Generation: import
#_____________________________
func Import *(
    info    : TLineInfo;
    entries : int    = 0;
    As      : string = "";
    From    : bool   = false;
    cmment  : bool   = R.bool();
  ) :PNode=
  let kind =
    if   From        : nkFromStmt
    elif entries > 0 : nkImportExceptStmt
    else             : nkImportStmt
  let name =
    if As == "": identifier.random(info)
    else       : affix.infix(info, op="as", left= identifier.random(info), right= identifier.random(info))
  result = newNodeI(kind, info)
  result.add(name)  # 0: Name
  for _ in 0..<entries: result.add(identifier.random(info))
  if cmment: result.addComment()


#_______________________________________
# @section Statement.Module Generation: include
#_____________________________
func Include *(
    info   : TLineInfo;
    cmment : bool = R.bool();
  ) :PNode=
  result = newNodeI(nkIncludeStmt, info)
  result.add(identifier.random(info))  # 0: Name
  if cmment: result.addComment()


#_______________________________________
# @section Statement.Module Generation: Entry Point
#_____________________________
func random *(
    info : TLineInfo;
  ) :PNode=
  case R.integer(4)
  of 1: module.Include(info)
  of 2: module.Import(info, As= identifier.name())
  of 3: module.Import(info, As= identifier.name(), entries= R.integer(5))
  of 4: module.Import(info, entries= R.integer(6))
  else: module.Import(info)

