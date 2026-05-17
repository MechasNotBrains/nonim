#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
import minitest
import std/os
import std/strutils
import std/strformat
# @deps compiler
import "$nim"/compiler/[ options, lineinfos, msgs, pathutils, ast ]
# @deps nim.gen
import ../generate
# @deps nim.gen.tests
import ../tests/base


const TmplTestCode = """
# Generated test code - testing variable declarations
proc testVariables()=
$1

when isMainModule:
  testVariables()
"""


describe "nonim.fuzzer | Variable Generation Tests":
  let testCacheDir = "bin/.tests/variable"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("variable", &"variables{testID}.nim", testCode)
    testID.inc

  it "must generate compilable var declarations", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=true, runtime=true, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    compileTest(declarations).ok()

  it "must generate compilable let declarations", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=false, runtime=true, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    compileTest(declarations).ok()

  it "must generate compilable const declarations", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=false, runtime=false, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    compileTest(declarations).ok()
