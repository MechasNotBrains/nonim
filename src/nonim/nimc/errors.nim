#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import "$nim"/compiler/[options, lineinfos, msgs]


#_______________________________________
# @section Errors
#_____________________________
type NimcError * = object of CatchableError


#_______________________________________
# @section Callbacks
#_____________________________
var errorStr :string
proc errorAST *(conf :ConfigRef; info :TLineInfo; msg :TMsgKind; arg :string)=
  if errorStr.len == 0 and msg <= errMax:
    errorStr = formatMsg(conf, info, msg, arg)
    debugEcho errorStr
