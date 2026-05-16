#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________


#_______________________________________
# @section Errors
#_____________________________
type NimcError * = object of CatchableError


#_______________________________________
# @section Callbacks
#_____________________________
var errorStr :string
proc errorAST *(conf :options.ConfigRef; info :lineinfos.TLineInfo; msg :lineinfos.TMsgKind; arg :string)=
  if errorStr.len == 0 and msg <= errMax:
    errorStr = msgs.formatMsg(conf, info, msg, arg)
    debugEcho errorStr

