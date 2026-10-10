proc pick (x :int) :int=
  var result :int= 0
  if   x == 1 : result = 10
  elif x == 2 : result = 20
  else        : result = 30
  return result
