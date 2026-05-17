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


proc write_output *(options :Options; output :Output; trg :B.Target) =
  createDir(options.dir.cache)
  createDir(options.dir.code)
  for index, module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    let cache_c = options.dir.cache/name.changeFileExt(".c")
    let cache_h = options.dir.cache/name.changeFileExt(".h")
    let code_c  = options.dir.code/name.changeFileExt(".c")
    let code_h  = options.dir.code/name.changeFileExt(".h")
    if module.definitions.len > 0:
      writeFile(cache_c, module.definitions)
      trg.format(cache_c)
      copyFile(cache_c, code_c)
    if module.declarations.len > 0:
      writeFile(cache_h, module.declarations)
      trg.format(cache_h)
      copyFile(cache_h, code_h)


proc sources_collect *(options :Options; output :Output) :seq[string]=
  for module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    if module.definitions.len > 0:
      result.add(options.dir.cache/name.changeFileExt(".c"))


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
