#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/os import splitPath, `/`, fileExists, pcDir, parentDir
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

