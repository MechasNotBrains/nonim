const vector = @This()

const (X, Y, Z, W) = (0, 1, 2, 3)

type Vec4 = object
  data    :array[4, f32]
  create  {.alias: vector.vec4.}:proc

proc vec4 (x,y,z,w :f32) :Vec4= return (data: [x,y,z,w])

