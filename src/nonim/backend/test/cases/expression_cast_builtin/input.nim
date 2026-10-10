proc convert (value :pointer) :ptr int=
  return cast[ptr int](value)
proc truncate (value :int) :char=
  return cast[char](value)
