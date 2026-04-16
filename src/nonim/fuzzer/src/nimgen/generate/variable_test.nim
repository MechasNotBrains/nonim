#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import std/unittest
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


suite "Variable Generation Tests":
  let testCacheDir = "bin/.tests/variable"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("variable", &"variables{testID}.nim", testCode)
    testID.inc

  test "Var declarations":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=true, runtime=true, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)

  test "Let declarations":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=false, runtime=true, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)

  test "Const declarations":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info    = newLineInfo(config, absPath, id, 0)
      let varNode = generate.statement_variable(info, mutable=false, runtime=false, public=false)
      declarations.add("  " & render.code((node: varNode, info: info)).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)
