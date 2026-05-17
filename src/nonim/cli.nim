#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared CLI options for all nonim backends.
#_______________________________________________________________|
# @deps std
import std/os
import std/parseopt


type Backend *{.pure.}= enum
  minc    ## Untyped path: parse only, no semantic analysis.
  cleanc  ## Typed path: full semantic analysis before codegen.

type Command *{.pure.}= enum
  codegen  ## Generate C code only.
  compile  ## Generate C and compile to binary.
  run      ## Generate, compile, and execute.

type Dir * = object
  bin   *:string= "bin"
  cache *:string= "bin/.cache"
  code  *:string= ""

type Options * = object
  backend  *:Backend
  command  *:Command
  input    *:string
  output   *:string
  dir      *:Dir
  verbose  *:bool
  quiet    *:bool


proc options_parse *(args :seq[string]= commandLineParams()) :Options=
  result = Options(
    backend: Backend.cleanc,
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
      of "backend":
        case parser.val
        of "minc":   result.backend = Backend.minc
        of "cleanc": result.backend = Backend.cleanc
        else: discard
      else: discard
    of cmdArgument:
      case positional_index
      of 0:
        case parser.key
        of "c":   result.command = Command.compile
        of "cc":  result.command = Command.codegen
        of "r":   result.command = Command.run
        else:     result.input = parser.key
      of 1: result.input = parser.key
      of 2: result.output = parser.key
      else: discard
      positional_index += 1

  if result.output.len == 0 and result.input.len > 0:
    result.output = result.input.changeFileExt("")
  if result.dir.code.len == 0:
    result.dir.code = getCurrentDir()
