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
from minibuild as B import build, format, ReportMode, Dependency, Dependencies


proc make_target *(options :Options; sources :seq[string]) :B.Target=
  var cfg = B.Config()
  cfg.dir.src = ""
  cfg.dir.bin = options.dir.bin
  if options.verbose: cfg.log.level = ReportMode.verbose
  case options.backend
  of Backend.minz, Backend.zig:
    cfg.zig.format.active = true
  else:
    cfg.c.format.active = true
  var flags :B.FlagsList
  for flag in options.pass_c: flags.add(flag)
  var deps :B.Dependencies
  if options.backend in {Backend.minz, Backend.zig}:
    for dep in options.dependencies:
      for subdep in dep.subdeps:
        flags.add("--dep")
        flags.add(subdep)
      flags.add("-M" & dep.name & "=" & dep.path)
    for dep in options.dependencies:
      deps.add(B.Dependency(name: dep.name, url: "", path: ""))
  result = B.target(B.Kind.Program, sources[0], options.output.splitFile.name, sources, cfg, flags, deps)


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
  let has_code_dir = options.dir.code.len > 0
  if has_code_dir: createDir(options.dir.code)
  let src = options.ext_src()
  let hdr = options.ext_hdr()
  for index, module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    let cache_src = options.dir.cache/name.changeFileExt(src)
    if module.definitions.len > 0:
      writeFile(cache_src, module.definitions)
      trg.format(cache_src)
      if has_code_dir: copyFile(cache_src, options.dir.code/name.changeFileExt(src))
    if module.declarations.len > 0:
      let cache_h = options.dir.cache/name.changeFileExt(hdr)
      writeFile(cache_h, module.declarations)
      trg.format(cache_h)
      if has_code_dir: copyFile(cache_h, options.dir.code/name.changeFileExt(hdr))


proc sources_collect *(options :Options; output :Output) :seq[string]=
  for module in output.modules:
    let name = if module.path.len > 0: module.path.splitFile.name
               else: options.output.splitFile.name
    if module.definitions.len > 0:
      result.add(options.dir.cache/name.changeFileExt(options.ext_src()))


proc link_imports *(options :Options) =
  let source_dir = options.input.absolutePath().parentDir()
  for entry in walkDir(source_dir, relative=false):
    if entry.kind != pcDir: continue
    let dirname = entry.path.lastPathPart()
    let link_path = options.dir.cache/dirname
    if symlinkExists(link_path): removeFile(link_path)
    createSymlink(entry.path, link_path)

proc run *(options :Options; output :Output) =
  if options.input.len == 0:
    quit("nonim: no input file provided", 1)
  let sources = options.sources_collect(output)
  let trg = options.make_target(sources)
  options.write_output(output, trg)
  case options.command
  of Command.codegen: discard
  of Command.compile:
    if options.backend in {Backend.minz, Backend.zig}: options.link_imports()
    trg.build()
  of Command.run:
    if options.backend in {Backend.minz, Backend.zig}: options.link_imports()
    trg.build(run = true)
