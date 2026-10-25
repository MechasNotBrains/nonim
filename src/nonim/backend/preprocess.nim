#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Preprocessor for the untyped backends.
#________________________________________________________|
# @deps std
from std/os import parentDir, splitFile
from std/strutils import startsWith, splitLines, strip, split, find
from std/tables import Table, `[]=`
# @deps nonim
import ./includes

proc processIncludes *(source :string; inputPath :string) :string=
  includes.processIncludes(source, inputPath, includes.sourceExtensions)


proc importPath *(entry :string) :string=
  result = entry.strip()
  let pragma = result.find("{.")
  if pragma >= 0: result = result[0 ..< pragma].strip()
  let alias = result.find(" as ")
  if alias >= 0: result = result[0 ..< alias].strip()

proc importPaths *(line :string) :seq[string]=
  if line.startsWith("from "):
    let keyword = line.find(" import ")
    if keyword < 0: return
    return @[importPath(line[5 ..< keyword])]
  if not line.startsWith("import "): return
  for entry in line[7 .. ^1].split(','):
    result.add importPath(entry)

proc importFolder *(path :string) :string=
  if path.len == 0 or path.startsWith("@"): return ""
  if path.splitFile.ext.len > 0: return ""
  var relative = path
  if relative.startsWith("./"): relative = relative[2 .. ^1]
  if relative.startsWith(".."): return ""
  result = relative.parentDir()
  if result == ".": return ""

proc importFolders *(source :string) :seq[string]=
  for line in source.splitLines():
    for path in importPaths(line.strip()):
      let folder = importFolder(path)
      if folder.len == 0 or folder in result: continue
      result.add folder

proc importMap *(files :openArray[string]) :Table[string, seq[string]]=
  for file in files:
    result[file] = importFolders(readFile(file))
