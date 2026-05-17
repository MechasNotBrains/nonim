#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps std
from std/random as R import nil
from std/hashes import hash
# @deps nim.gen
import ./typetools


#_______________________________________
# @section Random Seed Management
#_____________________________
const seed {.strDefine.}= CompileDate & CompileTime
#___________________
func init_with (seed_string :string= seed) :R.Rand;
var state = random.init_with(random.seed)
func init_with (seed_string :string= seed) :R.Rand=
  {.cast(noSideEffect).}:
    return R.initRand(hash(seed_string))
#___________________
func init *(seed_string :string= seed) :void=
  {.cast(noSideEffect).}:
    random.state = random.init_with(seed_string)


#_______________________________________
# @section Containers
#_____________________________
func sample *[T](container :T) :auto=
  {.cast(noSideEffect).}:
    return R.sample(state, container)


#_______________________________________
# @section Integers
#_____________________________
func integer *() :SomeInteger=
  {.cast(noSideEffect).}:
    return R.rand(state, int.high)
#___________________
func integer *[T: SomeInteger](H :T) :T=
  {.cast(noSideEffect).}:
    return R.rand(state, H)
#___________________
func integer *[T: SomeInteger](S :Slice[T]) :T=
  {.cast(noSideEffect).}:
    return R.rand(state, S)
#___________________
func integer_lit *() :string=
  return random.sample(typetools.Integers_all)



#_______________________________________
# @section Booleans
#_____________________________
func bool *() :bool= random.integer(1) == 1


#_______________________________________
# @section Floats
#_____________________________
func float *[T: SomeFloat](H :T) :T=
  {.cast(noSideEffect).}:
    let limit = if H == T.high: 12_345.6789012.T else: H
    return R.rand(state, limit)
#___________________
func float *[T: SomeFloat](S :Slice[T]) :T=
  {.cast(noSideEffect).}:
    return R.rand(state, S)
#___________________
func float_lit *() :string=
  return random.sample(typetools.Floats_all)


#_______________________________________
# @section Characters
#_____________________________
type SomeChar = char | cchar | cschar | cuchar
#___________________
func char *[T: SomeChar]() :T=
  {.cast(noSideEffect).}:
    return system.char(R.rand(state, T.high.int))
#___________________
func char_lit *() :string=
  if random.bool() : "char"
  else             : "cchar"


#_______________________________________
# @section General Typedef
#_____________________________
func typename *() :string=
  case random.integer(4):
  of 1: return random.float_lit()
  of 2: return random.char_lit()
  of 3: return "bool"
  of 4: return "string"
  else: return random.integer_lit()


#_______________________________________
# @section Operators
#_____________________________
func operator *(
    prefix  : bool;
    keyword : bool     = random.integer(3) == 0;
    len     : Positive = random.integer(1..16);
  ) :string=
  if keyword:
    let pool =
      if prefix : Operator_keywords_prefix
      else      : Operator_keywords_infix
    return random.sample(pool)
  result = ""
  for _ in 0..<len: result.add random.sample(Operator_characters)
  if   result == "*:": result = "**"
  elif result == "::": result = ":="
  elif result == "=":  result = "=="
  if prefix:
    if   result == ":":  result = "+:"
    elif result == ".":  result = ".+"
    elif result == "..": result = "..."

