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
import ../../random as R
import ../../generate
import ./Return
# @deps nim.gen.tests
import ../../tests/base


suite "Return Generation Tests":
  let testCacheDir = "bin/.tests/return"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(code: string): bool =
    result = base.compileTest("return", &"return{testID}.nim", code)
    testID.inc

  test "Return statements":
    var procs = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let T    = R.typename()
      let info = newLineInfo(config, absPath, id, 0)
      let node = Return.random(info, T)
      let rendered = generate.render((node: node, info: info))
      procs.add(&"proc test{id}(): {T} =\n  {rendered}")
    check compileTest(procs.join("\n"))
