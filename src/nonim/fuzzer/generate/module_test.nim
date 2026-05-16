#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
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
import ./identifier
# @deps nim.gen.tests
import ../tests/base


const TmplTestCode = """
# Generated test code - testing module statements
$1
"""


describe "nonim.fuzzer | Variable Generation Tests":
  let testCacheDir = "bin/.tests/module"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("module", &"modules{testID}.nim", testCode, semaRequired= false)
    testID.inc

  it "must generate compilable include statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_include(info)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable import statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_import(info)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable import-except statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_import(info, entries= #[ broken above 6 ]# R.integer(1..6))
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable import-as statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = generate.statement_import(info, entries= #[ broken above 5 ]# R.integer(0..5), As= identifier.name())
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()

  it "must generate compilable from-import statements", proc() =
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let As   = if R.bool(): identifier.name() else: ""
      let node = generate.statement_import(info, entries= R.integer(1..16), From= true, As= As)
      declarations.add(render.code((node: node, info: info)))
    compileTest(declarations).ok()
