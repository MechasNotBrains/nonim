type Vec4 = object
  data    :array[4, f32]
  create  {.alias: vector.create.}:proc
