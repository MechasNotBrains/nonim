#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import nil
from std/strutils import join, toHex
from std/strformat import `&`
# @deps nim.gen
import ./random
import ./generate

#_______________________________________
# @section nim.gen Logging
#_____________________________
func info *(msg :varargs[string, `$`]) :void=
  debugEcho "[nim.gen] " & msg.join(" ")


#_______________________________________
# @section nim.gen Entry Point
#_____________________________
proc run *(args :seq[string]) :void=
  doAssert args.len in {2,3}
  let choice = args[0]
  let file   = args[1]
  let dir    = os.splitFile(file).dir
  let seed   = if args.len > 2: args[2] else: random.integer().toHex()
  random.init(seed)
  # Validate Arguments
  doAssert choice in ["all", "variable", "proc"]
  doAssert not os.fileExists(file)
  # Report to CLI
  info(&"Generating {choice} code at {file} with seed {seed}")
  # Run the generator
  let code = case choice # FIX: Pass allowBlocks option from cli
  of "variable" : generate.variable()
  of "proc"     : generate.procs()
  else          : generate.nim()
  # Write to the file
  if not os.dirExists(dir): os.createDir dir
  file.writeFile(code)
  when defined(debug): echo code

