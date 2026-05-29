#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import "$nim"/compiler/[options, lineinfos, msgs]


#_______________________________________
# @section Errors
#_____________________________
type NimcError * = object of CatchableError

type ParseError * = object
  message  *:string
  kind     *:TMsgKind
  arg      *:string
  line     *:int
  column   *:int
  file     *:string


#_______________________________________
# @section Collection
#_____________________________
var collected *{.threadvar.}:seq[ParseError]

proc errors_clear *() =
  collected.setLen(0)


#_______________________________________
# @section Callbacks
#_____________________________
proc errorAST *(conf :ConfigRef; info :TLineInfo; msg :TMsgKind; arg :string)=
  if msg <= errMax:
    collected.add(ParseError(
      message: formatMsg(conf, info, msg, arg),
      kind:    msg,
      arg:     arg,
      line:    info.line.int,
      column:  info.col.int,
      file:    toFilename(conf, info),
    ))
