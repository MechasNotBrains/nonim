#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import std/os


proc compileTest *(
    subDir       : string;
    fileName     : string;
    code         : string;
    semaRequired : bool = true;
  ) :bool=
  let testsDir = "bin/.tests"/subDir # Explicit tests dir for this test
  let cacheDir = testsDir/"nimcache" # Explicit cache dir for this test
  let filePath = os.joinPath(testsDir, fileName) # Path inside tests dir
  # Cleanup previous run artifacts before the test
  if not dirExists(cacheDir) : createDir(cacheDir)
  if fileExists(filePath)    : removeFile(filePath)
  # Compile the generated code
  writeFile(filePath, code)
  # Check with nim
  var command = "nim check --hints:off --warnings:off --nimcache:" & cacheDir & " " & filePath
  if os.execShellCmd(command) == 0: return true
  if semaRequired: return false
  # Check syntax with simplified parser (no semantics)
  command = "./bin/nimcheck " & filePath
  return os.execShellCmd(command) == 0

