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
import ./statement_comment
# @deps nim.gen.tests
import ../tests/base


const TmplTestCode = """
# Generated test code - testing comment statements
$1
"""


describe "nonim.fuzzer | Comment Generation Tests":
  let testCacheDir = "bin/.tests/comment"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("comment", &"comments{testID}.nim", testCode, semaRequired= false)
    testID.inc

  it "must generate compilable comment statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = statement_comment.random(info)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable comments with explicit length", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = statement_comment.random(info, len= id)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()
