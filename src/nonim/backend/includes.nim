#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Shared include resolution for untyped backends.
## Used by both preprocess (before parsing) and
## postprocess (after codegen) stages.
#________________________________________________________|
# @deps std
from std/os import `/`, parentDir, splitFile, absolutePath, fileExists
from std/sets import HashSet, initHashSet, containsOrIncl
from std/strutils import startsWith, splitLines, strip


const sourceExtensions * = [".nim", ".cm", ".zm"]


proc resolveFile *(path :string; baseDir :string; extensions :openArray[string] = @[]) :string=
  if extensions.len > 0:
    for ext in extensions:
      let candidate = absolutePath(baseDir/path & ext)
      if fileExists(candidate): return candidate
  else:
    let candidate = absolutePath(baseDir/path)
    if fileExists(candidate): return candidate
  return ""


proc processImpl (source :string; baseDir :string; seen :var HashSet[string]; extensions :openArray[string]) :string=
  let lines = source.splitLines()
  for i in 0 ..< lines.len:
    if i == lines.len - 1 and lines[i].len == 0: break
    let line = lines[i]
    if line.startsWith("include "):
      var path = line[8..^1].strip()
      if path.startsWith("@"): path = path[1..^1]
      if path.len > 0:
        let resolved = resolveFile(path, baseDir, extensions)
        if resolved.len > 0 and not seen.containsOrIncl(resolved):
          result.add processImpl(readFile(resolved), resolved.parentDir(), seen, extensions)
          continue
    result.add line & "\n"


proc processIncludes *(source :string; inputPath :string; extensions :openArray[string] = @[]) :string=
  var seen = initHashSet[string]()
  return processImpl(source, inputPath.parentDir(), seen, extensions)
