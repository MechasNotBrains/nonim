#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Preprocessor for the untyped backends.
#________________________________________________________|
# @deps std
from std/os import `/`, parentDir, splitFile, absolutePath, fileExists
from std/sets import HashSet, initHashSet, containsOrIncl
from std/strutils import startsWith, splitLines, strip, split


proc isRecursiveInclude (line :string) :bool=
  if not line.startsWith("include "): return false
  let path = line[8..^1].strip()
  if path.len == 0: return false
  if '@' in path: return false
  let (_, _, ext) = path.splitFile()
  return ext == ""


const includeExtensions = [".nim", ".cm", ".zm"]
proc resolveIncludePath (line :string; baseDir :string) :string=
  let path = line[8..^1].strip()
  for ext in includeExtensions:
    let candidate = absolutePath(baseDir/path & ext)
    if fileExists(candidate): return candidate
  return ""


proc processIncludesImpl (source :string; baseDir :string; seen :var HashSet[string]) :string=
  for line in source.splitLines():
    if isRecursiveInclude(line):
      let path = resolveIncludePath(line, baseDir)
      if path.len == 0 or seen.containsOrIncl(path):
        continue
      let contents = readFile(path)
      let includeDir = path.parentDir()
      result.add processIncludesImpl(contents, includeDir, seen)
    else:
      result.add line & "\n"


proc processIncludes *(source :string; inputPath :string) :string=
  ## Resolves extensionless `include` lines by recursively
  ## inlining the referenced source files before parsing.
  ## Searches for `.nim`, `.cm`, and `.zm` extensions.
  var seen = initHashSet[string]()
  let baseDir = inputPath.parentDir()
  return processIncludesImpl(source, baseDir, seen)

