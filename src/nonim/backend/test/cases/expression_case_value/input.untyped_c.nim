proc foo (x :int) :ptr char=
  return case x
    of 1: "one"
    of 2: "two"
    else: ""
