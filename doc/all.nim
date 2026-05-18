# Every Nim syntax construct supported by nonim.
# A feature MUST appear here before it can be implemented.

# [x] Variable: let (immutable, runtime)
let answer :int= 42

# [x] Variable: var (mutable)
var counter :int= 0

# [x] Variable: exported
let exported_answer *:int= 42

# [x] Procedure: forward declaration
proc add (x, y :int) :int

# [x] Procedure: with body
proc add (x, y :int) :int=
  return x + y

# [x] Procedure: exported
proc visible *(x :int) :int=
  return x

# [x] Expression: function call
proc main () :int=
  return add(1, 2)

# [x] Statement: discard
proc noop (x :int)=
  discard x div 2

# [x] Literal: bool
proc check_bool (x :bool) :bool=
  if x:
    return true
  return false

# [x] Literal: nil
proc nothing ()=
  discard nil

# [x] Literal: float
let pi :float64= 3.14159

# [x] Literal: string
let greeting :cstring= "hello"

# [x] Literal: char
let letter :char= 'a'

# [x] Variable: multiple bindings
let a, b :int= 0

# [x] Expression: assignment
proc increment (x :var int) =
  x = x + 1

# [x] Control flow: if/else
proc abs_val (x :int) :int=
  if x < 0:
    return -x
  else:
    return x

# [x] Control flow: while
proc countdown (n :int) =
  var current :int= n
  while current > 0:
    current = current - 1

# [x] Expression: indexed
proc get_element (arr :array[10, int]; idx :int) :int=
  return arr[idx]

# [x] Type: object
type Vec2 = object
  x :float32
  y :float32

# [ ] Type: enum
type Direction = enum
  north
  south
  east
  west

# [ ] Type: alias
type Integer = int

# [ ] Import
import std/os
