#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared output pipeline: write, format, compile, run.
#_______________________________________________________________|
# @deps std
import std/os
# @deps nonim
import ../cli
import ../codegen/output
from minibuild as B import build, format


proc make_target *(options :Options; sources :seq[string]) :B.Target=
  var cfg = B.Config()
  cfg.c.format.active = true
  cfg.dir.bin = options.dir.bin
  result = B.target(B.Kind.Program, sources[0], options.output, sources, cfg)


proc ext_src *(options :Options) :string=
  case options.backend
  of Backend.minz, Backend.zig: ".zig"
  else: ".c"

proc ext_hdr *(options :Options) :string=
  case options.backend
  of Backend.minz, Backend.zig: ".h.zig"
  else: ".h"


proc write_output *(options :Options; output :Output; trg :B.Target) =
  createDir(options.dir.cache)
  createDir(options.dir.code)
  let src = options.ext_src()
  let hdr = options.ext_hdr()
  for index, module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    let cache_src = options.dir.cache/name.changeFileExt(src)
    let code_src  = options.dir.code/name.changeFileExt(src)
    if module.definitions.len > 0:
      writeFile(cache_src, module.definitions)
      trg.format(cache_src)
      copyFile(cache_src, code_src)
    if module.declarations.len > 0:
      let cache_h = options.dir.cache/name.changeFileExt(hdr)
      let code_h  = options.dir.code/name.changeFileExt(hdr)
      writeFile(cache_h, module.declarations)
      trg.format(cache_h)
      copyFile(cache_h, code_h)


proc sources_collect *(options :Options; output :Output) :seq[string]=
  for module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    if module.definitions.len > 0:
      result.add(options.dir.cache/name.changeFileExt(options.ext_src()))


proc run *(options :Options; output :Output) =
  if options.input.len == 0:
    quit("nonim: no input file provided", 1)
  let sources = options.sources_collect(output)
  let trg = options.make_target(sources)
  options.write_output(output, trg)
  case options.command
  of Command.codegen: discard
  of Command.compile: trg.build()
  of Command.run:     trg.build(run = true)
