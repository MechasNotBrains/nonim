#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ./variable
import ./procedure
import ./call
import ./module
import ./comment as Comment
import ./assignment
import ./Discard


#_______________________________________
# @section Statement Generation: Dispatch
#_____________________________
func generate *(
    info : TLineInfo;
    kind : TNodeKind;
  ) :PNode=
  result = case kind
  of nkVarSection, nkLetSection,
     nkConstSection              : variable.random(info)
  of nkProcDef                   : procedure.random(info)
  of nkCall                      : call.random(info)
  of nkCommand                   : call.random(info, command= true)
  of nkCommentStmt               : Comment.random(info)
  of nkAsgn                      : assignment.random(info)
  of nkDiscardStmt               : Discard.random(info)
  of nkImportStmt, nkFromStmt,
     nkImportExceptStmt,
     nkIncludeStmt               : module.random(info)
  else                           : newNodeI(nkEmpty, info)
