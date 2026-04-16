#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, lineinfos ]
# @deps nim.gen
import ../../random as R
import ../identifier
import ../expression
import ./comment as Comment


func node *(
    info : TLineInfo;
    name : string         = identifier.name();
    args : openArray[PNode] = [];
  ) :PNode=
  result = newNodeI(nkCall, info)
  result.add(identifier.node(info, name))
  for arg in args: result.add(arg)
#___________________
func random *(
    info   : TLineInfo;
    args   : int  = R.integer(16);
    cmment : bool = R.bool();
  ) :PNode=
  # @workaround nkCommand renderer bug: command syntax wraps long lines without
  #   parens, producing invalid indentation. See: renderer.nim:1227-1237
  const CallIdentLen = when defined(NimCompilerBug_CommandIndent): 64 else: 8
  result = newNodeI(if R.bool(): nkCall else: nkCommand, info)
  result.add(identifier.random(info, length= R.integer(1..CallIdentLen)))
  for _ in 0..<args: result.add(expression.random(info))
  if cmment: result.addComment()

