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
import ../identifier
import ./module
# @deps nim.gen.tests
import ../../tests/base


const TmplTestCode = """
# Generated test code - testing module statements
$1
"""


suite "Variable Generation Tests":
  let testCacheDir = "bin/.tests/module"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("module", &"modules{testID}.nim", testCode, semaRequired= false)
    testID.inc

  test "include statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = module.Include(info)
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)

  test "import statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = module.Import(info)
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)

  test "import except statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = module.Import(info, entries= #[ broken above 6 ]# R.integer(1..6))
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)

  test "import as statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let node = module.Import(info, entries= #[ broken above 5 ]# R.integer(0..5), As= identifier.name())
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)

  test "from statements":
    var declarations = newSeq[string]()
    let config  = newConfigRef()
    let absPath = AbsoluteFile("test.nim")
    for id in 1..100:
      let info = newLineInfo(config, absPath, id, 0)
      let As   = if R.bool(): identifier.name() else: ""
      let node = module.Import(info, entries= R.integer(1..16), From= true, As= As)
      declarations.add(generate.render((node: node, info: info)))
    check compileTest(declarations)

