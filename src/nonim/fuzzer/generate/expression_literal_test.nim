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
from ./expression_literal import nil
import ./render
# @deps nim.gen.tests
import ../tests/base


const TmplTestCode = """
# Generated test code - testing literal expressions
proc testLiterals() =
$1

when isMainModule:
  testLiterals()
"""


describe "nonim.fuzzer | Literal Expression Generation Tests":
  let testCacheDir = "bin/.tests/literal"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("literal", &"literals{testID}.nim", testCode)
    testID.inc

  it "must generate compilable integer literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.integer()
      declarations.add("  var x" & $id & " = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable float literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.float()
      declarations.add("  var x" & $id & " = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable char literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.char()
      declarations.add("  var x" & $id & ": char = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable string literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.string()
      declarations.add("  var x" & $id & ": string = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable bool literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.bool()
      declarations.add("  var x" & $id & ": bool = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable nil literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.Nil()
      declarations.add("  var x" & $id & ": pointer = " & render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable random literals", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.random()
      declarations.add("  discard " & render.code((node: node, info: info)))
    compileTest(declarations).ok()
