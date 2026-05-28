proc sum (vals :array[_, int]) :int=
  var result :int= 0
  for val in vals:
    result += val
  return result
