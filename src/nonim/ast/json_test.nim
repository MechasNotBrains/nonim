#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from std/os import splitPath, `/`, fileExists, pcDir, parentDir
from std/strutils import startsWith
from std/sugar import capture
import minitest
import ./json

const samplesDirectory {.strdefine.} = currentSourcePath().parentDir()/".."/".."/".."/"bin"/".lib"/"astTF"/"samples"

describe "nonim.ast.json | parse all samples":
  for category in os.walkDir(samplesDirectory):
    if category.kind != pcDir: continue
    if category.path.splitPath().tail == "invalid": continue
    for sample in os.walkDir(category.path):
      if sample.kind != pcDir: continue
      let astFile = sample.path / "ast.atf"
      if not fileExists(astFile): continue
      let name = category.path.splitPath().tail & "/" & sample.path.splitPath().tail
      capture astFile, name:
        it "must be able to parse " & name, proc() =
          let content = astFile.readFile()
          let parsed  = content.fromJson()
          parsed.data.modules.len.eq(1)

