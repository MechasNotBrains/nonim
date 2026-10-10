include @stddef.h
proc sum (count :int) :int=
  var result :int= 0
  for id in 0 ..< count:
    result += id
  return result
