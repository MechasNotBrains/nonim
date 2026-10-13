#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import splitFile, createDir, `/`
from std/options import some, isNone, get
from std/strutils import toLowerAscii
# @deps nonim
import ../cli
import ../cli/output as cli_output
import ../nimc/Untyped
import ../ast as astTF
import ../codegen/C
import ../codegen/zig
import ../codegen/nim
import ../codegen/output
import ./preprocess


proc language_name (language :Language) :string= ($language).toLowerAscii()


proc backend (input :string) :Backend=
  for backend in Backend:
    if backend.source_ext().len == 0 or input.splitFile.ext != backend.source_ext(): continue
    return backend
  return Backend.minatf

proc backend_convert (backend :Backend) :Language=
  case backend
  of Backend.minc: Language.C
  else:            Language.Nim

proc backend_language (backend :Backend) :string=
  if backend.source_ext().len > 0: return $backend
  return Language.Nim.language_name()


proc atf *(options :Options) :astTF.Ast=
  let backend = options.input.backend()
  let source  = preprocess.processIncludes(readFile(options.input), options.input)
  let root    = Untyped.compile(source, options.input)
  result = root.convert(backend.backend_convert(), typed=false, options.input)
  result.metadata = some(astTF.Metadata(language: some(backend.backend_language())))


proc extension *(language :string) :string=
  let backend = Backend.parse(language)
  if backend.source_ext().len > 0: return backend.source_ext()
  return "." & Language.parse(language).language_name()

proc generate (ast :astTF.Ast; language :string) :Output=
  if Backend.parse(language).source_ext().len > 0: return ast.nim()
  case Language.parse(language)
  of Language.C:   result = ast.C()
  of Language.Zig: result = ast.zig()
  of Language.Nim: result = ast.nim()

proc language (ast :astTF.Ast) :string=
  if ast.metadata.isNone: return ""
  return ast.metadata.get.language.get("")


proc generate *(options :Options) :Output=
  let ast = astTF.fromJson(readFile(options.input))
  return ast.generate(ast.language())


proc run *(options :Options) =
  if options.input.splitFile.ext == ".atf":
    let ast = astTF.fromJson(readFile(options.input))
    options.run_output(ast.generate(ast.language()), ast.language().extension())
    return
  createDir(options.dir.bin)
  writeFile(options.dir.bin/options.output.splitFile.name & ".atf", options.atf().toJson())
