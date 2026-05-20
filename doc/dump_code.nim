proc foo(x :int) =
  let y = 0
  case x
  of 1, 2: discard
  of 3:
    let z = 1
    discard z
  else: discard
