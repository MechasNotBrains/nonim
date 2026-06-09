#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared codegen helpers used by all backends.
#_______________________________________________________________|
from std/options import isSome, isNone, get, Option
from std/sequtils import toSeq
from std/strutils import join
import ../ast as astTF
from ./output import Output, string

#_______________________________________
# @section Error Management
#_____________________________
type BaseCodegenError = object of CatchableError
#___________________
proc fail *(
    err  : typedesc;
    msg  : static string;
    args : varargs[string, `$`];
  ) :void {.noreturn.}= raise newException(err, (@["[nonim.codegen]", msg] & args.toSeq).join(" "))


#_______________________________________
# @section Source String Helpers
#_____________________________
func type_name *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : astTF.Id;
  ) :string=
  result   = "_"
  let name = astTF.type_name(ast, id)
  if not name.isSome: fail BaseCodegenError, "base.type_name: Tried to access the name of a type that has no name."
  result = ast.source(module, name.get)


#_______________________________________
# @section Formatting
#_____________________________
const format_Newline * = "\n"
const format_Space   * = " "
const format_Tab     * = format_Space & format_Space
#___________________
func format_before *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : Option[astTF.Id];
    Out    : var Output;
    indent : string = " ";
  ) :void=
  if id.isNone: return
  let fmt = ast.format(id.get)
  for _ in 0..<fmt.newlines.get(0) : Out.string(module, format_Newline, output.Target.definition)
  for _ in 0..<fmt.indent.get(0)   : Out.string(module, format_Tab,     output.Target.definition)
  for _ in 0..<fmt.before.get(0)   : Out.string(module, format_Space,   output.Target.definition)
#___________________
func format_after *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : Option[astTF.Id];
    Out    : var Output;
  ) :void=
  if id.isNone: return
  let fmt = ast.format(id.get)
  for _ in 0..<fmt.after.get(0): Out.string(module, format_Space, output.Target.definition)
#___________________
func format_comment *(
    ast    : astTF.Ast;
    module : astTF.Id;
    id     : Option[astTF.Id];
    Out    : var Output;
  ) :void=
  if id.isNone: return
  let fmt = ast.format(id.get)
  for _ in 0..<fmt.comment.get(0): Out.string(module, format_Space, output.Target.definition)


#_______________________________________
# FIX: REMOVE COMPLETELY. DO NOT USE AT ALL
#_____________________________
func node_depth *(ast :astTF.Ast; depth_id :Option[astTF.Id]) :int=
  result = 0
  if depth_id.isNone: return
  let depth = ast.depth(depth_id.get)
  if depth.indent.isSome: result = depth.indent.get.int

