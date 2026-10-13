#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/os import splitPath, `/`, fileExists, pcDir, parentDir
from std/strutils import replace
from std/options import get
import minitest
import ./json
from astTF import nil

const samplesDirectory {.strdefine.} = currentSourcePath().parentDir()/".."/".."/".."/"bin"/".lib"/"astTF"/"samples"

type TestCase = object
  title   :string
  parsed  :astTF.astTF

var cases :seq[TestCase]
for category in os.walkDir(samplesDirectory):
  if category.kind != pcDir: continue
  if category.path.splitPath().tail == "invalid": continue
  for sample in os.walkDir(category.path):
    if sample.kind != pcDir: continue
    let astFile = sample.path / "ast.atf"
    if not fileExists(astFile): continue
    let name = category.path.splitPath().tail & "/" & sample.path.splitPath().tail
    cases.add TestCase(
      title: "must be able to parse " & name,
      parsed: astFile.readFile().fromJson(),
    )

describe "nonim.ast.json | parse all samples":
  for index in 0 ..< cases.len:
    it cases[index].title, proc() =
      cases[index].parsed.data.modules.len.eq(1)

describe "nonim.ast.json | Stores":
  it "must parse the depths store", proc() =
    let input = """{ "root": 0, "data": { "modules": [{ "path": "", "source": "" }], "depths": [{ "indent": 1 }] } }"""
    input.fromJson().data.depths.get[0].indent.get.eq 1'u64

describe "nonim.ast.json | write all samples":
  for index in 0 ..< cases.len:
    it cases[index].title.replace("parse", "roundtrip"), proc() =
      let written = cases[index].parsed.toJson()
      written.fromJson().toJson().eq(written)

