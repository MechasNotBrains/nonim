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
import ../random as R
import ../generate
import ./statement_return
# @deps nim.gen.tests
import ../tests/base


describe "nonim.fuzzer | Return Generation Tests":
  let testCacheDir = "bin/.tests/return"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(code: string): bool =
    result = base.compileTest("return", &"return{testID}.nim", code)
    testID.inc

  it "must generate compilable return statements", proc() =
    var procs = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let T    = R.typename()
      let info = newLineInfo(config, absPath, id, 0)
      let node = statement_return.random(info, T)
      let rendered = render.code((node: node, info: info))
      procs.add(&"proc test{id}(): {T} =\n  {rendered}")
    compileTest(procs.join("\n")).ok()
