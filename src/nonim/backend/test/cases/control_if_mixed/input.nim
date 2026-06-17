proc clamp (value :int, limit :int) :int=
  if value > limit:
    discard value
    return limit
  else:
    return value
