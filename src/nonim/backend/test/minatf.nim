#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/os import `/`, parentDir, createDir
from std/options import some, get
from std/strutils import toLowerAscii
# @deps tests
import minitest
# @deps nonim
import ../../backend/minatf
import ../../ast as astTF
import ../../codegen/C
import ../../cli
from ../../cli/output import source_ext


const cases_dir = currentSourcePath().parentDir()/"cases"
const tmp_dir   = "./bin/.tests/minatf"

proc case_expected_c (name :string) :string=
  readFile(cases_dir/name/"expected.c")

proc case_expected_h (name :string) :string=
  readFile(cases_dir/name/"expected.h")


describe "nonim.minatf | astTF to Target":
  it "must generate a procedure declaration from an .atf file", proc() =
    let options = options_parse(@["--backend:minatf", "cc", cases_dir/"atf_procedure_declaration"/"input.atf"])
    minatf.generate(options).modules[0].definitions.eq case_expected_c("atf_procedure_declaration")
    minatf.generate(options).modules[0].declarations.eq case_expected_h("atf_procedure_declaration")

  it "must write each module into the code directory under its module path", proc() =
    let options = options_parse(@["--backend:minatf", "--cacheDir:" & tmp_dir/"cache", "--codeDir:" & tmp_dir/"code", "cc", cases_dir/"atf_module_path"/"input.atf"])
    minatf.run(options)
    readFile(tmp_dir/"code"/"api"/"utility.h").eq case_expected_h("atf_module_path")

proc atf_generate (language :string) =
  let input = tmp_dir/language/"input.atf"
  var ast   = readFile(cases_dir/"atf_target"/"input.atf").fromJson()
  ast.metadata = some(Metadata(language: some(language)))
  createDir(input.parentDir())
  writeFile(input, ast.toJson())
  let options = options_parse(@["--backend:minatf", "--cacheDir:" & tmp_dir/language/"cache", "--codeDir:" & tmp_dir/language/"code", "cc", input])
  minatf.run(options)
  let extension = minatf.extension(language)
  readFile(tmp_dir/language/"code"/"api"/("utility" & extension)).eq readFile(cases_dir/"atf_target"/("expected" & extension))
  if language != ($Language.C).toLowerAscii(): return
  readFile(tmp_dir/language/"code"/"api"/"utility.h").eq case_expected_h("atf_target")

describe "nonim.minatf | astTF to every Language":
  for language in Language:
    it "must generate the " & $language & " language declared by the .atf", proc() =
      atf_generate(($language).toLowerAscii())

describe "nonim.minatf | astTF to every Backend source":
  for backend in Backend:
    if backend.source_ext().len == 0: continue
    it "must generate the " & $backend & " source declared by the .atf", proc() =
      atf_generate($backend)

describe "nonim.minatf | Source to astTF":
  it "must convert a source file to astTF", proc() =
    let options = options_parse(@["--backend:minatf", "c", cases_dir/"atf_from_lang"/"input.nim"])
    minatf.atf(options).C().modules[0].definitions.eq case_expected_c("atf_from_lang")
    minatf.atf(options).C().modules[0].declarations.eq case_expected_h("atf_from_lang")

  it "must declare nim as the language of a nim source file", proc() =
    let options = options_parse(@["--backend:minatf", "c", cases_dir/"atf_from_lang"/"input.nim"])
    minatf.atf(options).metadata.get.language.get.eq "nim"

  it "must declare minc as the language of a minc source file", proc() =
    let options = options_parse(@["--backend:minatf", "c", cases_dir/"atf_from_lang"/"input.cm"])
    minatf.atf(options).metadata.get.language.get.eq "minc"

  it "must declare minz as the language of a minz source file", proc() =
    let options = options_parse(@["--backend:minatf", "c", cases_dir/"atf_from_lang"/"input.zm"])
    minatf.atf(options).metadata.get.language.get.eq "minz"

  it "must write the astTF of a source file into a single .atf file", proc() =
    let options = options_parse(@["--backend:minatf", "--binDir:" & tmp_dir, "c", cases_dir/"atf_from_lang"/"input.nim"])
    minatf.run(options)
    let written = readFile(tmp_dir/"input.atf").fromJson()
    written.C().modules[0].definitions.eq case_expected_c("atf_from_lang")
    written.C().modules[0].declarations.eq case_expected_h("atf_from_lang")
