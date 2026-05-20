proc foo(x :int) :int=
  case x
  of 1, 2: return 10
  of 3: return 30
  else: return 0
