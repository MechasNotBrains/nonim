#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps std
import minitest
import std/os
import std/strutils
import std/strformat
# @deps tests
import ../tests/base
import ./identifier


const TmplTestCode = """
# Generated test code - testing identifier validity
proc testIdentifiers() =
$1

when isMainModule:
  testIdentifiers()
"""


describe "nonim.fuzzer | Identifier Generation Tests":
  let testCacheDir = "bin/.tests/nimcache/identifier"
  if not dirExists(testCacheDir): createDir(testCacheDir)

  var testID = 0
  proc compileTest (declarations :seq[string]) :bool=
    let testCode = TmplTestCode % [declarations.join("\n")]
    result = base.compileTest("identifier", &"identifiers{testID}.nim", testCode)
    testID.inc

  it "must generate valid basic identifiers", proc() =
    var declarations = newSeq[string]()
    for i in 1..100:
      let identifier = identifier.name(underscore=false)
      declarations.add("  var " & identifier & " = " & $i)
    compileTest(declarations).ok()

  it "must generate identifiers at edge case lengths", proc() =
    var declarations = newSeq[string]()
    for length in [1, 2, 100, 1000]:
      let identifier = identifier.name(length)
      declarations.add("  var " & identifier & " = " & $length)
    compileTest(declarations).ok()

  it "must generate valid identifiers without underscores", proc() =
    var declarations = newSeq[string]()
    # Test without underscore
    for id in 51..100:
      let identifier = identifier.name(8, underscore=false)
      declarations.add("  var " & identifier & " = " & $(id + 50))
    compileTest(declarations).ok()

  it "must generate invalid identifiers with underscores", proc() =
    var declarations = newSeq[string]()
    # Test with underscore allowed
    for id in 1..50:
      let identifier = identifier.name(8, underscore=true)
      declarations.add("  var " & identifier & " = " & $id)
    (not compileTest(declarations)).ok()
    # Add invalid underscore cases
    declarations = newSeq[string]()
    declarations.add("  var " & "_" & " = 1")
    declarations.add("  var " & "__" & " = 2")
    declarations.add("  var " & "___" & " = 3")
    declarations.add("  var " & "_a_" & " = 4")
    declarations.add("  var " & "__b__" & " = 5")
    declarations.add("  var " & "___c___" & " = 6")
    (not compileTest(declarations)).ok()

