proc thing (T :typedesc) :void=
  discard @typeInfo(T).struct.fields
