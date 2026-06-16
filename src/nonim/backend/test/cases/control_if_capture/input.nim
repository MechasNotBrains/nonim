proc check (thing : ?Thing) :void=
  if thing as value:
    discard value
  else:
    discard
