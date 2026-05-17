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
# Generated test code - testing assignment statements
$1
"""


describe "nonim.fuzzer | Assignment Generation Tests":
  let testCacheDir = "bin/.tests/assignment"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("assignment", &"assignments{testID}.nim", testCode, semaRequired= false)
    testID.inc

  it "must generate compilable assignment statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_assignment(info)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()
