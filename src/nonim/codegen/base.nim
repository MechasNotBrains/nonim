#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared codegen helpers used by all backends.
#_______________________________________________________________|
from std/options import isSome, isNone, get, Option
import ../ast as astTF


func node_depth *(ast :astTF.Ast; depth_id :Option[astTF.Id]) :int=
  if depth_id.isNone: return 0
  let depth = ast.data.depths.get[depth_id.get]
  if depth.indent.isSome: return int(depth.indent.get)
  return 0
