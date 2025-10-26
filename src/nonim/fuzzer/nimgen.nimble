#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# Package Info
packageName = "nimgen"
version     = "0.0.0"
author      = "heysokam"
description = "codegen.nim | Random Code Generator for the Nim Programming Language"
license     = "GPL-3.0-or-later"
#___________________
# Folders
srcDir  = "src"
binDir  = "bin"
#___________________
# Build Options
backend = "c"
bin     = @["nimgen"]
#___________________
# Build requirements
requires "nim >= 2.0.0"


#_______________________________________
# Tasks: Internal
#_____________________________
# @deps std
import std/strformat
import std/os
#___________________
task tests, "Internal:  Runs all unit tests of the project.":
  if dirExists("./bin/.tests"): rmDir("./bin/.tests")
  for testFile in os.walkDirRec("./src", yieldFilter= {pcFile}, relative= false):
    if not testFile.endsWith("_test.nim"): continue
    selfExec &"c -r --hints:off --warnings:off --outDir:./bin/.tests {testFile}"

