proc unwrap (a : ?int) :int=
  let value = a ?! 0
  return value
