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
# Generated test code - testing call statements
$1
"""


suite "Call Generation Tests":
  let testCacheDir = "bin/.tests/call"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("call", &"calls{testID}.nim", testCode, semaRequired= false)
    testID.inc

  test "Call statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_call(info)
      declarations.add(render.code((node: node, info: info)))
    check compileTest(declarations)
