proc foo(x :int, y :int) :int=
  case x
  of 1:
    case y
    of 10: return 100
    else: return 0
  else: return 0
