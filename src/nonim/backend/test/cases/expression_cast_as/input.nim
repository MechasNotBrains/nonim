proc convert (value :pointer) :ptr int=
  return value as ptr int
proc release (value :var pointer)
