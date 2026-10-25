#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared CLI options for all nonim backends.
#_______________________________________________________________|
# @deps std
import std/os
import std/parseopt
from std/strutils import find, split
# @deps nonim
from minibuild import nil


type Backend *{.pure.}= enum
  minatf  ## Untyped path: parse only, no semantic analysis. Emits astTF.
  minc    ## Untyped path: parse only, no semantic analysis. Emits C.
  minz    ## Untyped path: parse only, no semantic analysis. Emits Zig.
  cleanc  ## Typed path: full semantic analysis before codegen. Emits C.
  zig     ## Typed path: full semantic analysis before codegen. Emits Zig.

proc parse *(_:typedesc[Backend]; name :string; fallback :Backend = Backend.minatf) :Backend=
  for backend in Backend:
    if $backend == name: return backend
  return fallback

type Command *{.pure.}= enum
  codegen  ## Generate C code only.
  compile  ## Generate C and compile to binary.
  run      ## Generate, compile, and execute.

type Zig * = object
  bin   *:string= "zig"
  cache *:string= ""

type System * = minibuild.ConfigSystem

type Files * = object
  c        *:seq[string]
  c_dir    *:seq[string]
  Include  *:seq[string]

type Dir * = object
  bin   *:string= "bin"
  cache *:string= "bin/.cache"
  code  *:string= ""
  src   *:string= ""

type Options * = object
  backend      *:Backend
  command      *:Command
  input        *:string
  output       *:string
  dir          *:Dir
  files        *:Files
  zig          *:Zig
  system       *:System
  verbose      *:bool
  quiet        *:bool
  pass_c       *:seq[string]
  link         *:seq[string]
  dependencies *:seq[tuple[name: string, subdeps: seq[string], path: string]]


proc options_parse *(
    args            : seq[string] = commandLineParams();
    default_backend : Backend     = Backend.cleanc;
  ) :Options=
  result = Options(
    backend: default_backend,
    command: Command.codegen,
  )
  var parser = initOptParser(args)
  var positional_index = 0

  while true:
    parser.next()
    case parser.kind
    of cmdEnd: break
    of cmdShortOption:
      case parser.key
      of "v": result.verbose = true
      of "q": result.quiet = true
      of "o": result.output = parser.val
      else: discard
    of cmdLongOption:
      case parser.key
      of "verbose":  result.verbose = true
      of "quiet":    result.quiet = true
      of "output":   result.output = parser.val
      of "binDir":   result.dir.bin = parser.val
      of "cacheDir": result.dir.cache = parser.val
      of "codeDir":  result.dir.code = parser.val
      of "zigBin":   result.zig.bin = parser.val
      of "zigCache": result.zig.cache = parser.val
      of "os":       result.system.os  = parser.val
      of "cpu":      result.system.cpu = parser.val
      of "abi":      result.system.abi = parser.val
      of "target":
        let parts = parser.val.split('-')
        result.system.cpu = parts[0]
        result.system.os  = if parts.len > 1: parts[1] else: ""
        result.system.abi = if parts.len > 2: parts[2] else: ""
      of "backend":    result.backend = Backend.parse(parser.val, result.backend)
      of "passC":      result.pass_c.add(parser.val)
      of "cfile":      result.files.c.add(parser.val)
      of "cdir":       result.files.c_dir.add(parser.val)
      of "include":    result.files.Include.add(parser.val)
      of "link":       result.link.add(parser.val)
      of "dependency":
        let name_sep = parser.val.find(':')
        if name_sep > 0:
          let dep_name = parser.val[0 ..< name_sep]
          let rest = parser.val[name_sep+1 .. ^1]
          let bracket_open = rest.find('[')
          let bracket_close = rest.find(']')
          if bracket_open >= 0 and bracket_close > bracket_open:
            let subdep_str = rest[bracket_open+1 ..< bracket_close]
            var subdeps :seq[string]
            if subdep_str.len > 0:
              for part in subdep_str.split(','): subdeps.add(part)
            let path_start = bracket_close + 2
            let dep_path = rest[path_start .. ^1]
            result.dependencies.add((name: dep_name, subdeps: subdeps, path: dep_path))
          else:
            result.dependencies.add((name: dep_name, subdeps: @[], path: rest))
      else: discard
    of cmdArgument:
      case positional_index
      of 0:
        case parser.key
        of "c":  result.command = Command.compile
        of "cc": result.command = Command.codegen
        of "r":  result.command = Command.run
        else: quit("nonim: invalid command '" & parser.key & "', expected c, cc, or r", 1)
      of 1: result.input = parser.key
      of 2: result.output = parser.key
      else: discard
      positional_index += 1

  result.quiet = result.quiet and not result.verbose
  if result.output.len == 0 and result.input.len > 0:
    result.output = result.input.changeFileExt("")

proc module_path *(options :Options) :string=
  let root = if options.dir.src.len > 0: options.dir.src else: options.input.parentDir()
  options.input.absolutePath().relativePath(root.absolutePath())

