proc thing (T :typedesc) :void=
  var count :int= 0
  for field {.inline.} in @typeInfo(T).struct.fields:
    discard field
  discard count
