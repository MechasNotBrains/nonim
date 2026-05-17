proc find_first (n :int) :int=
  var current = 0
  while true:
    if current == n:
      break
    current = current + 1
  return current
