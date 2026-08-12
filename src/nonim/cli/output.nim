#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared output pipeline: write, format, compile, run.
#_______________________________________________________________|
# @deps std
import std/os
from std/sets import HashSet, initHashSet, containsOrIncl, contains
from std/strutils import startsWith, splitLines, strip
# @deps nonim
import ../cli
import ../codegen/output
import ../backend/includes
from minibuild as B import build, format, format_exec, ReportMode, Dependency, Dependencies

type GenerateProc * = proc (options :Options) :Output {.nimcall.}


proc make_target *(options :Options; sources :seq[string]) :B.Target=
  var cfg = B.Config()
  cfg.dir.src = ""
  cfg.dir.bin = options.dir.bin
  cfg.zig.bin = options.zig.bin
  cfg.zig.cache = options.zig.cache
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
  result = B.target(B.Kind.Program, sources[0], options.output.splitFile.name, sources[1..^1], cfg, flags, deps)


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

proc source_ext *(backend :Backend) :string=
  ## Source extension a folder-codegen pass collects for each backend.
  ## `.nim` is intentionally excluded: it is not a minz/minc input.
  case backend
  of Backend.minc: ".cm"
  of Backend.minz: ".zm"
  else:            ""


proc scan_includes (file :string; merged :var HashSet[system.string]) =
  ## Records every file pulled in via `include` (transitively) so the folder
  ## driver can skip emitting standalone output for merged sources.
  if not fileExists(file): return
  let base = file.parentDir()
  for raw in readFile(file).splitLines():
    let line = raw.strip()
    if not line.startsWith("include "): continue
    var path = line[8 .. ^1].strip()
    if path.startsWith("@"): path = path[1 .. ^1]
    if path.len == 0: continue
    let resolved = includes.resolveFile(path, base, includes.sourceExtensions)
    if resolved.len > 0 and not merged.containsOrIncl(resolved):
      scan_includes(resolved, merged)


proc run_folder (options :Options; generate :GenerateProc) =
  let extension  = options.backend.source_ext()
  let out_ext    = options.ext_src()
  let input_root = options.input.absolutePath()
  let out_root   = if options.output.len > 0 and options.output.absolutePath() != input_root: options.output
                   else: options.input/options.dir.bin
  var files :seq[system.string]
  for path in walkDirRec(options.input):
    if path.splitFile.ext == extension: files.add path.absolutePath()
  var merged = initHashSet[system.string]()
  for file in files: scan_includes(file, merged)
  var processed_count = 0
  for file in files:
    if file in merged: continue
    var per_file = options
    per_file.input = file
    let relative = file.relativePath(input_root)
    let out_file = out_root/relative.changeFileExt(out_ext)
    createDir(out_file.parentDir())
    if options.verbose:
      echo "generating:  " & out_file
    elif not options.quiet:
      stdout.write "."
      stdout.flushFile()
    let output = generate(per_file)
    if options.verbose:
      for parse_error in output.parse_errors:
        echo "  error:  " & parse_error.message
    if output.modules.len == 0 or output.modules[0].definitions.len == 0: continue
    writeFile(out_file, output.modules[0].definitions)
    let trg = per_file.make_target(@[out_file])
    if options.verbose:
      echo "formatting:  " & out_file
    elif not options.quiet:
      stdout.write "."
      stdout.flushFile()
    trg.format_exec(out_file)
    processed_count += 1
  if not options.verbose and not options.quiet and processed_count > 0:
    stdout.write "\n"
    stdout.flushFile()


proc run *(options :Options; generate :GenerateProc) =
  if options.input.len == 0:
    quit("nonim: no input file provided", 1)
  if options.backend in {Backend.minz, Backend.minc} and dirExists(options.input):
    options.run_folder(generate)
    return
  var opts = options
  opts.dir.cache = options.dir.cache / options.output.splitFile.name
  let output = generate(opts)
  let sources = opts.sources_collect(output)
  let trg = opts.make_target(sources)
  opts.write_output(output, trg)
  case opts.command
  of Command.codegen: discard
  of Command.compile:
    if opts.backend in {Backend.minz, Backend.zig}: opts.link_imports()
    trg.build()
  of Command.run:
    if opts.backend in {Backend.minz, Backend.zig}: opts.link_imports()
    trg.build(run = true)
