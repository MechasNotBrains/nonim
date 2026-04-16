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
import ./procedure
# @deps nim.gen.tests
import ../../tests/base


const TmplTestCode = """
# Generated test code - testing procedure declarations
$1
"""


suite "Procedure Generation Tests":
  let testCacheDir = "bin/.tests/procedure"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("procedure", &"procedures{testID}.nim", testCode, semaRequired= false)
    testID.inc

  test "Procedure declarations":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..16:
      let info = newLineInfo(config, absPath, id, 0)
      let node = procedure.random(info, public=false)
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)
