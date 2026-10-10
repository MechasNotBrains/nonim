proc convert (value :pointer) :ptr int=
  return value@ptr int
proc widen (value :char) :int=
  return value@int
proc erase (value :ptr int) :pointer=
  return value@pointer
