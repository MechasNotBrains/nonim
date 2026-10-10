#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import `/`, parentDir, walkDirs, walkFiles
# @deps nimc
import "$nim"/compiler/[ast]
# @deps nonim
import ../nimc/Untyped


const cases_dir = currentSourcePath().parentDir()/"test"/"cases"
const filter :set[TNodeKind]= {
  nkNone, nkSym, nkType, nkComesFrom, nkDotCall, nkHiddenCallConv,
  nkCheckedFieldExpr, nkClosedSymChoice, nkOpenSymChoice, nkOpenSym,
  nkHiddenStdConv, nkHiddenSubConv, nkConv, nkAddr, nkHiddenAddr, nkHiddenDeref, nkDerefExpr,
  nkObjDownConv, nkObjUpConv, nkChckRangeF, nkChckRange64, nkChckRange, nkRange,
  nkStringToCString, nkCStringToString, nkFastAsgn, nkSinkAsgn,
  nkBlockType, nkStmtListType, nkParForStmt, nkPattern, nkHiddenTryStmt, nkClosure,
  nkGotoState, nkState, nkBreakState, nkError, nkModuleRef, nkReplayAction, nkNilRodNode,
}


proc node_kinds (node :PNode; found :var set[TNodeKind]) =
  if node.isNil: return
  found.incl(node.kind)
  for index in 0 ..< node.safeLen: node_kinds(node[index], found)

proc case_kinds () :set[TNodeKind]=
  for case_dir in walkDirs(cases_dir/"*"):
    for input_path in walkFiles(case_dir/"input*.nim"):
      node_kinds(Untyped.compile(readFile(input_path), input_path), result)


when isMainModule:
  let covered = case_kinds()
  for kind in TNodeKind:
    if kind in covered: continue
    if kind in filter: continue
    echo kind
