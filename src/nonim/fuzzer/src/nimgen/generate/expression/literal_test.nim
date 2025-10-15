#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import std/unittest
import std/os
import std/strutils
import std/strformat
# @deps compiler
from   "$nim"/compiler/renderer import renderTree, renderNoComments, renderNoPragmas
# @deps tests
import ../../tests/base
import ../../random
import ./literal


const TmplTestCode = """
# Generated test code - testing literal expression validity
proc testLiterals() =
$1

when isMainModule:
  testLiterals()
"""


suite "Literal Generation Tests":
  let testCacheDir = "bin/.tests/expression/literal"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest(declarations: seq[string]): bool =
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("expression/literal", &"literals{testID}.nim", testCode)
    testID.inc

  test "Integer Expressions":
    var declarations = newSeq[string]()
    for id in 1..100:
      let varNode = literal.integer(random.integer_lit())
      declarations.add("  discard " & varNode.renderTree({renderNoComments, renderNoPragmas}).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)

  test "Float Expressions":
    var declarations = newSeq[string]()
    for id in 1..100:
      let varNode = literal.float(random.float_lit())
      declarations.add("  discard " & varNode.renderTree({renderNoComments, renderNoPragmas}).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)

  test "Random Literal Expressions":
    var declarations = newSeq[string]()
    for id in 1..100:
      let varNode = literal.random()
      declarations.add("  discard " & varNode.renderTree({renderNoComments, renderNoPragmas}).replace("\n", "\n  "))  # Add indentation for proper formatting
    check compileTest(declarations)

