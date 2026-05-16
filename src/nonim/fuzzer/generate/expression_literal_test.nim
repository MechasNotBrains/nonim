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


suite "Literal Expression Generation Tests":
  let testCacheDir = "bin/.tests/literal"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("literal", &"literals{testID}.nim", testCode)
    testID.inc

  test "Integer literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.integer()
      declarations.add("  var x" & $id & " = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "Float literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.float()
      declarations.add("  var x" & $id & " = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "Char literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.char()
      declarations.add("  var x" & $id & ": char = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "String literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.string()
      declarations.add("  var x" & $id & ": string = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "Bool literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.bool()
      declarations.add("  var x" & $id & ": bool = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "Nil literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.Nil()
      declarations.add("  var x" & $id & ": pointer = " & render.code((node: node, info: info)))
    check compileTest(declarations)

  test "Random literals":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = expression_literal.random()
      declarations.add("  discard " & render.code((node: node, info: info)))
    check compileTest(declarations)
