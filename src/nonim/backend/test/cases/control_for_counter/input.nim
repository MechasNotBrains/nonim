proc process (vals :array[_, int]) :void=
  for val, id in (vals, 0..^1):
    discard id
