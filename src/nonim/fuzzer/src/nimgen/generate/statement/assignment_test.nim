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
import ../../generate
import ./assignment
# @deps nim.gen.tests
import ../../tests/base


const TmplTestCode = """
# Generated test code - testing assignment statements
$1
"""


suite "Assignment Generation Tests":
  let testCacheDir = "bin/.tests/assignment"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("assignment", &"assignments{testID}.nim", testCode, semaRequired= false)
    testID.inc

  test "Assignment statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = assignment.random(info)
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)
